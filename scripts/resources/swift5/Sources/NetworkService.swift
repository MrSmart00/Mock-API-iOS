{% include "Includes/Header.stencil" %}

import Foundation
import Moya
import Alamofire
import Combine

private func JSONResponseDataFormatter(data: Data) -> String {
    if let dataJson = try? JSONSerialization.jsonObject(with: data),
        let prettyData = try? JSONSerialization.data(withJSONObject: dataJson, options: .prettyPrinted),
        let result = String(data: prettyData, encoding: .utf8) {
        return result
    } else {
        return String(data: data, encoding: .utf8) ?? ""
    }
}

private func loggingPlugin() -> PluginType {
    let formatter = NetworkLoggerPlugin.Configuration.Formatter(requestData: JSONResponseDataFormatter, responseData: JSONResponseDataFormatter)
    let configuation = NetworkLoggerPlugin.Configuration(formatter: formatter,
                                                         logOptions: [.formatRequestAscURL, .successResponseBody, .errorResponseBody])
    return NetworkLoggerPlugin(configuration: configuation)
}

public enum APIError: Swift.Error {
    case jsonMapping
    case objectMapping
    case statusCode(Response)
    case noConnection
    case timedOut
    case response(Response)
    case other(Error)
    case unknown

    init(_ error: MoyaError) {
        switch error {
        case .jsonMapping:
            self = .jsonMapping
        case .objectMapping:
            self = .objectMapping
        case let .statusCode(res):
            self = .statusCode(res)
        case let .underlying(error, response):
            if let afError = error as? AFError, let nsError = afError.underlyingError as NSError? {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    self = .noConnection
                    return
                case NSURLErrorTimedOut:
                    self = .timedOut
                    return
                default:
                    break
                }
            }
            if let _response = response {
                self = .response(_response)
            } else {
                self = .other(error)
            }
        default:
            self = .unknown
        }
    }

    var response: Response? {
        switch self {
        case let .response(res), let .statusCode(res):
            return res
        default:
            return nil
        }
    }
}

public protocol NetworkServiceType {
    func request<R>(_ target: R) -> AnyPublisher<R.Response, APIError> where R: {{ options.name }}BaseTargetType, R.Response: Decodable
}

public protocol StubResponseInjectable {
    func fetchStubData<T>(_ target: T) -> Data
}

public class StubNetworkService: NetworkServiceType {
    private let provider: MoyaProvider<AbstractTarget>
    private let injectResponse: StubResponseInjectable?

    public init(provider: MoyaProvider<AbstractTarget> = MoyaProvider<AbstractTarget>(stubClosure: MoyaProvider.immediatelyStub),
                injectResponse: StubResponseInjectable? = nil) {
        self.provider = provider
        self.injectResponse = injectResponse
    }

    public func request<R>(_ target: R) -> AnyPublisher<R.Response, APIError> where R: {{ options.name }}BaseTargetType, R.Response: Decodable {
        let data = injectResponse?.fetchStubData(target)
        let target = AbstractTarget(target, data ?? .init())
        return provider.requestPublisher(target)
            .map(R.Response.self, failsOnEmptyData: false)
            .mapError(APIError.init)
            .eraseToAnyPublisher()
    }
}

private class OAuthHandler: RequestInterceptor {
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?, _ refreshToken: String?) -> Void

    private var isRefreshing = false
    private var requestsToRetry: [((RetryResult) -> Void)] = []

    private let lock = NSLock()
    private var accessTokenRepository: TokenRepositoryType?
    private var refreshTokenHandler: RefreshTokenHandler?

    init(accessTokenRepository: TokenRepositoryType?,
         refreshTokenHandler: RefreshTokenHandler? = nil) {
        self.accessTokenRepository = accessTokenRepository
        self.refreshTokenHandler = refreshTokenHandler
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        if let accessToken = accessTokenRepository?.token {
            var urlRequest = urlRequest
            urlRequest.setValue("Bearer " + accessToken.rawValue, forHTTPHeaderField: "Authorization")
            return completion(.success(urlRequest))
        }
        return completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        defer {
            lock.unlock()
        }

        lock.lock()
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            requestsToRetry.append(completion)

            if !isRefreshing {
                refreshTokens { [weak self] json in
                    guard let strongSelf = self else {
                        return
                    }

                    strongSelf.lock.lock()
                    defer {
                        strongSelf.lock.unlock()
                    }
                    if let strongJson = json {
                        strongSelf.refreshTokenHandler?.completion(strongJson)
                    }
                    strongSelf.requestsToRetry.forEach { $0(.doNotRetry) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }

    private func refreshTokens(completion: @escaping ([String: Any]?) -> Void) {
        guard !isRefreshing, let target = refreshTokenHandler?.endpointTarget else {
            return
        }

        isRefreshing = true

        var endpoint = MoyaProvider.defaultEndpointMapping(for: target)
        if let refreshToken = refreshTokenHandler?.tokenRepository.token {
            endpoint = endpoint.adding(newHTTPHeaderFields: ["Authorization": "Bearer \(refreshToken.rawValue)"])
        }

        let request = try! endpoint.urlRequest() // swiftlint:disable:this force_try
        Session.default.request(request)
            .responseJSON { [weak self] (response) in
                guard let strongSelf = self else {
                    return
                }
                if case .success(let value) = response.result,
                    let json = value as? [String: Any] {
                    completion(json)
                } else {
                    completion(nil)
                }
                strongSelf.isRefreshing = false
            }
    }
}

public class NetworkService: NetworkServiceType {
    private let provider: MoyaProvider<AbstractTarget>

    public init(accessTokenRepository: TokenRepositoryType?,
                refreshTokenHandler: RefreshTokenHandler? = nil) {
        let handler = OAuthHandler(accessTokenRepository: accessTokenRepository,
                                   refreshTokenHandler: refreshTokenHandler)
        let provider = MoyaProvider<AbstractTarget>(
            session: .init(interceptor: handler),
            plugins: [
                loggingPlugin()
            ])
        self.provider = provider
    }

    public func request<R>(_ target: R) -> AnyPublisher<R.Response, APIError> where R : MockAPIBaseTargetType, R.Response : Decodable {
        let target = AbstractTarget(target)
        return provider.requestPublisher(target)
            .map(R.Response.self, failsOnEmptyData: false)
            .mapError(APIError.init)
            .eraseToAnyPublisher()
    }
}

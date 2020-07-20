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

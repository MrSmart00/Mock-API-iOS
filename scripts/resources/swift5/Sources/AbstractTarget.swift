{% include "Includes/Header.stencil" %}

import Foundation
import Moya

private func JSONResponseDataFormatter(data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data //fallback to original data if it cant be serialized
    }
}

public enum AbstractTarget: TargetType {
    case target(TargetType, Data)

    public init(_ target: TargetType, _ data: Data = .init()) {
        self = .target(target, data)
    }

    public var path: String {
        target.path
    }

    public var baseURL: URL {
        target.baseURL
    }

    public var method: Moya.Method {
        target.method
    }

    public var sampleData: Data {
        switch self {
        case let .target(_, data): return data
        }
    }

    public var task: Task {
        target.task
    }

    public var validationType: ValidationType {
        target.validationType
    }

    public var headers: [String: String]? {
        target.headers
    }

    public var target: TargetType {
        switch self {
        case let .target(target, _): return target
        }
    }
}

extension AbstractTarget: AccessTokenAuthorizable {
    public var authorizationType: AuthorizationType? {
        if let _target = target as? AccessTokenAuthorizable {
            return _target.authorizationType
        } else {
            return .none
        }
    }
}
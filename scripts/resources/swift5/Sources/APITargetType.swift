{% include "Includes/Header.stencil" %}

import Foundation
import Moya

public protocol {{ options.name }}BaseTargetType: TargetType {
    associatedtype Response
}

public extension {{ options.name }}BaseTargetType {
    var baseURL: URL {
        return URL(string: "{{ options.baseURL }}")!
    }
    var headers: [String : String]? {
        return nil
    }
    var sampleData: Data {
        return Data()
    }
    var validationType: ValidationType {
        return .successCodes
    }
}

public protocol {{ options.name }}TargetType: {{ options.name }}BaseTargetType {
}

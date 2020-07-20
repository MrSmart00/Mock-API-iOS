{% include "Includes/Header.stencil" %}

import Foundation

public struct Token: RawRepresentable {
    public typealias RawValue = String

    public var rawValue: String

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
}

public protocol TokenRepositoryType {
    var token: Token? { get set }
}

public protocol RefreshTokenHandler {
    var tokenRepository: TokenRepositoryType { get }
    var endpointTarget: AbstractTarget { get }
    var completion: ([String: Any]) -> Void { get }
}


//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

import Foundation

public struct Credential: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case email
        case password
    }

    public let email: String

    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

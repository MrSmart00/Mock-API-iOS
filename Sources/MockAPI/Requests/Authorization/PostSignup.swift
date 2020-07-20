
//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

import Foundation
import Moya

public extension Endpoint.Authorization {
    /** サインアップ */

    struct PostSignup: MockAPITargetType {
        public typealias Response = AccessToken

        public var method: Moya.Method {
            Moya.Method(rawValue: "POST")
        }

        public var path: String {
            let path = "/signup"
            return path
        }

        public var task: Task {
            .requestJSONEncodable(body)
        }

        public var body: Credential

        public init(body: Credential) {
            self.body = body
        }
    }
}
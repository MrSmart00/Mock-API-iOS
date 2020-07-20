
//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

import Foundation
import Moya

public extension Endpoint.Me {
    /** ユーザー情報を取得 */

    struct GetMe: MockAPITargetType {
        public typealias Response = User

        public var method: Moya.Method {
            Moya.Method(rawValue: "GET")
        }

        public var path: String {
            let path = "/me"
            return path
        }

        public var task: Task {
            .requestPlain
        }

        public init() {}
    }
}

extension MockAPI.Endpoint.Me.GetMe: AccessTokenAuthorizable {
    public var authorizationType: AuthorizationType? {
        .bearer
    }
}
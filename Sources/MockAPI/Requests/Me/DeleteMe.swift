
//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

import Foundation
import Moya

public extension Endpoint.Me {
    /** ユーザー情報を削除 */

    struct DeleteMe: MockAPITargetType {
        public typealias Response = NoContent

        public var method: Moya.Method {
            Moya.Method(rawValue: "DELETE")
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

extension MockAPI.Endpoint.Me.DeleteMe: AccessTokenAuthorizable {
    public var authorizationType: AuthorizationType? {
        .bearer
    }
}

{% include "Includes/Header.stencil" %}

import Foundation

public struct NoContent: Codable {
    public init() {
    }
}

public extension NoContent {
    public init(from decoder: Decoder) throws {
        self.init()
    }
}

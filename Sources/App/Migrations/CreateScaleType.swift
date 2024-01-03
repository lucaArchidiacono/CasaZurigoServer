//
//  CreateScaleType.swift
//
//
//  Created by Luca Archidiacono on 12.01.2024.
//

import Foundation
import Vapor
import Fluent

struct CreateScaleType: AsyncMigration {
    func prepare(on database: Database) async throws {
        _ = try await database.enum(ScaleType.name)
            .case(ScaleType.high.rawValue)
            .case(ScaleType.medium.rawValue)
            .case(ScaleType.low.rawValue)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.enum(ScaleType.name).delete()
    }
}

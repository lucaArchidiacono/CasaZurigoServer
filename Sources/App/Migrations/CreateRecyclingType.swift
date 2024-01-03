//
//  CreateRecyclingType.swift
//
//
//  Created by Luca Archidiacono on 12.01.2024.
//

import Foundation
import Vapor
import Fluent

struct CreateRecyclingType: AsyncMigration {
    func prepare(on database: Database) async throws {
        _ = try await database.enum(RecyclingType.name)
            .case(RecyclingType.cardboard.rawValue)
            .case(RecyclingType.cargotram.rawValue)
            .case(RecyclingType.etram.rawValue)
            .case(RecyclingType.organic.rawValue)
            .case(RecyclingType.paper.rawValue)
            .case(RecyclingType.waste.rawValue)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.enum(RecyclingType.name).delete()
    }
}

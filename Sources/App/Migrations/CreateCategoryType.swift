//
//  CreateCategoryType.swift
//
//
//  Created by Luca Archidiacono on 12.01.2024.
//

import Foundation
import Vapor
import Fluent

struct CreateCategoryType: AsyncMigration {
    func prepare(on database: Database) async throws {
        _ = try await database.enum(CategoryType.name)
            .case(CategoryType.recycling.rawValue)
            .case(CategoryType.event.rawValue)
            .case(CategoryType.restaurant.rawValue)
            .case(CategoryType.bar.rawValue)
            .case(CategoryType.coffee.rawValue)
            .case(CategoryType.club.rawValue)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.enum(CategoryType.name).delete()
    }
}

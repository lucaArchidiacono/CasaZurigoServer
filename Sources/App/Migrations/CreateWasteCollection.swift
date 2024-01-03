//
//  CreateWasteCollection.swift
//
//
//  Created by Luca Archidiacono on 12.01.2024.
//

import Foundation
import Vapor
import Fluent

struct CreateWasteCollection: AsyncMigration {
    func prepare(on database: Database) async throws {
        let recyclingType = try await database.enum(RecyclingType.name).read()

        try await database.schema(WasteCollection.schema)
            .id()
            .field("date", .datetime, .required)
            .field("zip", .int, .required)
            .field("station", .string)
            .field("region", .string)
            .field(.string(RecyclingType.name), recyclingType, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(WasteCollection.schema).delete()
    }
}

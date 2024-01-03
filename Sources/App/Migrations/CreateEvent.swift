//
//  CreateEvent.swift
//
//
//  Created by Luca Archidiacono on 12.01.2024.
//

import Foundation
import Vapor
import Fluent

struct CreateEvent: AsyncMigration {
    func prepare(on database: Database) async throws {
        let scaleType = try await database.enum(ScaleType.name).read()
        try await database.schema(Event.schema)
            .id()
            .field("title", .string, .required)
            .field("date", .datetime, .required)
            .field("description", .string, .required)
            .field("location", .string, .required)
            .field("link", .string, .required)
            .field("thumbnail", .data)
            .field(.string(ScaleType.name), scaleType, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Event.schema).delete()
    }
}

//
//  Scale.swift
//
//
//  Created by Luca Archidiacono on 12.11.2023.
//

import Foundation
import Vapor
import Fluent

enum Scale: String, Codable {
	case high
	case medium
	case low
}

struct CreateScale: AsyncMigration {
	/// Prepares the database for storing Galaxy models.
	func prepare(on database: Database) async throws {
		_ = try await database.enum("scale_type")
			.case("high")
			.case("medium")
			.case("low")
			.create()
	}

	/// Optionally reverts the changes made in the prepare method.
	func revert(on database: Database) async throws {
		try await database.enum("scale_type").delete()
	}
}

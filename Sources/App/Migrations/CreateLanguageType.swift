//
//  CreateLanguageType.swift
//
//
//  Created by Luca Archidiacono on 13.01.2024.
//

import Foundation
import Vapor
import Fluent

struct CreateLanguageType: AsyncMigration {
	func prepare(on database: Database) async throws {
		_ = try await database.enum(LanguageType.name)
			.case(LanguageType.de.rawValue)
			.case(LanguageType.en.rawValue)
			.case(LanguageType.fr.rawValue)
			.case(LanguageType.it.rawValue)
			.create()
	}

	func revert(on database: Database) async throws {
		try await database.enum(LanguageType.name).delete()
	}
}

//
//  Event.swift
//
//
//  Created by Luca Archidiacono on 11.11.2023.
//

import Foundation
import Fluent
import Vapor

final class Event: Model, Content {
	// Name of the table or collection.
	static let schema = "events"

	// Unique identifier for this Galaxy.
	@ID(key: .id)
	var id: UUID?

	///	 The Event's title.
	@Field(key: "title")
	var title: String

	///	 The Event's date.
	@Field(key: "date")
	var date: Date

	/// The Event's description.
	@Field(key: "description")
	var description: String

	/// The Event's location.
	@Field(key: "location")
	var location: String

	/// The Event's link.
	@Field(key: "link")
	var link: URL
	
	/// Scale of the Event.
	@Field(key: "scale")
	var scale: Scale

	/// Creates a new, empty Event.
	init() { }

	/// Creates a new Event with all properties set.
	init(id: UUID? = nil, title: String, date: Date, description: String, location: String, link: URL) {
		self.id = id
		self.title = title
		self.date = date
		self.description = description
		self.location = location
		self.link = link
	}
}

struct CreateEvent: AsyncMigration {
	/// Prepares the database for storing Galaxy models.
	func prepare(on database: Database) async throws {
		let scaleType = try await database.enum("scale_type").read()
		try await database.schema("events")
			.id()
			.field("title", .string)
			.field("date", .date)
			.field("description", .string)
			.field("location", .string)
			.field("link", .string)
			.field("scale", scaleType, .required)
			.create()
	}

	/// Optionally reverts the changes made in the prepare method.
	func revert(on database: Database) async throws {
		try await database.schema("galaxies").delete()
	}
}

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

	// Unique identifier for this Event.
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
	var location: String?

	/// The Event's link.
	@Field(key: "link")
	var link: String
    
	/// Scale of the Event.
	@Enum(key: "scale_type")
	var scale: Scale

	/// Creates a new, empty Event.
	init() { }

	/// Creates a new Event with all properties set.
    init(id: UUID? = nil,
         title: String,
         date: Date,
         description: String,
         location: String?,
         link: String,
         scale: Scale) {
		self.id = id
		self.title = title
		self.date = date
		self.description = description
		self.location = location
		self.link = link
        self.scale = scale
	}
}

struct CreateEvent: AsyncMigration {
	/// Prepares the database for storing Galaxy models.
	func prepare(on database: Database) async throws {
        let scaleType = try await database.enum("scale_type")
            .case("high")
            .case("medium")
            .case("low")
            .create()
        
		try await database.schema("events")
			.id()
			.field("title", .string)
			.field("date", .datetime)
			.field("description", .string)
			.field("location", .string)
            .field("link", .string)
            .field("scale_type", scaleType, .required)
			.create()
	}

	/// Optionally reverts the changes made in the prepare method.
	func revert(on database: Database) async throws {
		try await database.schema("events").delete()
	}
}

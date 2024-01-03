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
	var location: String

	/// The Event's link.
	@Field(key: "link")
	var link: String
    
	/// Scale of the Event.
	@Enum(key: .string(ScaleType.name))
	var scaleType: ScaleType

	/// The Event's Thumbnail
	@Field(key: "thumbnail")
	var thumbnail: Data?

	/// Creates a new, empty Event.
	init() { }

	/// Creates a new Event with all properties set.
    init(id: UUID? = nil,
         title: String,
         date: Date,
         description: String,
         location: String,
         link: String,
         scaleType: ScaleType,
		 thumbnail: Data?) {
		self.id = id
		self.title = title
		self.date = date
		self.description = description
		self.location = location
		self.link = link
        self.scaleType = scaleType
		self.thumbnail = thumbnail
	}
}


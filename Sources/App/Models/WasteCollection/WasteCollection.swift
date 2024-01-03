//
//  File.swift
//  
//
//  Created by Luca Archidiacono on 03.01.2024.
//

import Foundation
import Fluent
import Vapor

final class WasteCollection: Model, Content {
	// Name of the table or collection.
	static let schema = "waste_collections"

	// Unique identifier for this Event.
	@ID(key: .id)
	var id: UUID?

	@Field(key: "date")
	var date: Date
	
	@Enum(key: .string(RecyclingType.name))
	var type: RecyclingType
	
	@Field(key: "zip")
	var zip: Int

	@Field(key: "station")
	var station: String?

	@Field(key: "region")
	var region: String

	init() { }

	/// Creates a new Event with all properties set.
	init(id: UUID? = nil,
		 date: Date,
		 type: RecyclingType,
		 zip: Int,
		 station: String?,
		 region: String) {
		self.id = id
		self.date = date
		self.type = type
		self.zip = zip
		self.station = station
		self.region = region
	}
}


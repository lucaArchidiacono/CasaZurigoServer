//
//  OpenERZTransformer.swift
//
//
//  Created by Luca Archidiacono on 14.01.2024.
//

import Foundation

extension DataTransformer {
	enum OpenERZ {}
}

extension DataTransformer.OpenERZ {
	static func transform(_ data: OpenERZResponse) -> [WasteCollection] {
		return data.result.compactMap { result in
			guard let date = try? Date(result.date, strategy: .iso8601_light),
				  let type = RecyclingType(rawValue: result.wasteType)
			else { return nil }
			let station = result.station.isEmpty ? nil : result.station
			let id = UUID("\(date)\("-\(type.rawValue)")\("-\(result.zip)")\(station != nil ? "-\(station!)" : "")-\(result.region)")

			return WasteCollection(id: id, date: date, type: type, zip: result.zip, station: station, region: result.region)
		}
	}
}

extension ParseStrategy where Self == Date.FormatStyle {
	static var iso8601_light: Date.ParseStrategy {
		return Date.ParseStrategy(format: "\(year: .defaultDigits)-\(month: .defaultDigits)-\(day: .defaultDigits)",
								  locale: .current,
								  timeZone: .current)
	}
}

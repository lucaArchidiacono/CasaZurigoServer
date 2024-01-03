//
//  OpenERZResponse.swift
//
//
//  Created by Luca Archidiacono on 14.01.2024.
//

import Foundation

struct OpenERZResponse: Decodable {
	let metadata: MetadataResponse
	let result: [ResultResponse]

	enum CodingKeys: String, CodingKey {
		case metadata = "_metadata"
		case result
	}

	// MARK: - Metadata
	struct MetadataResponse: Decodable {
		let totalCount, rowCount: Int

		enum CodingKeys: String, CodingKey {
			case totalCount = "total_count"
			case rowCount = "row_count"
		}
	}

	// MARK: - Result
	struct ResultResponse: Decodable {
		let date: String
		let wasteType: String
		let zip: Int
		let area: String
		let station: String
		let region: String

		enum CodingKeys: String, CodingKey {
			case wasteType = "waste_type"
			case date, zip, area, station, region
		}
	}
}

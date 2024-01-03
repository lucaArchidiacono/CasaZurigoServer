//
//  WasteCollectionJob.swift
//
//
//  Created by Luca Archidiacono on 14.01.2024.
//

import Foundation
import Vapor
import Queues

struct WasteCollectionJob: AsyncScheduledJob {
	private enum Config {
		private static let region = "zurich"
		private static let sortBy = "date"
		private static let startDate: String = {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "YYYY-MM-dd"
			return dateFormatter.string(from: .now)
		}()

		static func buildURL(offset: Int, threshold: Int) -> String {
			"https://openerz.metaodi.ch/api/calendar.json?region=\(Config.region)&start=\(Config.startDate)&sort=\(Config.sortBy)&offset=\(offset)&limit=\(offset + threshold)"
		}
	}

	func run(context: QueueContext) async throws {
		var offset = 0
		var isEOF = false
		let threshold = 1000

		while !isEOF {
			let endpoint = Config.buildURL(offset: offset, threshold: threshold)
			let response = try await context.application.client.get(URI(string: endpoint))
			let openERZResponse = try response.content.decode(OpenERZResponse.self)

			guard !openERZResponse.result.isEmpty else {
				isEOF = true
				return
			}

			let wasteCollection = DataTransformer.OpenERZ.transform(openERZResponse)
			for waste in wasteCollection {
				_ = try await waste.save(on: context.application.db)
			}

			offset += threshold
		}
	}
}


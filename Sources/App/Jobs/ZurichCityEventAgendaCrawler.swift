//
//  ZurichCityEventAgendaCrawler.swift
//
//
//  Created by Luca Archidiacono on 12.11.2023.
//

import Foundation
import Vapor
import Queues
import FeedKit

struct ZurichCityEventAgendaCrawler: AsyncScheduledJob {
	func run(context: QueueContext) async throws {
		let feedURL = URL(string: "https://www.stadt-zuerich.ch/content/portal/de/index/aktuelles/agenda/_jcr_content/mainparsys/veranstalltungen.rss")!
		let parser = FeedParser(URL: feedURL)

		let result = parser.parse()
		switch result {
		case .success(let feed):
			guard let items = feed.rssFeed?.items else {
				throw Abort(.notFound)
			}
			items.forEach { item in
				guard let event = DataTransformer.Event.transform(item) else {
					context.logger.log(level: .error, "Could not build Event.")
					return
				}
				_ = event.save(on: context.application.db)
			}
		case .failure(let error):
			context.logger.log(level: .error, "\(error)")
		}
	}
}

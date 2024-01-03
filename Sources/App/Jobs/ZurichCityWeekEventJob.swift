//
//  ZurichCityWeekEventJob.swift
//
//
//  Created by Luca Archidiacono on 12.11.2023.
//

import Foundation
import Vapor
import Queues
import FeedKit
import SwiftSoup

struct ZurichCityWeekEventJob: AsyncScheduledJob {
	private let host: String
	private let feedParser: FeedParser

	init() {
		self.host = "https://www.stadt-zuerich.ch"

		let feedURL = URL(string: "\(host)/content/portal/de/index/aktuelles/agenda/_jcr_content/mainparsys/veranstalltungen.rss")!
		self.feedParser = FeedParser(URL: feedURL)
	}

	func run(context: QueueContext) async throws {
        let result: Result<Feed, ParserError> = await withCheckedContinuation { continuation in
			feedParser.parseAsync { result in
                continuation.resume(returning: result)
            }
        }
        
        switch result {
        case .success(let feed):
            guard let items = feed.rssFeed?.items else {
                throw Abort(.notFound)
            }
            for item in items {
				guard let title = item.title,
					  let date = item.pubDate,
					  let description = item.description,
					  let link = item.link else {
					let message = """
					Could not build Event. RSS Feed Item has some missing values:
					Title: \(item.title ?? "n.a")
					Date: \(item.pubDate?.rfc1123 ?? "n.a")
					Description: \(item.description ?? "n.a")
					Link: \(item.link ?? "n.a")
					"""
                    context.logger.log(level: .warning, "\(message)")
					return
				}

                let response = try await context.application.client.get(URI(string: link))
                guard let body = response.body else { 
					context.logger.log(level: .warning, "Was not able to get Body from:\n\(response)")
					return
				}

				let document = try SwiftSoup.parse(String(buffer: body))
                let streetAddress = try document.getElementsByAttributeValue("itemprop", "streetAddress").text()
				let zip = try document.getElementsByAttributeValue("itemprop", "postalCode").text()
				let addressLocality = try document.getElementsByAttributeValue("itemprop", "addressLocality").text()
				let location = "\(streetAddress), \(zip) \(addressLocality)"

				var thumbnail: Data?
				if let thumbnailURL = try? document.getElementsByClass("image").attr("href"),
				   let response = try? await context.application.client.get(URI("\(host)\(thumbnailURL)")),
				   let buffer = response.body {
					thumbnail = Data(buffer: buffer, byteTransferStrategy: .copy)
				}

				let event = Event(
					id: UUID(link),
					title: title,
					date: date,
					description: description,
					location: location,
					link: link,
					scaleType: .low,
					thumbnail: thumbnail)
				_ = try await event.save(on: context.application.db)
            }
        case .failure(let error):
            context.logger.log(level: .error, "\(error)")
        }
	}
}

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
import SwiftSoup

struct ZurichCityEventAgendaCrawler: AsyncScheduledJob {
	func run(context: QueueContext) async throws {
		let feedURL = URL(string: "https://www.stadt-zuerich.ch/content/portal/de/index/aktuelles/agenda/_jcr_content/mainparsys/veranstalltungen.rss")!
		let parser = FeedParser(URL: feedURL)

        let result: Result<Feed, ParserError> = await withCheckedContinuation { continuation in
            parser.parseAsync { result in
                continuation.resume(returning: result)
            }
        }
        
        switch result {
        case .success(let feed):
            guard let items = feed.rssFeed?.items else {
                throw Abort(.notFound)
            }
            for item in items {
                guard let event = DataTransformer.Event.transform(item, scale: .low) else {
                    context.logger.log(level: .error, "Could not build Event.")
                    return
                }
                
                let response = try await context.application.client.get(URI(string: event.link))
                guard let body = response.body else { return }
                let bodyString = String(buffer: body)
                
                let document = try SwiftSoup.parse(bodyString)
                if let address = try? document.getElementsByAttributeValue("itemprop", "streetAddress").text(),
                   let zip = try? document.getElementsByAttributeValue("itemprop", "postalCode").text(),
                   let locality = try? document.getElementsByAttributeValue("itemprop", "addressLocality").text() {
                    event.location = "\(address), \(zip) \(locality)"
                }
                _ = try await event.save(on: context.application.db)
            }
        case .failure(let error):
            context.logger.log(level: .error, "\(error)")
        }
	}
}

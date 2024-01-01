import Vapor

import Queues
import FeedKit

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

	app.get("events") { req async throws -> [Event] in
        let feedURL = URL(string: "https://www.stadt-zuerich.ch/content/portal/de/index/aktuelles/agenda/_jcr_content/mainparsys/veranstalltungen.rss")!
        let parser = FeedParser(URL: feedURL)

        let result = parser.parse()
        switch result {
        case .success(let feed):
            guard let items = feed.rssFeed?.items else {
                throw Abort(.notFound)
            }
            for item in items {
                guard let event = DataTransformer.Event.transform(item, scale: .low) else {
                    print("Could not build Event.")
                    return []
                }
                
                _ = try await event.save(on: req.db)
            }
        case .failure(let error):
            req.logger.log(level: .error, "\(error)")
            throw error
        }
        
        let events = try await Event.query(on: req.db).all()
        return events
	}
}

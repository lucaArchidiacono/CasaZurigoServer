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
        try await Event.query(on: req.db).all()
	}
}

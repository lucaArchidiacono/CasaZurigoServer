import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

	app.get("events") { req async throws in
		try await Event.query(on: req.db).all()
	}
}

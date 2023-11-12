import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

	// PostgreSQL Setup
	guard let hostname = Environment.get("DATABASE_HOST"),
		  let username = Environment.get("DATABASE_USERNAME"),
		  let password = Environment.get("DATABASE_PASSWORD"),
		  let database = Environment.get("DATABASE_NAME")
	else {
		app.logger.log(level: .critical, """
Was not able to read environment variables:
DATABASE_HOST: \(Environment.get("DATABASE_HOST") ?? "n.a")
DATABASE_USERNAME: \(Environment.get("DATABASE_USERNAME") ?? "n.a")
DATABASE_PASSWORD: \(Environment.get("DATABASE_PASSWORD") ?? "n.a")
DATABASE_NAME: \(Environment.get("DATABASE_NAME") ?? "n.a")
""")
		throw Abort(.internalServerError)
	}
	var tls = TLSConfiguration.makeClientConfiguration()
	tls.certificateVerification = .none
	let sslContext = try NIOSSLContext(configuration: tls)
	let configuration = SQLPostgresConfiguration(
		hostname: hostname,
		username: username,
		password: password,
		database: database,
		tls: .prefer(sslContext)
	)
	app.databases.use(.postgres(configuration: configuration), as: .psql)

	// Add DB Models in here:
	app.migrations.add(CreateEvent())

	// Add Jobs
	// Highlights - Big Events which are organised on a yearly basis.
	app.queues.schedule(ZurichEventHighlightCrawlerJob())
		.monthly()
		.on(.first)
		.at(.noon)
	app.queues.schedule(ZurichCityEventAgendaCrawler())
		.daily()
		.at(.midnight)

    // register routes
    try routes(app)
}



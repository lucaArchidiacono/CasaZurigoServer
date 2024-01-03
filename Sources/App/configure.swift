import Vapor
import Fluent
import FluentPostgresDriver
import QueuesRedisDriver

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
	app.migrations.add(CreateLanguageType())
	app.migrations.add(CreateCategoryType())
	app.migrations.add(CreateScaleType())
	app.migrations.add(CreateRecyclingType())
	app.migrations.add(CreateEvent())
	app.migrations.add(CreateWasteCollection())

    try await app.autoMigrate()
    
    // Setup Queues
    guard let hostname = Environment.get("REDIS_HOST") else {
                app.logger.log(level: .critical, """
Was not able to read environment variables:
REDIS_HOST: \(Environment.get("REDIS_HOST") ?? "n.a")
""")
        throw Abort(.internalServerError)
    }

	try app.queues.use(.redis(.init(url: "redis://\(hostname):6379", 
									pool: .init(connectionRetryTimeout: .seconds(60)))))

	// Add Jobs
	// Highlights - Big Events which are organised on a yearly basis.
	//	let cityYearEventJob = ZurichCityYearEventJob()
	//	app.queues.schedule(cityYearEventJob)
	//		.monthly()
	//        .on(.first)
	//        .at(.midnight)
	let cityWeekEventJob = ZurichCityWeekEventJob()
	app.queues.schedule(cityWeekEventJob)
		.daily()
		.at(.midnight)
	let wasteCollectionJob = WasteCollectionJob()
	app.queues.schedule(wasteCollectionJob)
		.yearly()
		.in(.january)
		.on(.first)
		.at(.midnight)

    try app.queues.startInProcessJobs(on: .default)
    try app.queues.startScheduledJobs()

    // register routes
    try routes(app)

	let context = app.queues.queue.context
	do {
//		try await cityYearEventJob.run(context: context)
		try await cityWeekEventJob.run(context: context)
		try await wasteCollectionJob.run(context: context)
	} catch {
		app.logger.log(level: .error, "\(error)")
	}
}



// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CasaZurigoServer",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.83.1"),
		.package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2"),
		.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
		.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
		.package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
				.product(name: "FeedKit", package: "FeedKit"),
				.product(name: "SwiftSoup", package: "SwiftSoup"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
				.product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),

            // Workaround for https://github.com/apple/swift-package-manager/issues/6940
            .product(name: "Vapor", package: "vapor"),
        ])
    ]
)

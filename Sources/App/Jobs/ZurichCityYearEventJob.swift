//
//  ZurichCityYearEventJob.swift
//
//
//  Created by Luca Archidiacono on 12.11.2023.
//

import Foundation
import Vapor
import Queues
import SwiftSoup

struct ZurichCityYearEventJob: AsyncScheduledJob {
	private enum Config {
		enum Lang: String, CaseIterable {
			case en
			case de
			case it
			case fr

			var endpoint: URI {
				switch self {
				case .de:
					return URI(string: "\(Config.host)/\(self.rawValue)/besuchen/event-highlightss")
				case .en:
					return URI(string: "\(Config.host)/\(self.rawValue)/visit/event-highlights")
				case .fr:
					return URI(string: "\(Config.host)/\(self.rawValue)/visite/evenements-marquants")
				case .it:
					return URI(string: "\(Config.host)/\(self.rawValue)/visitare/eventi-top")
				}
			}

			func buildDate(_ data: String) -> Date? {
				var formatters = [DateFormatter]()
				switch self {
				case .en:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "en_US")
					dateFormatter1.dateFormat = "MMMM dd – dd, yyyy"
					formatters.append(dateFormatter1)
					let dateFormatter2 = DateFormatter()
					dateFormatter2.locale = Locale(identifier: "en_US")
					dateFormatter2.dateFormat = "MMMM dd, yyyy"
					formatters.append(dateFormatter2)
				case .de:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "de_DE")
					dateFormatter1.dateFormat = "dd. – dd. MMMM yyyy"
					formatters.append(dateFormatter1)
					let dateFormatter2 = DateFormatter()
					dateFormatter2.locale = Locale(identifier: "de_DE")
					dateFormatter2.dateFormat = "dd. MMMM yyyy"
					formatters.append(dateFormatter2)
				case .fr:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "fr_FR")
					dateFormatter1.dateFormat = "'Du' dd 'au' dd MMMM yyyy"
					formatters.append(dateFormatter1)
					let dateFormatter2 = DateFormatter()
					dateFormatter2.locale = Locale(identifier: "fr_FR")
					dateFormatter2.dateFormat = "dd MMMM yyyy"
					formatters.append(dateFormatter2)
				case .it:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "it_IT")
					dateFormatter1.dateFormat = "dd – dd MMMM yyyy"
					let dateFormatter2 = DateFormatter()
					dateFormatter2.locale = Locale(identifier: "fr_FR")
					dateFormatter2.dateFormat = "dd MMMM yyyy"
					formatters.append(dateFormatter2)
				}

				for formatter in formatters {
					if let date = formatter.date(from: data) {
						return date
					}
				}

				return nil
			}
		}

		static let host = "https://www.zuerich.com"
		static let sectionIDs: Set<String> = [
			"january",
			"february",
			"march",
			"april",
			"may",
			"june",
			"july",
			"august",
			"september",
			"october",
			"november",
			"december",
		]
	}


	func run(context: QueueContext) async throws {
		for lang in Config.Lang.allCases {
			let response = try await context.application.client.get(lang.endpoint)

			guard let body = response.body else {
				context.logger.log(level: .warning, "Was not able to get Body from:\n\(response)")
				return
			}

			let document = try SwiftSoup.parse(String(buffer: body))
			guard let sections = try getSections(from: document, using: context), !sections.isEmpty() else {
				context.logger.log(level: .error, "No `sections` where found in:\n\(document)")
				return
			}

			let links: [URI] = try sections
				.filter { Config.sectionIDs.contains($0.id()) }
				.compactMap { element -> [URI] in
					return try element.select(".section .teaser")
						.filter { $0.hasAttr("href") }
						.compactMap { element in
							guard let path = try? element.attr("href"), !path.contains("http") else {
								return nil
							}
							return URI(string: "\(Config.host)\(path)")
						}
				}
				.reduce([], +)

			for link in links {
				let response = try await context.application.client.get(link)

				guard let body = response.body else {
					context.logger.log(level: .warning, "Was not able to get Body from:\n\(response)")
					continue
				}

				let document = try SwiftSoup.parse(String(buffer: body))

				guard let main = try document.getElementsByTag("main").first() else {
					context.logger.log(level: .warning, "Was not able to get `main` from:\n\(document)")
					continue
				}

				let title = try main.select("header .title").text()
				let subtitle = try main.select("header .subtitle").text()

				guard let content = try main.select(".content").first() else {
					context.logger.log(level: .warning, "Was not able to get `.content` from:\n\(main)")
					continue
				}

				let children = content.children()
				guard let dateString = try children.first()?.text(), let date = lang.buildDate(dateString) else {
					context.logger.log(level: .warning, "Was not able to get `date` from:\n\(main)")
					continue
				}

				let description = children.dropFirst()
					.prefix { child in
						child.tagName() == "p"
					}
					.reduce("") { partialResult, child in
						let text = (try? child.text()) ?? ""
						return partialResult.appending("\(text)")
					}

				var thumbnail: Data?
				if let thumbnailURL = try? main.getElementsByClass("image-container").first()?.getElementsByTag("img").attr("src"),
				   let response = try? await context.application.client.get(URI("\(Config.host)\(thumbnailURL)")),
				   let buffer = response.body {
					thumbnail = Data(buffer: buffer, byteTransferStrategy: .copy)
				}

				let event = Event(
					id: UUID(link.string),
					title: title,
					date: date, 
					description: description,
					location: "",
					link: link.string,
					scaleType: .high,
					thumbnail: thumbnail)
				_ = try await event.save(on: context.application.db)
			}
		}
	}

	private func getSections(from document: Document, using context: QueueContext) throws -> Elements? {
		guard let body = document.body() else {
			context.logger.log(level: .error, "Was not able to get `body` from:\n\(document)")
			return nil
		}

		guard let main = try body.getElementsByTag("main").first() else {
			context.logger.log(level: .error, "Was not able to get `main` from:\n\(document)")
			return nil
		}

		return try main.getElementsByTag("section")
	}
}

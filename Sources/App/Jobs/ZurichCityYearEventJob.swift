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
// Instead of using the very hybrid: "https://www.zuerich.com"
// https://www.guidle.com/en/veranstaltungen#distance=&group=month&mustToHaveTagNodes=317161753&pLayout=view-extended&where=-102036997542687

struct ZurichCityYearEventJob: AsyncScheduledJob {
	private enum Config {
		enum Lang: String, CaseIterable {
			case en
			case de
			case it
			case fr

			var endpoint: URI {
				let endpoint = "/#group=month&mustToHaveTagNodes=317161753&pLayout=view-extended&where=-102036997542687"
				switch self {
				case .de:
					return URI(string: "\(Config.host)/\(self.rawValue)/veranstaltungen\(endpoint)")
				case .en:
					return URI(string: "\(Config.host)/\(self.rawValue)/events\(endpoint)")
				case .fr:
					return URI(string: "\(Config.host)/\(self.rawValue)/evenements\(endpoint)")
				case .it:
					return URI(string: "\(Config.host)/\(self.rawValue)/eventi\(endpoint)")
				}
			}

			func buildDate(_ data: String) -> Date? {
				var formatters = [DateFormatter]()
				switch self {
				case .en:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "en_US")
					dateFormatter1.dateFormat = "dd/MMMM/yyyy   HH:mm"
					formatters.append(dateFormatter1)
				case .de:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "de_DE")
					dateFormatter1.dateFormat = "dd.MMMM.yyyy   HH:mm"
					formatters.append(dateFormatter1)
				case .fr:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "fr_FR")
					dateFormatter1.dateFormat = "dd/MMMM/yyyy   HH:mm"
					formatters.append(dateFormatter1)
				case .it:
					let dateFormatter1 = DateFormatter()
					dateFormatter1.locale = Locale(identifier: "it_IT")
					dateFormatter1.dateFormat = "dd.MMMM.yyyy   HH:mm "
					formatters.append(dateFormatter1)
				}

				for formatter in formatters {
					if let date = formatter.date(from: data) {
						return date
					}
				}

				return nil
			}
		}

		static let host = "https://www.guidle.com"
	}


	func run(context: QueueContext) async throws {
		for lang in Config.Lang.allCases {
			guard let document = try await getDocument(from: lang.endpoint, context: context) else {
				context.logger.log(level: .error, "Was not able to get document using:\n\(lang.endpoint)")
				return
			}

			guard let body = document.body() else {
				context.logger.log(level: .error, "Was not able to get `body` from:\n\(document)")
				return
			}

			guard let main = try body.select(".container main").first() else {
				context.logger.log(level: .error, "Was not able to get `body` from:\n\(body)")
				return
			}

			let links = try main.select("section .item-wide a")
				.compactMap { element in
					let href = try element.attr("href")
					return URI(string: "\(Config.host)\(href)")
				}

			for link in links {
				guard let document = try await getDocument(from: link, context: context) else {
					context.logger.log(level: .error, "Was not able to get document using:\n\(link)")
					return
				}

				guard let body = document.body() else {
					context.logger.log(level: .error, "Was not able to get `body` from:\n\(document)")
					return
				}

				guard let main = try body.select(".container main").first() else {
					context.logger.log(level: .error, "Was not able to get `body` from:\n\(body)")
					return
				}

				let spans = try main.select("span")

				let titleSpan = spans
					.first { element in
						let attributes = element.getAttributes()
						return attributes?.contains(where: { $0.getValue() == "summary" }) ?? false
					}

				guard let titleSpan else {
					context.logger.log(level: .error, "Was not able to get `summary` from `header span`:\n\(main)")
					return
				}

				let title = try titleSpan.text()

				let descriptionSpan = spans
					.first { element in
						let attributes = element.getAttributes()
						return attributes?.contains(where: { $0.getValue() == "description" }) ?? false
					}

				guard let descriptionSpan else {
					context.logger.log(level: .error, "Was not able to get `description` from `span`:\n\(main)")
					return
				}

				let description = try descriptionSpan.text()

				guard let infoElement = try main.select(".info-additional").first() else {
					context.logger.log(level: .error, "Was not able to get `.info-additional` from:\n\(main)")
					return
				}

				let infoAccordions = try infoElement.select(".accordion")

				guard let date = lang.buildDate(try infoAccordions[0].text()) else {
					return
				}

				let location = try infoAccordions[1].text()
				let contact = try infoAccordions[2].text()
				
				guard let linkElement = try infoAccordions[3].select("a").first() else {
					return
				}

				let link = try linkElement.attr("href")
				
				let event = Event(
					id: UUID(link),
					title: title,
					date: date,
					description: description,
					location: location,
					link: link,
					scaleType: .low,
					thumbnail: nil)
				_ = try await event.save(on: context.application.db)
			}
		}
	}

	private func getDocument(from uri: URI, context: QueueContext) async throws -> SwiftSoup.Document? {
		let response = try await context.application.client.get(uri)

		guard let responseBody = response.body else {
			context.logger.log(level: .warning, "Was not able to get Body from:\n\(response)")
			return nil
		}

		let document = try SwiftSoup.parse(String(buffer: responseBody))
		return document
	}
}

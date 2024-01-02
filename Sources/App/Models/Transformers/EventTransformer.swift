//
//  EventTransformer.swift
//  
//
//  Created by Luca Archidiacono on 12.11.2023.
//

import Foundation
import FeedKit
import Logging

extension DataTransformer {
	enum Event {}
}

extension DataTransformer.Event {
    static func transform(_ item: RSSFeedItem, scale: Scale) -> Event? {
		guard let title = item.title,
			  let date = item.pubDate,
			  let description = item.description,
              let link = URL(string: item.link ?? "")?.absoluteString else {
			return nil
		}
        return Event(title: title, date: date, description: description, location: nil, link: link, scale: scale)
	}
}

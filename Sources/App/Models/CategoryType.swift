//
//  CategoryType.swift
//
//
//  Created by Luca Archidiacono on 02.01.2024.
//

import Foundation
import Vapor
import Fluent

enum CategoryType: String, Codable {
	static let name = "category_type"

    case recycling
    case event
    case restaurant
    case bar
    case coffee
	case club
}


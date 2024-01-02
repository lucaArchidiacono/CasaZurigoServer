//
//  Category.swift
//
//
//  Created by Luca Archidiacono on 02.01.2024.
//

import Foundation
import Vapor
import Fluent

enum Category: String, Codable {
    case recycling
    case event
    case restaurant
    case bar
    case coffee
}

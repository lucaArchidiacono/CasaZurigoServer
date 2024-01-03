//
//  RecyclingType.swift
//
//
//  Created by Luca Archidiacono on 02.01.2024.
//

import Foundation
import Fluent
import Vapor

enum RecyclingType: String, Codable {
	static let name = "recycling_type"

    case cardboard
    case cargotram
    case etram
    case organic
    case paper
    case waste
}


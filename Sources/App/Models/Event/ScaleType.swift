//
//  ScaleType.swift
//
//
//  Created by Luca Archidiacono on 12.11.2023.
//

import Foundation
import Vapor
import Fluent

enum ScaleType: String, Codable {
	static let name = "scale_type"

	case high
	case medium
	case low
}


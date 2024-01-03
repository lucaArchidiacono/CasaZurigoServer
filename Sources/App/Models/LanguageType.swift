//
//  LanguageType.swift
//
//
//  Created by Luca Archidiacono on 13.01.2024.
//

import Foundation
import Vapor
import Fluent

enum LanguageType: String, Codable {
	static let name = "language_type"

	case en
	case fr
	case it
	case de
}

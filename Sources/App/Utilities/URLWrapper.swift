//
//  URLWrapper.swift
//
//
//  Created by Luca Archidiacono on 02.01.2024.
//

import Foundation
import Vapor
import Fluent

@propertyWrapper
class URLWrapper: Property {
    typealias Model = Event
    typealias Value = URL
    var value: URL?

    init(wrappedValue: URL?) {
        self.value = wrappedValue
    }

    var wrappedValue: URL? {
        get { value }
        set { value = newValue }
    }

    // Implement the property wrapper methods for encoding and decoding
    static func encode(_ value: URL?, to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value?.absoluteString)
    }

    static func decode(from decoder: Decoder) throws -> URL? {
        let container = try decoder.singleValueContainer()
        let urlString = try container.decode(String?.self)
        return URL(string: urlString ?? "")
    }
}

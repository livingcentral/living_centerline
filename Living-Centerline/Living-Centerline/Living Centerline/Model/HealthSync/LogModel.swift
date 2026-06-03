//
//  LogModel.swift
//  Living-Centerline
//
//  Created by APPLE on 2/21/25.
//

import Foundation

struct LogModel: Codable {
    let currentDate: Date
    let UTCDate: Date
    let data: String
    
    init(data: String) {
        self.currentDate = Date()
        self.UTCDate = convertLocalToUTC(localDate: Date()) ?? Date()
        self.data = data
    }
    func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [
                "currentDate": ISO8601DateFormatter().string(from: currentDate),
                "UTCDate": ISO8601DateFormatter().string(from: UTCDate),
                "data": data
            ]
            
            return dict
        }
}
struct logResposnseModel: Codable {
    let success: Bool
    let message: String
}

//struct AnyCodable: Codable {
//    let value: Any
//    
//    init(_ value: Any) {
//        self.value = value
//    }
//    
//    // Encoding to JSON or other formats
//    func encode(to encoder: Encoder) throws {
//        var container = try encoder.singleValueContainer()
//        if let value = value as? String {
//            try container.encode(value)
//        } else if let value = value as? Int {
//            try container.encode(value)
//        } else if let value = value as? Bool {
//            try container.encode(value)
//        } else if let value = value as? [String: Any] {
//            let encodedValue = try JSONSerialization.data(withJSONObject: value, options: [])
//            let jsonValue = try JSONDecoder().decode(AnyCodable.self, from: encodedValue)
//            try container.encode(jsonValue)
//        }
//        // Add more types as necessary
//    }
//    
//    // Decoding the value
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        if let value = try? container.decode(String.self) {
//            self.value = value
//        } else if let value = try? container.decode(Int.self) {
//            self.value = value
//        } else if let value = try? container.decode(Bool.self) {
//            self.value = value
//        } else {
//            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown type")
//        }
//    }
//}

//
//  MissingDatesModel.swift
//  Living-Centerline
//
//  Created by Apple on 08/03/25.
//

import Foundation

// MARK: - Welcome
struct MissingDatesModel: Codable {
    let success: Bool
    let message: String
    let data: MissingDates
}

// MARK: - DataClass
struct MissingDates: Codable {
    let missingDates: [String]
}

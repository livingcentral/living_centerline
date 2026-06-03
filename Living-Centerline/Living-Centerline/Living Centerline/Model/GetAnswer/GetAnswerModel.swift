//
//  GetAnswerModel.swift
//  Living-Centerline
//
//  Created by MACMonterio on 30/09/2024.
//


import Foundation

// Model to represent a single question's response
struct QuestionResponse: Codable {
    let id: String
    let value: Int? // value can be nil if no option is selected
}

// Model to represent the entire payload
struct SubmitRequest: Codable {
    let questions: [QuestionResponse]
}



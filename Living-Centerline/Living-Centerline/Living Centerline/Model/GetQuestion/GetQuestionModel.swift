import Foundation

// Generic API response wrapper
struct APIresponse<T: Decodable>: Decodable {
    let success: Int
    let message: String?
    let data: T?
}

// Main model for the question response (data is now an array of GetQuestionData)
struct GetQuestionModel: Decodable {
    let success: Bool
    let message: String
    let data: [GetQuestionData] // <-- data is an array now
}

// Data structure for each question (only text and sequence needed)
struct GetQuestionData: Codable {
    let _id: String?
    let text: String
    let sequence: Int
    let scaleDetails: ScaleDetails
    var selectedValue: String?
}

// ScaleDetails model (only options included)
struct ScaleDetails: Codable {
    let options: [Option] // Only options, other fields removed
}

// The options (only text and value needed)
struct Option: Codable {
    let text: String
    let value: Int
}




import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Int
    let message: String?
    let data: T?
}

/*struct GetProfileModel: Decodable {
 let first_name: String
 let last_name: String
 let image: String?
 } */

struct GetProfileModel: Codable {
    let success: Bool
    let message: String
    let data: UserProfileData
}

struct UserProfileData: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let submissionDate: String?
    let token: String?
    enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case email, token
            case submissionDate = "submission_date"
        }
}

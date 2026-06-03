//
//  SetNewPasswordModel.swift
//  Living-Centerline
//
//  Created by MACMonterio on 23/09/2024.
//

import Foundation

struct SetNewPasswordModel: Encodable {
    
    let email: String
    let otp: String
    let password: String
    
    // Use CodingKeys to map model properties to JSON keys (if API expects different key names)
    enum CodingKeys: CodingKey {
        case email
        case otp
        case password  // Adjust this if the API expects "Password" with a capital P
    }
}

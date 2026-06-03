//
//  Register.swift
//  Living-Centerline
//
//  Created by MACMonterio on 19/09/2024.
//

import Foundation

struct RegisterModel: Encodable {
    let first_name: String
    let last_name: String
    let email: String
    let password: String
    
    // Use CodingKeys to map model properties to JSON keys
    enum CodingKeys: String, CodingKey {
        case first_name = "firstname"
        case last_name = "lastname"
        case email
        case password
    }
}




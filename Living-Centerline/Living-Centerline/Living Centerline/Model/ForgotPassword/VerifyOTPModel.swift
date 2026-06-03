//
//  VerifyOTPModel.swift
//  Living-Centerline
//
//  Created by MACMonterio on 23/09/2024.
//

import Foundation

struct VarifyOTPModel : Encodable {
    
    let email: String
    let otp: String
    
    // Use CodingKeys to map model properties to JSON keys
    enum CodingKeys: String, CodingKey {
        
        case email
        case otp
    }
}


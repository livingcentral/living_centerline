//
//  EditProfileModel.swift
//  Living-Centerline
//
//  Created by MACMonterio on 24/09/2024.
//

import Foundation

struct EditProfileModel: Encodable {
    
    let first_name: String
    let last_name: String
  
    // Use CodingKeys to map model properties to JSON keys (if API expects different key names)
    enum CodingKeys: CodingKey {
        case first_name
        case last_name
       
    }
}

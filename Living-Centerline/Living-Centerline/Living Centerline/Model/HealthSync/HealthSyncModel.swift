//
//  HealthSyncModel.swift
//  Living-Centerline
//
//  Created by APPLE on 17/12/24.
//

import Foundation

struct Welcome: Codable {
    let success: Bool
    let message: String
    let data: LastSyncModel
}
struct LastSyncModel: Codable {
    let lastSyncDate: String

    enum CodingKeys: String, CodingKey {
        case lastSyncDate = "last_sync_date"
    }
}

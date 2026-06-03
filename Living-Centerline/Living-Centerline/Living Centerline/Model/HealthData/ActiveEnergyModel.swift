//
//  ActiveEnergyModel.swift
//  Living-Centerline
//
//  Created by Rajal Sardhara on 25/11/24.
//

import Foundation

struct ActiveEnergyModel: Codable {
    let date: String
    let activeEnergy: ActiveEnergyValue // in kilocalories (kcal)
    let dateWithTimeStamp: Date
    let samples: [ActiveEnergySampleModel]
}
struct ActiveEnergyValue: Codable {
    let activeEnergy: Double
    let dateWithTimeStamp: Date
}

struct ActiveEnergySampleModel: Codable {
    let date: String
    let activeEnergy: Double
    let dateWithTimeStamp: Date
}

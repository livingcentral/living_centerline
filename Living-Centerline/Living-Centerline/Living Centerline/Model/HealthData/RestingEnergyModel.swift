//
//  RestingEnergyModel.swift
//  Living-Centerline
//
//  Created by APPLE on 26/12/24.
//

import Foundation
struct RestingEnergyModel: Codable {
    let date: String
    let restingEnergy: RestingEnergyValue // in kilocalories (kcal)
    let dateWithTimeStamp: Date
    let samples: [RestingEnergySampleModel]
}
struct RestingEnergyValue: Codable {
    let restingEnergy: Double
    let dateWithTimeStamp: Date
}

struct RestingEnergySampleModel: Codable {
    let date: String
    let restingEnergy: Double
    let dateWithTimeStamp: Date
}

//
//  RestingHeartModel.swift
//  Living-Centerline
//
//  Created by Rajal Sardhara on 25/11/24.
//

import Foundation

struct RestingHeartDataModel: Codable {
    let date: String
    let heartRate: RestingHeartValue
    let dateWithTimeStamp: Date
    let samples: [RestingHeartSampleModel]
}

struct RestingHeartValue: Codable {
    let heartValue: Double
    let dateWithTimeStamp: Date
}

struct RestingHeartSampleModel: Codable {
    let date: String
    let heartValue: Double
    let dateWithTimeStamp: Date
}

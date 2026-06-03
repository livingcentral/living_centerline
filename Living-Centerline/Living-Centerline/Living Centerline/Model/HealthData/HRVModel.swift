//
//  HRVModel.swift
//  Living-Centerline
//
//  Created by Rajal Sardhara on 25/11/24.
//

import Foundation

struct HRVDataModel: Codable {
    let date: String // The date the HRV data was recorded
    let hrvValue: HRVValue // The HRV value in milliseconds
    let samples: [HRVSampleModel]
}

struct HRVValue: Codable {
    let hrvValue: Double
    let dateWithTimeStamp: Date
}

struct HRVSampleModel: Codable {
    let date: String
    let hrvValue: Double
    let dateWithTimeStamp: Date
}

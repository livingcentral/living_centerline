//
//  StepsModel.swift
//  Living-Centerline
//
//  Created by Rajal Sardhara on 25/11/24.
//

import Foundation

struct StepDataModel: Codable {
    let date: String
    var totalSteps: TotalSteps
    let samples: [StepSampleModel]
}
struct TotalSteps: Codable {
    let dateWithTimeStamp: Date
    let totalSteps: Int
}
struct StepSampleModel: Codable {
    let date: String
    let stepCount: Int
    let dateWithTimeStamp: Date
}

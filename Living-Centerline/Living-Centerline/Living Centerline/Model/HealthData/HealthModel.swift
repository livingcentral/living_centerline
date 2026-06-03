//
//  HealthModel.swift
//  Living-Centerline
//
//  Created by Developer on 02/10/24.
//

import Foundation

struct HealthDateModel: Codable {
    var date: Date
    var totalSteps: TotalSteps? = nil
   // var hourmodel: [HourModel]? = nil
    // sleep
   // var totalSleepHours: Double? = nil
   // var sleepDuration: String? = nil
    var totalSleep: TotalSleep? = nil // Total sleep duration
    var remSleep: RemSleep? = nil   // REM sleep duration
    var coreSleep: CoreSleep? = nil  // Core sleep duration
    var deepSleep: DeepSleep? = nil  // Deep sleep duration
    var awakeTime: AwakeTime? = nil
    var activeCalorieBurned: ActiveEnergyValue? = nil
    var restingEnergy: RestingEnergyValue? = nil
    var restingHeartRate: RestingHeartValue? = nil
    var hrv: HRVValue? = nil
}

struct HeartDataModel: Codable {
    let date: Date
    let hourmodel: [HourModel]
}

struct HourModel: Codable {
    let hourValue: String
    let heartRateValue: Double
}

struct HealthDataRequest: Codable {
    let data: [HealthDateModel]
}

struct LogDataRequest: Codable {
    let data: LogModel
}

struct HealthDataResponse: Codable {
    let success: Bool
    let message: String
}

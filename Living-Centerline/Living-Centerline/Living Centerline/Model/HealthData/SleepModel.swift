//
//  SleepModel.swift
//  Living-Centerline
//
//  Created by Rajal Sardhara on 25/11/24.
//

import Foundation

struct SleepPhaseModel: Codable {
    let date: String
    var totalSleep: TotalSleep? = nil // Total sleep duration
    var remSleep: RemSleep? = nil   // REM sleep duration
    var coreSleep: CoreSleep? = nil  // Core sleep duration
    var deepSleep: DeepSleep? = nil  // Deep sleep duration
    var awakeTime: AwakeTime? = nil
    // Additional computed properties for hours or duration can be added if necessary
        var totalSleepHours: Double {
            return totalSleep!.totalSleep / 3600.0 // Convert seconds to hours
        }

        var sleepDuration: String {
            let hours = Int(totalSleepHours)
            let minutes = Int((totalSleepHours - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        }
    let samples : [SleepSampleModel]
}

struct SleepSampleModel: Codable {
    let date: String
    var totalSleep: TotalSleep? = nil
    var remSleep: RemSleep? = nil  // REM sleep duration
    var coreSleep: CoreSleep?  = nil  // Core sleep duration
    var deepSleep: DeepSleep?  = nil  // Deep sleep duration
    var awakeTime: AwakeTime? = nil
    var dateWithTimeStamp: Date
}

struct TotalSleep: Codable {
    let dateWithTimeStamp: Date
    let totalSleep: Double
}

struct RemSleep: Codable {
    let dateWithTimeStamp: Date
    let remSleep: Double
}

struct CoreSleep: Codable {
    let dateWithTimeStamp: Date
    let coreSleep: Double
}

struct DeepSleep: Codable {
    let dateWithTimeStamp: Date
    let deepSleep: Double
}

struct AwakeTime: Codable {
    let dateWithTimeStamp: Date
    let awakeTime: Double
}

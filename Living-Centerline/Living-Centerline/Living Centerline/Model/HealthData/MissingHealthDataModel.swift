//
//  MissingHealthDataModel.swift
//  Living-Centerline
//
//  Created by APPLE on 27/01/25.
//

import Foundation
struct MissingHealthDataModel: Codable {
    let success: Bool
    let message: String
    let data: [Datum]
}

// MARK: - Datum
struct Datum: Codable {
    let id: String
    let userID: String
    let data: DataClass
    let date: String
    let dataKeyCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID = "user_id"
        case data, date, dataKeyCount
    }
}

struct DataClass: Codable {
    var date: Date
    var totalSteps: MySteps? = nil
    var totalSleep: MyTotalSleep? = nil
    var remSleep: MyRemSleep? = nil
    var coreSleep: MyCoreSleep? = nil
    var deepSleep: MyDeepSleep? = nil
    var awakeTime: MyAwakeTime? = nil
    var activeCalorieBurned: MyActiveEnergyValue? = nil
    var restingEnergy: MyRestingEnergyValue? = nil
    var restingHeartRate: MyRestingHeartValue? = nil
    var hrv: MyHRVValue? = nil

 //    Custom decoding to handle optional fields
    enum CodingKeys: String, CodingKey {
        case date
        case totalSteps
        case totalSleep
        case remSleep
        case coreSleep
        case deepSleep
        case awakeTime
        case activeCalorieBurned
        case restingEnergy
        case restingHeartRate
        case hrv
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
                // Decode the date manually from a string
        let dateString = try container.decode(String.self, forKey: .date)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                guard let parsedDate = formatter.date(from: dateString) else {
                    throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date format: \(dateString)")
                }
                self.date = parsedDate


        if let totalStepsData = try? container.decode(MySteps.self, forKey: .totalSteps) {
                    self.totalSteps = totalStepsData
                }
        
       //  Decode optional health data fields
        totalSteps = try? container.decode(MySteps.self, forKey: .totalSteps)
        totalSleep = try? container.decode(MyTotalSleep.self, forKey: .totalSleep)
        remSleep = try? container.decode(MyRemSleep.self, forKey: .remSleep)
        coreSleep = try? container.decode(MyCoreSleep.self, forKey: .coreSleep)
        deepSleep = try? container.decode(MyDeepSleep.self, forKey: .deepSleep)
        awakeTime = try? container.decode(MyAwakeTime.self, forKey: .awakeTime)
        activeCalorieBurned = try? container.decode(MyActiveEnergyValue.self, forKey: .activeCalorieBurned)
        restingEnergy = try? container.decode(MyRestingEnergyValue.self, forKey: .restingEnergy)
        restingHeartRate = try? container.decode(MyRestingHeartValue.self, forKey: .restingHeartRate)
        hrv = try? container.decode(MyHRVValue.self, forKey: .hrv)
    }
}
struct MySteps: Codable {
    var dateWithTimeStamp: String
    var totalSteps: Int
}
struct MyTotalSleep: Codable {
    var dateWithTimeStamp: String
    var totalSleep: Double
}

struct MyRemSleep: Codable {
    var dateWithTimeStamp: String
    var remSleep: Double
}

struct MyCoreSleep: Codable {
    var dateWithTimeStamp: String
    var coreSleep: Double
}

struct MyDeepSleep: Codable {
    var dateWithTimeStamp: String
    var deepSleep: Double
}

struct MyAwakeTime: Codable {
    var dateWithTimeStamp: String
    var awakeTime: Double
}
struct MyHRVValue: Codable {
    var hrvValue: Double
    var dateWithTimeStamp: String
}
struct MyRestingHeartValue: Codable {
    var heartValue: Double
    var dateWithTimeStamp: String
}
struct MyActiveEnergyValue: Codable {
    var activeEnergy: Double
    var dateWithTimeStamp: String
}
struct MyRestingEnergyValue: Codable {
    var restingEnergy: Double
    var dateWithTimeStamp: String
}

//
//  helperFunction.swift
//  Living-Centerline
//
//  Created by APPLE on 27/01/25.
//

import Foundation

func getTotalSteps(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Int, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let totalSteps = healthDataModel.totalSteps {
                let dateString = formatter.string(from: healthDataModel.date)
                return (totalSteps.totalSteps, dateString)
            }
        }
    }
    
    return nil
}

func getTotalSleep(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let totalSleep = healthDataModel.totalSleep {
                let dateString = formatter.string(from: healthDataModel.date)
                return (totalSleep.totalSleep, dateString)
            }
        }
    }
    
    return nil
}

func getRemSleep(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let remSleep = healthDataModel.remSleep {
                let dateString = formatter.string(from: healthDataModel.date)
                return (remSleep.remSleep, dateString)
            }
        }
    }
    
    return nil
}

func getCoreSleep(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let coreSleep = healthDataModel.coreSleep {
                let dateString = formatter.string(from: healthDataModel.date)
                return (coreSleep.coreSleep, dateString)
            }
        }
    }
    
    return nil
}

func getDeepSleep(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let deepSleep = healthDataModel.deepSleep {
                let dateString = formatter.string(from: healthDataModel.date)
                return (deepSleep.deepSleep, dateString)
            }
        }
    }
    
    return nil
}

func getAwakeTime(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let awakeTime = healthDataModel.awakeTime {
                let dateString = formatter.string(from: healthDataModel.date)
                return (awakeTime.awakeTime, dateString)
            }
        }
    }
    
    return nil
}

func getActiveCalorie(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let activeCalorie = healthDataModel.activeCalorieBurned {
                let dateString = formatter.string(from: healthDataModel.date)
                return (activeCalorie.activeEnergy, dateString)
            }
        }
    }
    
    return nil
}
func getRestingHeartRate(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let restingHeartRate = healthDataModel.restingHeartRate {
                let dateString = formatter.string(from: healthDataModel.date)
                return (restingHeartRate.heartValue, dateString)
            }
        }
    }
    
    return nil
}
func getRestingEnergy(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let restingEnergy = healthDataModel.restingEnergy {
                let dateString = formatter.string(from: healthDataModel.date)
                return (restingEnergy.restingEnergy, dateString)
            }
        }
    }
    
    return nil
}

func getHRV(forDate searchDate: Date, from healthData: [HealthDateModel]) -> (Double, String)? {
    let calendar = Calendar.current
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    for healthDataModel in healthData {
        if calendar.isDate(healthDataModel.date, inSameDayAs: searchDate) {
            if let hrv = healthDataModel.hrv {
                let dateString = formatter.string(from: healthDataModel.date)
                return (hrv.hrvValue, dateString)
            }
        }
    }
    
    return nil
}

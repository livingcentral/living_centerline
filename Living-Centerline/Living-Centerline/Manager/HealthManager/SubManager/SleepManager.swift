//
//  SleepManager.swift
//  Living-Centerline
//
//  Created by Developer on 11/10/24.
//

import HealthKit

class SleepManager {
    // MARK: Outlets
    let healthStore = HKHealthStore()
    //var sleepDataArray = [SleepPhaseModel]()
    
    // MARK: - Retrieve sleep data
    func retrieveSleepDataForWeek(numberOfDays: Int) async -> [SleepPhaseModel] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Determine the date range (start and end)
      //  let endDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
            print("Error converting date to local end date.")
            return []
        }
        let startDate = calendar.date(byAdding: .day, value: numberOfDays, to: endDate)!
        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
            print("Error converting date to local start date.")
            return []
        }

       // print("Query range: \(localStartDate) - \(localEndDate)")

        var sleepDataArray: [SleepPhaseModel] = []

        for offset in 0..<abs(numberOfDays) {
            if let targetDate = calendar.date(byAdding: .day, value: offset, to: localStartDate) {
                guard let localTargetDate = convertUTCToLocal(utcDate: targetDate) else {
                    print("Error converting target date to UTC.")
                    continue
                }

                // Fetch sleep phases for the target date using async/await
                let sleepPhaseModel = await retrieveSleepPhases(for: localTargetDate) 
                    sleepDataArray.append(sleepPhaseModel)
            }
        }

        // Sort sleep data by date
        sleepDataArray.sort { $0.date < $1.date }

        // Remove the first element if necessary
//        if !sleepDataArray.isEmpty {
//            sleepDataArray.removeFirst()
//        }
        return sleepDataArray
    }

    // working code
//    func retrieveSleepDataForWeek(numberOfDays: Int , completion: @escaping ([SleepPhaseModel]) -> Void) {
//        let healthStore = HKHealthStore()
//        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
//        let calendar = Calendar.current
//        let currentDate = Date()
//        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { return }
//        let endDate = calendar.startOfDay(for: nextDay) // Start of tomorrow (to include today's data)
//       // let startDate = calendar.date(byAdding: .day, value: numberOfDays, to: endDate)! // 14 days before today
//        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: numberOfDays, to: endDate)!)
//
//        print("Query range: \(startDate) - \(endDate)")
//
//        // Define the predicate to filter sleep samples
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//
//        // Create the sample query
//        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
//            if let error = error {
//                print("Error fetching sleep data: \(error.localizedDescription)")
//                completion([])
//                return
//            }
//
//            guard let sleepSamples = samples as? [HKCategorySample] else {
//                print("No valid sleep samples found.")
//                completion([])
//                return
//            }
//           // print("Samples fetched: \(sleepSamples.count)")
//            // Dictionary to store sleep data grouped by end date
//            var sleepDataDict: [String: (
//                totalSleep: Double,
//                remSleep: Double,
//                coreSleep: Double,
//                deepSleep: Double,
//                awakeTime: Double,
//                samples: [SleepSampleModel]
//            )] = [:]
//
//            // DateFormatter for grouping
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "MM-dd-yyyy"
//            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//
//            // Process the sleep samples
//            for sample in sleepSamples {
//                let sleepDuration = sample.endDate.timeIntervalSince(sample.startDate)
//                if sleepDuration <= 0 || sleepDuration > 86400 {
//                    continue // Skip invalid durations
//                }
//                // Group by the end date of the sample
//                let dateString = dateFormatter.string(from: sample.endDate)
//
//                // Retrieve or initialize daily data for this date
//                var dailyData = sleepDataDict[dateString] ?? (
//                    totalSleep: 0.0,
//                    remSleep: 0.0,
//                    coreSleep: 0.0,
//                    deepSleep: 0.0,
//                    awakeTime: 0.0,
//                    samples: []
//                )
//
//                // Add total sleep duration
//                dailyData.totalSleep += sleepDuration
//              //  print("sleep sample date \(sample.endDate)")
//                // Classify sleep phases (iOS 16+)
//                if #available(iOS 16.0, *) {
//                    switch sample.value {
//                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
//                        dailyData.remSleep += sleepDuration
//                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
//                        dailyData.coreSleep += sleepDuration
//                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
//                        dailyData.deepSleep += sleepDuration
//                    case HKCategoryValueSleepAnalysis.awake.rawValue:
//                        dailyData.awakeTime += sleepDuration
//                    default:
//                        continue
//                    }
//                } else {
//                    // For iOS < 16, only account for total sleep
//                    if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
//                        dailyData.totalSleep += sleepDuration
//                    }
//                }
//
//                // Append sample data as SleepSampleModel
//                dailyData.samples.append(SleepSampleModel(
//                    date: dateString,
//                    totalSleep: TotalSleep(dateWithTimeStamp: sample.endDate, totalSleep: sleepDuration),
//                    remSleep: dailyData.remSleep > 0 ? RemSleep(dateWithTimeStamp: sample.endDate, remSleep: dailyData.remSleep) : nil,
//                    coreSleep: dailyData.coreSleep > 0 ? CoreSleep(dateWithTimeStamp: sample.endDate, coreSleep: dailyData.coreSleep) : nil,
//                    deepSleep: dailyData.deepSleep > 0 ? DeepSleep(dateWithTimeStamp: sample.endDate, deepSleep: dailyData.deepSleep) : nil,
//                    awakeTime: dailyData.awakeTime > 0 ? AwakeTime(dateWithTimeStamp: sample.endDate, awakeTime: dailyData.awakeTime) : nil,
//                    dateWithTimeStamp: sample.endDate
//                ))
//
//                // Update the dictionary with the daily data
//                sleepDataDict[dateString] = dailyData
//            }
//
//            // Generate SleepPhaseModel array from the dictionary
//            var sleepDataArray: [SleepPhaseModel] = []
//            let endRange = abs(numberOfDays)
//            for offset in (1...endRange).reversed() { // Loop for the last 14 days
//                let targetDate = calendar.date(byAdding: .day, value: -offset, to: endDate)!
//                let dateString = dateFormatter.string(from: targetDate)
//
//                let sleepData = sleepDataDict[dateString] ?? (
//                    totalSleep: 0.0,
//                    remSleep: 0.0,
//                    coreSleep: 0.0,
//                    deepSleep: 0.0,
//                    awakeTime: 0.0,
//                    samples: []
//                )
//
//                sleepDataArray.append(SleepPhaseModel(
//                    date: dateString,
//                    totalSleep: sleepData.totalSleep > 0 ? TotalSleep(dateWithTimeStamp: targetDate, totalSleep: sleepData.totalSleep) : nil,
//                    remSleep: sleepData.remSleep > 0 ? RemSleep(dateWithTimeStamp: targetDate, remSleep: sleepData.remSleep) : nil,
//                    coreSleep: sleepData.coreSleep > 0 ? CoreSleep(dateWithTimeStamp: targetDate, coreSleep: sleepData.coreSleep) : nil,
//                    deepSleep: sleepData.deepSleep > 0 ? DeepSleep(dateWithTimeStamp: targetDate, deepSleep: sleepData.deepSleep) : nil,
//                    awakeTime: sleepData.awakeTime > 0 ? AwakeTime(dateWithTimeStamp: targetDate, awakeTime: sleepData.awakeTime) : nil,
//                    samples: sleepData.samples
//                ))
//            }
//            // Sort by date ascending
//            sleepDataArray.sort { $0.date < $1.date }
//            sleepDataArray.remove(at: 0)
//            // Return the result
//            completion(sleepDataArray)
//        }
//        // Execute the query
//        healthStore.execute(query)
//    }

    func retrieveSleepPhases(for date: Date) async -> SleepPhaseModel {
        let healthStore = HKHealthStore()
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
//        let startOfDay = calendar.startOfDay(for: date)
//        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let startOfDay = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date.addingTimeInterval(-86400))!
        let endOfDay = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
        guard let localStartDate = convertUTCToLocal(utcDate: startOfDay) else {
            let emptySleepPhaseModel = SleepPhaseModel(
                date: DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none),
                samples: []
            )
            print("Can't convert UTC to local start date")
            return emptySleepPhaseModel
        }
        guard let localEndDate = convertUTCToLocal(utcDate: endOfDay) else {
            let emptySleepPhaseModel = SleepPhaseModel(
                date: DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none),
                samples: []
            )
            print("Can't convert UTC to local end date sleep 1")
            return emptySleepPhaseModel
        }
        // Create predicate
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictEndDate)
        
        // Use a continuation to bridge the asynchronous query
        let samples: [HKCategorySample]? = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                if let error = error {
                    print("Error fetching sleep data: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: results as? [HKCategorySample])
                }
            }
            healthStore.execute(query)
        }
        
        // Handle no results case
        guard let sleepSamples = samples else {
            let emptySleepPhaseModel = SleepPhaseModel(
                date: DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none),
                samples: []
            )
            return emptySleepPhaseModel
        }
        
        var remSleepDuration: Double = 0.0
        var coreSleepDuration: Double = 0.0
        var deepSleepDuration: Double = 0.0
        var awakeTimeDuration: Double = 0.0
        
        var remSleepDate: Date? = nil
        var coreSleepDate: Date? = nil
        var deepSleepDate: Date? = nil
        var awakeTimeDate: Date? = nil
        var totalSleepStartDate: Date? = nil
        
        // Process sleep samples
        for sample in sleepSamples {
            let sleepDuration = sample.endDate.timeIntervalSince(sample.startDate)
            
            if sleepDuration <= 0 || sleepDuration > 86400 {
                continue
            }
            
            if #available(iOS 16.0, *) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    remSleepDuration += sleepDuration
                    if remSleepDate == nil {
                        remSleepDate = sample.endDate
                    }
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    coreSleepDuration += sleepDuration
                    if coreSleepDate == nil {
                        coreSleepDate = sample.endDate
                    }
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepSleepDuration += sleepDuration
                    if deepSleepDate == nil {
                        deepSleepDate = sample.endDate
                    }
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    awakeTimeDuration += sleepDuration
                    if awakeTimeDate == nil {
                        awakeTimeDate = sample.endDate
                    }
                default:
                    continue
                }
            } else {
                if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                    coreSleepDuration += sleepDuration
                    if remSleepDate == nil {
                        remSleepDate = sample.endDate
                    }
                }
            }
            
            if totalSleepStartDate == nil {
                totalSleepStartDate = sample.endDate
            }
        }
        
        let totalSleepDuration = remSleepDuration + coreSleepDuration + deepSleepDuration //+ awakeTimeDuration
        let finalTotalSleepDate = totalSleepStartDate ?? remSleepDate ?? coreSleepDate ?? deepSleepDate ?? awakeTimeDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let dateString = dateFormatter.string(from: date)
        
        // Prepare SleepPhaseModel
        let sleepPhaseModel = SleepPhaseModel(
            date: dateString,
            totalSleep: totalSleepDuration > 0 ? TotalSleep(dateWithTimeStamp: finalTotalSleepDate ?? Date(), totalSleep: totalSleepDuration) : nil,
            remSleep: remSleepDuration > 0 ? RemSleep(dateWithTimeStamp: remSleepDate ?? finalTotalSleepDate!, remSleep: remSleepDuration) : nil,
            coreSleep: coreSleepDuration > 0 ? CoreSleep(dateWithTimeStamp: coreSleepDate ?? finalTotalSleepDate!, coreSleep: coreSleepDuration) : nil,
            deepSleep: deepSleepDuration > 0 ? DeepSleep(dateWithTimeStamp: deepSleepDate ?? finalTotalSleepDate!, deepSleep: deepSleepDuration) : nil,
            awakeTime: awakeTimeDuration > 0 ? AwakeTime(dateWithTimeStamp: awakeTimeDate ?? finalTotalSleepDate!, awakeTime: awakeTimeDuration) : nil,
            samples: []  // Fill the samples array as needed
        )
        
        return sleepPhaseModel
    }

    // Function to merge overlapping sleep durations
//    func mergeOverlappingSleepPeriods(sleepData: [(start: Date, end: Date)]) -> [(start: Date, end: Date)] {
//        var mergedPeriods: [(start: Date, end: Date)] = []
//        let sortedPeriods = sleepData.sorted(by: { $0.start < $1.start })
//        for period in sortedPeriods {
//            if mergedPeriods.isEmpty {
//                mergedPeriods.append(period)
//            } else {
//                var last = mergedPeriods.last!
//                if period.start <= last.end { // Overlap exists
//                    last.end = max(last.end, period.end) // Merge
//                    mergedPeriods[mergedPeriods.count - 1] = last
//                } else {
//                    mergedPeriods.append(period)
//                }
//            }
//        }
//        return mergedPeriods
//    }
    
//    func fetchSleepData(completion: @escaping ([SleepPhaseModel]) -> Void) {
//        // Example HealthKit query setup
//        let calendar = Calendar.current
//        let endDate = Date()
//        let startDate = calendar.date(byAdding: .day, value: -13, to: endDate)!
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//        // Fetch sleep data from HealthKit
//        let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, results, error) in
//            guard error == nil else {
//                print("Error fetching sleep data: \(error?.localizedDescription ?? "")")
//                return
//            }
//            var sleepDataArray: [SleepPhaseModel] = []
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "dd-MM-yyyy"
//            if let sleepSamples = results as? [HKCategorySample] {
//                for sample in sleepSamples {
//                    let sleepDate = dateFormatter.string(from: sample.startDate)
//                    let totalSleep = sample.endDate.timeIntervalSince(sample.startDate)
//                    var remSleep: Double = 0.0
//                    var coreSleep: Double = 0.0
//                    var deepSleep: Double = 0.0
//                    // Use iOS version check for sleep stages available in iOS 16+
//                    if #available(iOS 16.0, *) {
//                        let sleepType = sample.value // Sleep stage (REM, core, deep)
//                        switch sleepType {
//                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
//                            remSleep = totalSleep
//                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
//                            coreSleep = totalSleep
//                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
//                            deepSleep = totalSleep
//                        default:
//                            break
//                        }
//                    } else {
//                        // For iOS versions before 16, treat all sleep as unspecified
//                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
//                            coreSleep = totalSleep // Treat as general sleep for earlier versions
//                        }
//                    }
//                    // Create the sleep phase model for the specific date
//                    let sleepModel = SleepPhaseModel(date: sleepDate, totalSleep: totalSleep, remSleep: remSleep, coreSleep: coreSleep, deepSleep: deepSleep)
//                    
//                    sleepDataArray.append(sleepModel)
//                }
//            }
//            // Return the data via the completion handler
//            completion(sleepDataArray)
//        }
//        let healthStore = HKHealthStore()
//        healthStore.execute(query)
//    }
}
extension Date {
    static var currentTimeStamp: Int64{
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}

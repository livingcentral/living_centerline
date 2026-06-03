//
//  RestingEnergyManager.swift
//  Living-Centerline
//
//  Created by APPLE on 26/12/24.
//

import Foundation
import HealthKit

class RestingEnergyManager {
    // MARK: Outlets
    let healthStore = HKHealthStore()

    // Method to retrieve resting energy burned for a single day hk sample query
//    func retrieveRestingEnergyForDate(date: Date, completion: @escaping ([RestingEnergySampleModel]) -> Void) {
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Get the start and end of the day for the given date
//        let startOfDay = calendar.startOfDay(for: date)
//        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)
//        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
//              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
//            print("Error converting date to local time.")
//            completion([])
//            return
//        }
//
//        // Create predicate for the specific day
//        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictEndDate)
//
//        // Ensure the resting energy type is available
//        guard let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
//            print("Resting Energy Burned type is not available.")
//            completion([])
//            return
//        }
//
//        // Create the sample query
//        let query = HKSampleQuery(sampleType: restingEnergyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard error == nil else {
//                print("Error fetching resting energy burned: \(error!.localizedDescription)")
//                completion([])
//                return
//            }
//
//            var restingEnergySamples: [RestingEnergySampleModel] = []
//
//            if let results = results as? [HKQuantitySample] {
//                for sample in results {
//                    let restingEnergyValue = sample.quantity.doubleValue(for: HKUnit.kilocalorie()) // Resting energy in kilocalories
//                    guard let localTimestamp = convertLocalToUTC(localDate: sample.startDate) else {
//                        continue
//                    }
//
//                    // Ensure the sample's start date matches the input date
//                                    if calendar.isDate(sample.startDate, inSameDayAs: date) {
//                                        let dateString = dateFormatter.string(from: localTimestamp)
//
//                                        let energySample = RestingEnergySampleModel(
//                                            date: dateString,
//                                            restingEnergy: restingEnergyValue,
//                                            dateWithTimeStamp: localTimestamp
//                                        )
//
//                                        restingEnergySamples.append(energySample)
//                                    }
//                }
//            }
//
//            completion(restingEnergySamples)
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }
    func retrieveRestingEnergyForDate(date: Date) async -> [RestingEnergySampleModel] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Get the start and end of the day for the given date
        let startOfDay = calendar.startOfDay(for: date)
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)

        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
            print("Error converting date to local time.")
            return []
        }

        // Create predicate for the specific day
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictEndDate)

        // Ensure the resting energy type is available
        guard let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            print("Resting Energy Burned type is not available.")
            return []
        }

        // ⬇️ Updated: Use `HKStatisticsCollectionQuery` for daily sum aggregation
        let query = HKStatisticsCollectionQuery(
            quantityType: restingEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: Date()),
            intervalComponents: DateComponents(day: 1)
        )

        return await withCheckedContinuation { continuation in
            query.initialResultsHandler = { _, result, error in
                guard let result = result, error == nil else {
                    print("Error fetching resting energy burned: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: [])
                    return
                }

                var restingEnergySamples: [RestingEnergySampleModel] = []

                result.enumerateStatistics(from: startOfDay, to: endOfToday ?? Date()) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let restingEnergyValue = sum.doubleValue(for: HKUnit.kilocalorie())

                        guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
                            return
                        }

                        let dateString = dateFormatter.string(from: localTimestamp)

                        let energySample = RestingEnergySampleModel(
                            date: dateString,
                            restingEnergy: restingEnergyValue,
                            dateWithTimeStamp: localTimestamp
                        )

                        restingEnergySamples.append(energySample)
                    }
                }

                continuation.resume(returning: restingEnergySamples)
            }

            // Execute the query
            healthStore.execute(query)
        }
    }
    func fetchRestingEnergyBurned(numberOfDays: Int) async -> [RestingEnergyModel] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Determine the date range
        let endDate = calendar.startOfDay(for: Date()) // Today
        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
            print("Can't convert date to local end date for resting energy.")
            return []
        }
        let startDate = calendar.date(byAdding: .day, value: numberOfDays, to: endDate)!
        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
            print("Can't convert date to local start date for resting energy.")
            return []
        }

        // Array to store aggregated resting energy data
        var restingEnergyDataArray: [RestingEnergyModel] = []
        let maxRetries = 3 // Maximum retries for each date

        // Function to handle retry logic for fetching data for a single date
        func fetchRestingEnergyForDateWithRetry(targetDate: Date, retries: Int = 0) async {
            guard let UTCTargetDate = convertLocalToUTC(localDate: targetDate) else {
                print("Can't convert local to UTC date for resting energy.")
                return
            }

            do {
                let samples = await retrieveRestingEnergyForDate(date: UTCTargetDate)

                if !samples.isEmpty {
                    // Calculate the total resting energy burned for the day
                    let totalRestingEnergy = samples.reduce(0) { $0 + $1.restingEnergy }
                    guard let tempDate = samples.first?.dateWithTimeStamp else {
                        print("Cannot convert optional to non-optional date for resting energy.")
                        return
                    }

                    // Get the date string
                    guard let tempTargetDate = convertLocalToUTC(localDate: tempDate) else {
                        print("Can't convert local to UTC date for resting energy.")
                        return
                    }
                    let dateString = dateFormatter.string(from: tempTargetDate)

                    // Create RestingEnergyValue and RestingEnergyModel
                    let restingEnergyValue = RestingEnergyValue(
                        restingEnergy: totalRestingEnergy.rounded(),
                        dateWithTimeStamp: tempDate
                    )

                    let restingEnergyModel = RestingEnergyModel(
                        date: dateString,
                        restingEnergy: restingEnergyValue,
                        dateWithTimeStamp: tempTargetDate,
                        samples: samples
                    )
                    DispatchQueue.main.async { [weak self] in
                        restingEnergyDataArray.append(restingEnergyModel)
                    }
                } else {
                    // Retry if no data is found
                    if retries < maxRetries {
                    //    print("Resting energy retrying for date \(dateFormatter.string(from: targetDate)), attempt \(retries + 1)")
                        await fetchRestingEnergyForDateWithRetry(targetDate: targetDate, retries: retries + 1)  // Retry fetch for this date
                    } else {
                      //  print("Resting energy no data found for date \(dateFormatter.string(from: targetDate)) after retries.")
                    }
                }
            } catch {
                print("Error fetching resting energy data: \(error.localizedDescription)")
            }
        }

        // Iterate through each day in the range and fetch data
        await withTaskGroup(of: Void.self) { taskGroup in
            for offset in 0..<abs(numberOfDays) {
                if let targetDate = calendar.date(byAdding: .day, value: offset, to: localStartDate) {
                    taskGroup.addTask {
                        await fetchRestingEnergyForDateWithRetry(targetDate: targetDate)
                    }
                }
            }
        }

        // Sort the final results
        if !restingEnergyDataArray.isEmpty {
            DispatchQueue.main.async {
                restingEnergyDataArray.sort { $0.date < $1.date }
            }
            return restingEnergyDataArray

        } else {
            return []
        }

    }
    // working 5 feb
    // Method to retrieve resting energy burned for a single day hk collection query
//    func retrieveRestingEnergyForDate(date: Date, completion: @escaping ([RestingEnergySampleModel]) -> Void) {
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Get the start and end of the day for the given date
//        let startOfDay = calendar.startOfDay(for: date)
//        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)
//
//        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
//              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
//            print("Error converting date to local time.")
//            completion([])
//            return
//        }
//
//        // Create predicate for the specific day
//        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictEndDate)
//
//        // Ensure the resting energy type is available
//        guard let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
//            print("Resting Energy Burned type is not available.")
//            completion([])
//            return
//        }
//
//        // ⬇️ Updated: Use `HKStatisticsCollectionQuery` for daily sum aggregation
//        let query = HKStatisticsCollectionQuery(
//            quantityType: restingEnergyType,
//            quantitySamplePredicate: predicate,
//            options: .cumulativeSum,
//            anchorDate: calendar.startOfDay(for: Date()),
//            intervalComponents: DateComponents(day: 1)
//        )
//
//        query.initialResultsHandler = { _, result, error in
//            guard let result = result, error == nil else {
//                print("Error fetching resting energy burned: \(error?.localizedDescription ?? "Unknown error")")
//                completion([])
//                return
//            }
//
//            var restingEnergySamples: [RestingEnergySampleModel] = []
//
//            result.enumerateStatistics(from: startOfDay, to: endOfToday ?? Date()) { statistics, _ in
//                if let sum = statistics.sumQuantity() {
//                    let restingEnergyValue = sum.doubleValue(for: HKUnit.kilocalorie())
//
//                    guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
//                        return
//                    }
//
//                    let dateString = dateFormatter.string(from: localTimestamp)
//
//                    let energySample = RestingEnergySampleModel(
//                        date: dateString,
//                        restingEnergy: restingEnergyValue,
//                        dateWithTimeStamp: localTimestamp
//                    )
//
//                    restingEnergySamples.append(energySample)
//                }
//            }
//
//            completion(restingEnergySamples)
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }
//    func fetchRestingEnergyBurned(numberOfDays: Int, completion: @escaping ([RestingEnergyModel]) -> Void) {
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Determine the date range
//        let endDate = calendar.startOfDay(for: Date()) // Today
//        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
//            print("Can't convert date to local end date for resting energy.")
//            return
//        }
//        let startDate = calendar.date(byAdding: .day, value: numberOfDays, to: endDate)!
//        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
//            print("Can't convert date to local start date for resting energy.")
//            return
//        }
//
//        // Array to store aggregated resting energy data
//        var restingEnergyDataArray: [RestingEnergyModel] = []
//        let dispatchGroup = DispatchGroup() // To synchronize asynchronous calls
//        let maxRetries = 3 // Maximum retries for each date
//
//        for offset in 0..<abs(numberOfDays) {
//            if let targetDate = calendar.date(byAdding: .day, value: offset, to: localStartDate) {
//                guard let UTCTargetDate = convertLocalToUTC(localDate: targetDate) else {
//                    print("Can't convert local to UTC date for resting energy.")
//                    return
//                }
//                
//                var retries = 0
//
//                // Retry mechanism for each date
//                func fetchRestingEnergyForDateWithRetry() {
//                    dispatchGroup.enter()
//                    retrieveRestingEnergyForDate(date: targetDate) { samples in
//                        if !samples.isEmpty {
//                            // Calculate the total resting energy burned for the day
//                            let totalRestingEnergy = samples.reduce(0) { $0 + $1.restingEnergy }
//                            guard let tempDate = samples.first?.dateWithTimeStamp else {
//                                print("Cannot convert optional to non-optional date for resting energy.")
//                                return
//                            }
//                            // Get the date string
//                            guard let tempTargetDate = convertLocalToUTC(localDate: tempDate) else {
//                                print("Can't convert local to UTC date for resting energy.")
//                                return
//                            }
//                            let dateString = dateFormatter.string(from: tempTargetDate)
//                            // Create RestingEnergyValue and RestingEnergyModel
//                            let restingEnergyValue = RestingEnergyValue(
//                                restingEnergy: totalRestingEnergy.rounded(),
//                                dateWithTimeStamp: tempDate
//                            )
//
//                            let restingEnergyModel = RestingEnergyModel(
//                                date: dateString,
//                                restingEnergy: restingEnergyValue,
//                                dateWithTimeStamp: tempDate,
//                                samples: samples
//                            )
//
//                            restingEnergyDataArray.append(restingEnergyModel)
//                        } else {
//                            // Retry if no data is found
//                            if retries < maxRetries {
//                                retries += 1
//                                print("resting energy Retrying for date \(dateFormatter.string(from: targetDate)), attempt \(retries)")
//                                fetchRestingEnergyForDateWithRetry()  // Retry fetch for this date
//                            } else {
//                                print("resting energy No data found for date \(dateFormatter.string(from: targetDate)) after retries.")
//                            }
//                        }
//                        dispatchGroup.leave()
//                    }
//                }
//
//                fetchRestingEnergyForDateWithRetry() // Fetch data for the date, including retries
//            }
//        }
//
//        // Once all async tasks are completed, return the aggregated results
//        dispatchGroup.notify(queue: .main) {
//            if restingEnergyDataArray.count > 0 {
//                restingEnergyDataArray.sort { $0.date < $1.date }
//                // restingEnergyDataArray.remove(at: 0) // Remove extra entry
//                completion(restingEnergyDataArray)
//            } else {
//                completion([])
//            }
//        }
//    }
}

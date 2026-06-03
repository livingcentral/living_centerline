//
//  ActiveEnergyManager.swift
//  Living-Centerline
//
//  Created by Developer on 11/10/24.
//

import HealthKit
class ActiveEnergyManager {
    // MARK: Outlets
    let healthStore = HKHealthStore()
    
    // Method to retrieve active energy burned for a single day hk collection query
    

    // Method to retrieve active energy burned for a single day hk sample query
//    func retrieveActiveEnergyForDate(date: Date, completion: @escaping ([ActiveEnergySampleModel]) -> Void) {
//        let healthStore = HKHealthStore()
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Get the start and end of the day for the given date
//        let startOfDay = calendar.startOfDay(for: date)
//        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
//              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
//            print("Error converting date to local time.")
//            completion([])
//            return
//        }
//        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)
//
//        // Create predicate for the specific day
//        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictEndDate)
//
//        // Ensure the active energy type is available
//        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
//            print("Active Energy Burned type is not available.")
//            completion([])
//            return
//        }
//
//        // Create the sample query
//        let query = HKSampleQuery(sampleType: activeEnergyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard error == nil else {
//                print("Error fetching active energy burned: \(error!.localizedDescription)")
//                completion([])
//                return
//            }
//
//            var activeEnergySamples: [ActiveEnergySampleModel] = []
//
//            if let results = results as? [HKQuantitySample] {
//                for sample in results {
//                    let activeEnergyValue = sample.quantity.doubleValue(for: HKUnit.kilocalorie()) // Active energy in kilocalories
//                    guard let localTimestamp = convertLocalToUTC(localDate: sample.startDate) else {
//                        continue
//                    }
//                    
//                    let dateString = dateFormatter.string(from: localTimestamp)
//
//                    let energySample = ActiveEnergySampleModel(
//                        date: dateString,
//                        activeEnergy: activeEnergyValue,
//                        dateWithTimeStamp: localTimestamp
//                    )
//
//                    activeEnergySamples.append(energySample)
//                }
//            }
//
//            completion(activeEnergySamples)
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }
    func retrieveActiveEnergyForDate(date: Date) async throws -> [ActiveEnergySampleModel] {
        let healthStore = HKHealthStore()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Get the start and end of the day for the given date
        let startOfDay = calendar.startOfDay(for: date)
        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
            print("Error converting date to local time.")
            throw NSError(domain: "HealthKitError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error converting date to local time."])
        }
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)

        // Create predicate for the specific day
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictEndDate)

        // Ensure the active energy type is available
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            print("Active Energy Burned type is not available.")
            throw NSError(domain: "HealthKitError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Active Energy Burned type is not available."])
        }

        // ⬇️ Updated: Use `HKStatisticsCollectionQuery` for daily sum aggregation
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: Date()),
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, result, error in
                guard let result = result, error == nil else {
                    print("Error fetching active energy burned: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(throwing: error ?? NSError(domain: "HealthKitError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                    return
                }

                var activeEnergySamples: [ActiveEnergySampleModel] = []

                result.enumerateStatistics(from: startOfDay, to: endOfToday ?? Date()) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let activeEnergyValue = sum.doubleValue(for: HKUnit.kilocalorie())

                        guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
                            return
                        }

                        let dateString = dateFormatter.string(from: localTimestamp)

                        let energySample = ActiveEnergySampleModel(
                            date: dateString,
                            activeEnergy: activeEnergyValue,
                            dateWithTimeStamp: localTimestamp
                        )

                        activeEnergySamples.append(energySample)
                    }
                }

                continuation.resume(returning: activeEnergySamples)
            }

            // Execute the query
            healthStore.execute(query)
        }
    }
    func fetchActiveEnergyBurned(numberOfDays: Int) async -> [ActiveEnergyModel] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Determine the date range
        let endDate = calendar.startOfDay(for: Date()) // Today
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: endDate)! // Start of previous day
        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
            print("Can't convert date to local end date for active energy")
            return []
        }
        let startDate = calendar.date(byAdding: .day, value: -abs(numberOfDays), to: localEndDate)!
        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
            print("Can't convert date to local start date for active energy")
            return []
        }

        // Array to store aggregated active energy data
        var activeEnergyDataArray: [ActiveEnergyModel] = []

        // Function to handle retry logic
        func fetchForDate(date: Date, retries: Int = 2) async {
            guard let UTCTargetDate = convertLocalToUTC(localDate: date) else {
                print("Can't convert date to local target date for active energy")
                return
            }

            do {
                let samples = try await retrieveActiveEnergyForDate(date: UTCTargetDate)

                if !samples.isEmpty {
                    // Calculate the total active energy burned for the day
                    let totalActiveEnergy = samples.reduce(0) { $0 + $1.activeEnergy }
                    if let tempDate = samples.last?.dateWithTimeStamp,
                       let tempTargetDate = convertLocalToUTC(localDate: tempDate) {
                        let activeEnergyValue = ActiveEnergyValue(
                            activeEnergy: floor(totalActiveEnergy),
                            dateWithTimeStamp: tempTargetDate
                        )
                        let activeEnergyModel = ActiveEnergyModel(
                            date: dateFormatter.string(from: tempTargetDate),
                            activeEnergy: activeEnergyValue,
                            dateWithTimeStamp: tempTargetDate,
                            samples: samples
                        )
                        DispatchQueue.main.async {
                            activeEnergyDataArray.append(activeEnergyModel)

                        }
                    }
                } else if retries > 0 {
                  //  print(" active energy Retrying for date \(dateFormatter.string(from: date)), remaining retries: \(retries)")
                    await fetchForDate(date: date, retries: retries - 1) // Retry with decremented retry count
                } else {
                //    print("No active energy data available for date: \(dateFormatter.string(from: date)) after retries")
                }
            } catch {
                print("Error fetching active energy data: \(error.localizedDescription)")
            }
        }

        // Iterate through each day in the range
        await withTaskGroup(of: Void.self) { taskGroup in
            for offset in 0..<abs(numberOfDays) {
                if let targetDate = calendar.date(byAdding: .day, value: offset, to: localStartDate) {
                    taskGroup.addTask {
                        await fetchForDate(date: targetDate)
                    }
                }
            }
        }

        // Sort the final results
            activeEnergyDataArray.sort { $0.date < $1.date }
            return activeEnergyDataArray
        
    }
    // working 5 feb
//    func retrieveActiveEnergyForDate(date: Date, completion: @escaping ([ActiveEnergySampleModel]) -> Void) {
//        let healthStore = HKHealthStore()
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Get the start and end of the day for the given date
//        let startOfDay = calendar.startOfDay(for: date)
//        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
//              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
//            print("Error converting date to local time.")
//            completion([])
//            return
//        }
//        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)
//
//        // Create predicate for the specific day
//        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictEndDate)
//
//        // Ensure the active energy type is available
//        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
//            print("Active Energy Burned type is not available.")
//            completion([])
//            return
//        }
//
//        // ⬇️ Updated: Use `HKStatisticsCollectionQuery` for daily sum aggregation
//        let query = HKStatisticsCollectionQuery(
//            quantityType: activeEnergyType,
//            quantitySamplePredicate: predicate,
//            options: .cumulativeSum,
//            anchorDate: calendar.startOfDay(for: Date()),
//            intervalComponents: DateComponents(day: 1)
//        )
//
//        query.initialResultsHandler = { _, result, error in
//            guard let result = result, error == nil else {
//                print("Error fetching active energy burned: \(error?.localizedDescription ?? "Unknown error")")
//                completion([])
//                return
//            }
//
//            var activeEnergySamples: [ActiveEnergySampleModel] = []
//
//            result.enumerateStatistics(from: startOfDay, to: endOfToday ?? Date()) { statistics, _ in
//                if let sum = statistics.sumQuantity() {
//                    let activeEnergyValue = sum.doubleValue(for: HKUnit.kilocalorie())
//
//                    guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
//                        return
//                    }
//
//                    let dateString = dateFormatter.string(from: localTimestamp)
//
//                    let energySample = ActiveEnergySampleModel(
//                        date: dateString,
//                        activeEnergy: activeEnergyValue,
//                        dateWithTimeStamp: localTimestamp
//                    )
//
//                    activeEnergySamples.append(energySample)
//                }
//            }
//
//            completion(activeEnergySamples)
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }
//    func fetchActiveEnergyBurned(numberOfDays: Int, completion: @escaping ([ActiveEnergyModel]) -> Void) {
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Determine the date range
//        let endDate = calendar.startOfDay(for: Date()) // Today
//        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: endDate)! // Start of previous day
//        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
//            print("Can't convert date to local end date for active energy")
//            completion([])
//            return
//        }
//        let startDate = calendar.date(byAdding: .day, value: -abs(numberOfDays), to: localEndDate)!
//        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
//            print("Can't convert date to local start date for active energy")
//            completion([])
//            return
//        }
//
//        // Array to store aggregated active energy data
//        var activeEnergyDataArray: [ActiveEnergyModel] = []
//        let dispatchGroup = DispatchGroup() // To synchronize asynchronous calls
//
//        // Function to handle retry logic
//        func fetchForDate(date: Date, retries: Int = 2) {
//            dispatchGroup.enter()
//
//            guard let UTCTargetDate = convertLocalToUTC(localDate: date) else {
//                print("Can't convert date to local target date for active energy")
//                dispatchGroup.leave()
//                return
//            }
//
//            retrieveActiveEnergyForDate(date: UTCTargetDate) { samples in
//                defer { dispatchGroup.leave() } // Ensure dispatchGroup.leave() is always called
//
//                if !samples.isEmpty {
//                    // Calculate the total active energy burned for the day
//                    let totalActiveEnergy = samples.reduce(0) { $0 + $1.activeEnergy }
//                    if let tempDate = samples.last?.dateWithTimeStamp,
//                       let tempTargetDate = convertLocalToUTC(localDate: tempDate) {
//                        let activeEnergyValue = ActiveEnergyValue(
//                            activeEnergy: totalActiveEnergy.rounded(),
//                            dateWithTimeStamp: tempTargetDate
//                        )
//                        let activeEnergyModel = ActiveEnergyModel(
//                            date: dateFormatter.string(from: tempTargetDate),
//                            activeEnergy: activeEnergyValue,
//                            dateWithTimeStamp: tempTargetDate,
//                            samples: samples
//                        )
//                        activeEnergyDataArray.append(activeEnergyModel)
//                    }
//                } else if retries > 0 {
//                    print("Retrying for date \(dateFormatter.string(from: date)), remaining retries: \(retries)")
//                    fetchForDate(date: date, retries: retries - 1) // Retry with decremented retry count
//                } else {
//                    print("No active energy data available for date: \(dateFormatter.string(from: date)) after retries")
//                }
//            }
//        }
//
//        // Iterate through each day in the range
//        for offset in 0..<abs(numberOfDays) {
//            if let targetDate = calendar.date(byAdding: .day, value: offset, to: localStartDate) {
//                fetchForDate(date: targetDate)
//            }
//        }
//
//        // Notify when all tasks are completed
//        dispatchGroup.notify(queue: .main) {
//            if activeEnergyDataArray.count > 0 {
//                activeEnergyDataArray.sort { $0.date < $1.date }
//                completion(activeEnergyDataArray)
//            } else {
//                completion([])
//            }
//        }
//    }

}

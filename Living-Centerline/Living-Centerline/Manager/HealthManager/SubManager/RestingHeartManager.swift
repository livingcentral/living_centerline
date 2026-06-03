//
//  RestingHeartManager.swift
//  Living-Centerline
//
//  Created by Developer on 11/10/24.
//

import HealthKit

class RestingHeartManager {
    // MARK: Outlets
    let healthStore = HKHealthStore()
   
    func retrieveRestingHeartRateForDate(date: Date) async throws -> [RestingHeartSampleModel] {
        let healthStore = HKHealthStore()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Get the start and end of the day for the given date
        let startOfDay = calendar.startOfDay(for: date)
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)

        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
            print("Error converting date to local time.")
            throw NSError(domain: "HealthKitError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error converting date to local time."])
        }

        // Create predicate for the specific day
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictEndDate)

        // Ensure the heart rate type is available
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            print("Resting heart rate type is not available.")
            throw NSError(domain: "HealthKitError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Resting heart rate type is not available."])
        }

        // Define the interval for aggregation (e.g., hourly)
        let interval = DateComponents(day: 1)

        return try await withCheckedThrowingContinuation { continuation in
            // Create statistics collection query
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: startOfDay,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, result, error in
                guard error == nil else {
                    print("Error fetching resting heart rate: \(error!.localizedDescription)")
                    continuation.resume(throwing: error!)
                    return
                }

                var heartRateSamples: [RestingHeartSampleModel] = []

                result?.enumerateStatistics(from: startOfDay, to: endOfToday!) { statistics, _ in
                    // Retrieve the average heart rate for each time interval (e.g., hourly)
                    if let heartRateValue = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        
                        // Convert the start date of the statistics to local time
                        guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
                        return
                    }
                    
                    let dateString = dateFormatter.string(from: localTimestamp)
                    
                    // Create the heart rate sample model with the aggregated data
                    let heartRateSample = RestingHeartSampleModel(
                        date: dateString,
                        heartValue: heartRateValue,
                        dateWithTimeStamp: localTimestamp
                    )
                    
                    heartRateSamples.append(heartRateSample)
                }
                }

                continuation.resume(returning: heartRateSamples)
            }

            // Execute the query
            healthStore.execute(query)
        }
    }
    func fetchRestingHeartRate(numberOfDays: Int) async -> [RestingHeartDataModel] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Determine the date range
        let endDate = calendar.startOfDay(for: Date()) // Today
        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
            print("Can't convert date to local end date for resting heart rate")
            return []
        }
        let startDate = calendar.date(byAdding: .day, value: -abs(numberOfDays), to: localEndDate)!
        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
            print("Can't convert date to local start date for resting heart rate")
            return []
        }

        var heartRateDataArray: [RestingHeartDataModel] = []
        
        // Function to handle retry logic
        func fetchForDate(date: Date, retries: Int = 3) async {
            guard let UTCTargetDate = convertLocalToUTC(localDate: date) else {
                print("Can't convert date to local target date for resting heart")
                return
            }

            do {
                let samples = try await retrieveRestingHeartRateForDate(date: UTCTargetDate)

                if !samples.isEmpty {
                    // Calculate average resting heart rate for the day
                    let totalHeartRate = samples.reduce(0) { $0 + $1.heartValue }
                    let averageHeartRate = totalHeartRate / Double(samples.count)

                    if let tempDate = samples.first?.dateWithTimeStamp,
                       let tempUTCDate = convertLocalToUTC(localDate: tempDate) {

                        let restingHeartValue = RestingHeartValue(
                            heartValue: averageHeartRate.rounded(),
                            dateWithTimeStamp: tempUTCDate
                        )

                        let heartRateDataModel = RestingHeartDataModel(
                            date: dateFormatter.string(from: tempDate),
                            heartRate: restingHeartValue,
                            dateWithTimeStamp: tempUTCDate,
                            samples: samples
                        )
                        DispatchQueue.main.async {
                            heartRateDataArray.append(heartRateDataModel)
                        }
                    }
                } else if retries > 0 {
                    // Retry logic for when samples are empty
                  //  print("Resting heart rate data missing for \(dateFormatter.string(from: date)), retrying (\(retries) retries left)")
                    await fetchForDate(date: date, retries: retries - 1) // Retry with decremented retry count
                } else {
                    // No data even after retries, log the failure
                   // print("No resting heart rate data available for date \(dateFormatter.string(from: date)) after retries")
                }
            } catch {
                print("Error fetching resting heart rate data for date \(dateFormatter.string(from: date)): \(error.localizedDescription)")
                if retries > 0 {
                    print("Retrying due to error... Remaining retries: \(retries)")
                    await fetchForDate(date: date, retries: retries - 1)
                }
            }
        }

        // Iterate through each day in the range and fetch data
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
        DispatchQueue.main.async {
            heartRateDataArray.sort { $0.date < $1.date }
        }

        return heartRateDataArray
    }
    // working 5 feb
//    func retrieveRestingHeartRateForDate(date: Date, completion: @escaping ([RestingHeartSampleModel]) -> Void) {
//        let healthStore = HKHealthStore()
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
//        // Ensure the heart rate type is available
//        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
//            print("Resting heart rate type is not available.")
//            completion([])
//            return
//        }
//
//        // Define the interval for aggregation (e.g., hourly)
//        let interval = DateComponents(day: 1)
//
//        // Create statistics collection query
//        let query = HKStatisticsCollectionQuery(quantityType: heartRateType,
//                                                 quantitySamplePredicate: predicate,
//                                                options: .discreteAverage,
//                                                 anchorDate: startOfDay,
//                                                 intervalComponents: interval)
//        
//        query.initialResultsHandler = { (query, result, error) in
//            guard error == nil else {
//                print("Error fetching resting heart rate: \(error!.localizedDescription)")
//                completion([])
//                return
//            }
//
//            var heartRateSamples: [RestingHeartSampleModel] = []
//
//            result?.enumerateStatistics(from: startOfDay, to: endOfToday!) { statistics, stop in
//                // Retrieve the average heart rate for each time interval (e.g., hourly)
//                if let heartRateValue = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
//                    
//                    // Convert the start date of the statistics to local time
//                    guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
//                        return
//                    }
//                    
//                    let dateString = dateFormatter.string(from: localTimestamp)
//                    
//                    // Create the heart rate sample model with the aggregated data
//                    let heartRateSample = RestingHeartSampleModel(
//                        date: dateString,
//                        heartValue: heartRateValue,
//                        dateWithTimeStamp: localTimestamp
//                    )
//                    
//                    heartRateSamples.append(heartRateSample)
//                }
//            }
//
//            completion(heartRateSamples)
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }
//    func fetchRestingHeartRate(numberOfDays: Int, completion: @escaping ([RestingHeartDataModel]) -> Void) {
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Determine the date range
//        let endDate = calendar.startOfDay(for: Date()) // Today
//        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
//            print("Can't convert date to local end date for resting heart rate")
//            completion([])
//            return
//        }
//        let startDate = calendar.date(byAdding: .day, value: -abs(numberOfDays), to: localEndDate)!
//        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
//            print("Can't convert date to local start date for resting heart rate")
//            completion([])
//            return
//        }
//
//        var heartRateDataArray: [RestingHeartDataModel] = []
//        let dispatchGroup = DispatchGroup() // To synchronize asynchronous calls
//
//        // Function to handle retry logic
//        func fetchForDate(date: Date, retries: Int = 3) {
//            dispatchGroup.enter()
//            
//            guard let UTCTargetDate = convertLocalToUTC(localDate: date) else {
//                print("Can't convert date to local target date for resting heart")
//                dispatchGroup.leave()
//                return
//            }
//            
//            retrieveRestingHeartRateForDate(date: UTCTargetDate) { samples in
//                defer { dispatchGroup.leave() } // Ensure dispatchGroup.leave() is always called
//
//                if !samples.isEmpty {
//                    // Calculate average resting heart rate for the day
//                    let totalHeartRate = samples.reduce(0) { $0 + $1.heartValue }
//                    let averageHeartRate = totalHeartRate / Double(samples.count)
//                    
//                    if let tempDate = samples.first?.dateWithTimeStamp,
//                       let tempUTCDate = convertLocalToUTC(localDate: tempDate) {
//                        let restingHeartValue = RestingHeartValue(
//                            heartValue: averageHeartRate.rounded(),
//                            dateWithTimeStamp: tempUTCDate
//                        )
//                        let heartRateDataModel = RestingHeartDataModel(
//                            date: dateFormatter.string(from: tempDate),
//                            heartRate: restingHeartValue,
//                            dateWithTimeStamp: tempUTCDate,
//                            samples: samples
//                        )
//                        DispatchQueue.main.async {
//                                               heartRateDataArray.append(heartRateDataModel)
//                                           }
//                    }
//                } else if retries > 0 {
//                    // Retry logic for when samples are empty
//                    print("Resting heart rate data missing for \(dateFormatter.string(from: date)), retrying (\(retries) retries left)")
//                    fetchForDate(date: date, retries: retries - 1) // Retry with decremented retry count
//                } else {
//                    // No data even after retries, log the failure
//                    print("No resting heart rate data available for date \(dateFormatter.string(from: date)) after retries")
//                }
//            }
//        }
//
//        // Iterate through each day in the range and fetch data
//        for offset in 0..<abs(numberOfDays) {
//            if let targetDate = calendar.date(byAdding: .day, value: offset, to: localStartDate) {
//                fetchForDate(date: targetDate)
//            }
//        }
//
//        // Notify when all tasks are completed
//        dispatchGroup.notify(queue: .main) {
//            if !heartRateDataArray.isEmpty {
//                heartRateDataArray.sort { $0.date < $1.date }
//                completion(heartRateDataArray)
//            } else {
//                completion([]) // Return empty if no data after all retries
//            }
//        }
//    }

}

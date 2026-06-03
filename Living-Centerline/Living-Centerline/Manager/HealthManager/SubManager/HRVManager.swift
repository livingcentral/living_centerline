//
//  HRVManager.swift
//  Living-Centerline
//
//  Created by Developer on 11/10/24.
//

import HealthKit
class HRVManager {
    // MARK: Outlets
    let healthStore = HKHealthStore()
    // Function to fetch HRV data for a single day using hk sample query
    //    func retrieveHRVForDate(date: Date, completion: @escaping ([HRVSampleModel]) -> Void) {
    //        let healthStore = HKHealthStore()
    //        let calendar = Calendar.current
    //        let dateFormatter = DateFormatter()
    //        dateFormatter.dateFormat = "MM-dd-yyyy"
    //
    //        // Define the HRV quantity type
    //        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
    //            print("HRV Type is not available.")
    //            completion([])
    //            return
    //        }
    //
    //        // Calculate the start and end of the day
    //        let startOfDay = calendar.startOfDay(for: date)
    //        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
    //              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
    //            print("Error converting date to local time.")
    //            completion([])
    //            return
    //        }
    //
    //        // Create a predicate for the specific day
    //        let predicate = HKQuery.predicateForSamples(withStart: localStartOfDay, end: localEndOfDay, options: .strictEndDate)
    //
    //        // Create the sample query
    //        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
    //            guard error == nil else {
    //                print("Error fetching HRV data: \(error!.localizedDescription)")
    //                completion([])
    //                return
    //            }
    //
    //            var hrvSamples: [HRVSampleModel] = []
    //
    //            if let results = results as? [HKQuantitySample] {
    //                for sample in results {
    //                    guard let localTimestamp = convertLocalToUTC(localDate: sample.startDate) else {
    //                        continue
    //                    }
    //
    //                    let dateString = dateFormatter.string(from: localTimestamp)
    //                    let hrvValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    //
    //                    let hrvSample = HRVSampleModel(
    //                        date: dateString,
    //                        hrvValue: hrvValue,
    //                        dateWithTimeStamp: localTimestamp
    //                    )
    //
    //                    hrvSamples.append(hrvSample)
    //                }
    //            }
    //
    //            completion(hrvSamples)
    //        }
    //
    //        // Execute the query
    //        healthStore.execute(query)
    //    }
    func retrieveHRVForDate(date: Date) async throws -> [HRVSampleModel] {
        let healthStore = HKHealthStore()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        
        // Define the HRV quantity type
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            print("HRV Type is not available.")
            throw NSError(domain: "HealthKitError", code: 1, userInfo: [NSLocalizedDescriptionKey: "HRV Type is not available."])
        }
        
        // Calculate the start and end of the day
        let startOfDay = calendar.startOfDay(for: date)
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)
        
        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
            print("Error converting date to local time.")
            throw NSError(domain: "HealthKitError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error converting date to local time."])
        }
        
        // Create a date anchor
        let anchorDate = calendar.startOfDay(for: Date())
        
        // Define the interval (e.g., daily aggregation)
        var interval = DateComponents()
        interval.day = 1
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create the statistics collection query
            let query = HKStatisticsCollectionQuery(
                quantityType: hrvType,
                quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictStartDate),
                options: .discreteAverage,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            
            // Handle the query results
            query.initialResultsHandler = { _, results, error in
                guard error == nil else {
                    print("Error fetching HRV data: \(error!.localizedDescription)")
                    continuation.resume(throwing: error!)
                    return
                }
                
                var hrvSamples: [HRVSampleModel] = []
                
                results?.enumerateStatistics(from: localStartOfDay, to: localEndOfDay) { statistics, _ in
                    if let averageQuantity = statistics.averageQuantity() {
                        guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
                            return
                        }
                        
                        let dateString = dateFormatter.string(from: localTimestamp)
                        let hrvValue = averageQuantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                        
                        let hrvSample = HRVSampleModel(
                            date: dateString,
                            hrvValue: hrvValue,
                            dateWithTimeStamp: localTimestamp
                        )
                        
                        hrvSamples.append(hrvSample)
                    }
                }
                
                continuation.resume(returning: hrvSamples)
            }
            
            // Execute the query
            healthStore.execute(query)
        }
    }
    
    
    func fetchHRVDataForWeek(numberOfDays: Int) async -> [HRVDataModel] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        
        // Determine the date range
        let endDate = calendar.startOfDay(for: Date())
        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
            print("Can't convert date to local end date for HRV")
            return []
        }
        let startDate = calendar.date(byAdding: .day, value: -abs(numberOfDays), to: localEndDate)!
        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
            print("Can't convert date to local start date for HRV")
            return []
        }
        
        var hrvDataArray: [HRVDataModel] = []
        
        // Function to handle retry logic
        func fetchForDate(date: Date, retries: Int = 3) async {
            guard let localTargetDate = convertLocalToUTC(localDate: date) else {
                print("Can't convert date to local target date for HRV")
                return
            }
            
            do {
                let samples = try await retrieveHRVForDate(date: localTargetDate)
                
                if !samples.isEmpty {
                    // Calculate the average HRV for the day
                    let totalHRV = samples.reduce(0) { $0 + $1.hrvValue }
                    let averageHRV = totalHRV / Double(samples.count)
                    
                    // Ensure we have a valid timestamp
                    if let tempDate = samples.first?.dateWithTimeStamp,
                       let tempTargetDate = convertLocalToUTC(localDate: tempDate) {
                        
                        let hrvValue = HRVValue(
                            hrvValue: averageHRV.rounded(),
                            dateWithTimeStamp: tempTargetDate
                        )
                        
                        let hrvDataModel = HRVDataModel(
                            date: dateFormatter.string(from: tempDate),
                            hrvValue: hrvValue,
                            samples: samples
                        )
                        
                        // Ensure thread safety before appending
                        DispatchQueue.main.async {
                            hrvDataArray.append(hrvDataModel)
                        }
                    }
                } else if retries > 0 {
                  //  print("HRV Retrying for date \(dateFormatter.string(from: date)), remaining retries: \(retries)")
                    await fetchForDate(date: date, retries: retries - 1) // Retry
                } else {
                    // print("No HRV data available for date: \(dateFormatter.string(from: date)) after retries")
                }
            } catch {
                print("Error fetching HRV data for date \(dateFormatter.string(from: date)): \(error.localizedDescription)")
                if retries > 0 {
                    print("Retrying due to error... Remaining retries: \(retries)")
                    await fetchForDate(date: date, retries: retries - 1)
                }
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
//        await MainActor.run {
//            hrvDataArray.sort { $0.date < $1.date }
//        }
        DispatchQueue.main.async {
            hrvDataArray.sort { $0.date < $1.date }
        }
            return hrvDataArray
        //        return hrvDataArray
    }
    // working 5 feb
    //    func retrieveHRVForDate(date: Date, completion: @escaping ([HRVSampleModel]) -> Void) {
    //        let healthStore = HKHealthStore()
    //        let calendar = Calendar.current
    //        let dateFormatter = DateFormatter()
    //        dateFormatter.dateFormat = "MM-dd-yyyy"
    //
    //        // Define the HRV quantity type
    //        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
    //            print("HRV Type is not available.")
    //            completion([])
    //            return
    //        }
    //
    //        // Calculate the start and end of the day
    //        let startOfDay = calendar.startOfDay(for: date)
    //        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)
    //        guard let localStartOfDay = convertUTCToLocal(utcDate: startOfDay),
    //              let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay) else {
    //            print("Error converting date to local time.")
    //            completion([])
    //            return
    //        }
    //
    //        // Create a date anchor
    //        let anchorDate = calendar.startOfDay(for: Date())
    //
    //        // Define the interval (e.g., hourly for more granularity)
    //        var interval = DateComponents()
    //        interval.day = 1
    //
    //        // Create the statistics collection query
    //        let query = HKStatisticsCollectionQuery(
    //            quantityType: hrvType,
    //            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startOfDay, end: endOfToday, options: .strictStartDate),
    //            options: .discreteAverage,
    //            anchorDate: anchorDate,
    //            intervalComponents: interval
    //        )
    //
    //        // Handle the query results
    //        query.initialResultsHandler = { _, results, error in
    //            guard error == nil else {
    //                print("Error fetching HRV data: \(error!.localizedDescription)")
    //                completion([])
    //                return
    //            }
    //
    //            var hrvSamples: [HRVSampleModel] = []
    //
    //            results?.enumerateStatistics(from: localStartOfDay, to: localEndOfDay) { statistics, _ in
    //                if let averageQuantity = statistics.averageQuantity() {
    //                    guard let localTimestamp = convertLocalToUTC(localDate: statistics.startDate) else {
    //                        return
    //                    }
    //
    //                    let dateString = dateFormatter.string(from: localTimestamp)
    //                    let hrvValue = averageQuantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    //
    //                    let hrvSample = HRVSampleModel(
    //                        date: dateString,
    //                        hrvValue: hrvValue,
    //                        dateWithTimeStamp: localTimestamp
    //                    )
    //
    //                    hrvSamples.append(hrvSample)
    //                }
    //            }
    //
    //            completion(hrvSamples)
    //        }
    //
    //        // Execute the query
    //        healthStore.execute(query)
    //    }
    //
    //    func fetchHRVDataForWeek(numberOfDays: Int, completion: @escaping ([HRVDataModel]) -> Void) {
    //        let calendar = Calendar.current
    //        let dateFormatter = DateFormatter()
    //        dateFormatter.dateFormat = "MM-dd-yyyy"
    //
    //        // Determine the date range
    //        let endDate = calendar.startOfDay(for: Date())
    //        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
    //            print("Can't convert date to local end date for HRV")
    //            completion([])
    //            return
    //        }
    //        let startDate = calendar.date(byAdding: .day, value: -abs(numberOfDays), to: localEndDate)!
    //        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
    //            print("Can't convert date to local start date for HRV")
    //            completion([])
    //            return
    //        }
    //
    //        var hrvDataArray: [HRVDataModel] = []
    //        let dispatchGroup = DispatchGroup() // To synchronize asynchronous calls
    //
    //        // Function to handle retry logic
    //        func fetchForDate(date: Date, retries: Int = 3) {
    //            dispatchGroup.enter()
    //
    //            guard let localTargetDate = convertLocalToUTC(localDate: date) else {
    //                print("Can't convert date to local target date for HRV")
    //                dispatchGroup.leave()
    //                return
    //            }
    //
    //            retrieveHRVForDate(date: localTargetDate) { samples in
    //                defer { dispatchGroup.leave() } // Ensure dispatchGroup.leave() is always called
    //
    //                if !samples.isEmpty {
    //                    // Calculate the average HRV for the day
    //                    let totalHRV = samples.reduce(0) { $0 + $1.hrvValue }
    //                    let averageHRV = totalHRV / Double(samples.count)
    //
    //                    // Check if samples first object is valid
    //                    if let tempDate = samples.first?.dateWithTimeStamp {
    //                        // Ensure that `convertLocalToUTC` does not return nil
    //                        guard let tempTargetDate = convertLocalToUTC(localDate: tempDate) else {
    //                            print("Error: Unable to convert local date to UTC for HRV.")
    //                            dispatchGroup.leave()
    //                            return
    //                        }
    //
    //                        // Create HRVValue and HRVDataModel
    //                        let hrvValue = HRVValue(
    //                            hrvValue: averageHRV.rounded(),
    //                            dateWithTimeStamp: tempTargetDate
    //                        )
    //
    //                        let hrvDataModel = HRVDataModel(
    //                            date: dateFormatter.string(from: tempDate),
    //                            hrvValue: hrvValue,
    //                            samples: samples
    //                        )
    //
    //                        // Ensure memory integrity before appending
    //                        if !Thread.isMainThread {
    //                            DispatchQueue.main.async {
    //                                hrvDataArray.append(hrvDataModel)
    //                            }
    //                        } else {
    //                                hrvDataArray.append(hrvDataModel)
    //                        }
    //                    }
    //                } else if retries > 0 {
    //                    print("HRV Retrying for date \(dateFormatter.string(from: date)), remaining retries: \(retries)")
    //                    fetchForDate(date: date, retries: retries - 1) // Retry with decremented retry count
    //                } else {
    //                    print("No HRV data available for date: \(dateFormatter.string(from: date)) after retries")
    //                }
    //            }
    //
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
    //            if hrvDataArray.count > 0 {
    //                hrvDataArray.sort { $0.date < $1.date }
    //                completion(hrvDataArray)
    //            } else {
    //                completion([])
    //            }
    //        }
    //    }
}

//
//  SleepManager.swift
//  Living-Centerline
//
//  Created by Developer on 11/10/24.
//

import HealthKit

class StepsManager {
    // MARK: Outlets
    let healthStore = HKHealthStore()
    var stepsDataArray = [StepDataModel]()
    // MARK: - fetch steps data of past week methods
//    func retrieveStepsForWeek(numberOfDays: Int, completion: @escaping ([StepDataModel], Error?) -> Void) {
//        guard let stepData = HKObjectType.quantityType(forIdentifier: .stepCount) else {
//          print("Steps identity not available")
//          return
//        }
//        let calendar = Calendar.current
//        // Calculate the start and end dates for the 14-day range
//        
//        let endDate = calendar.startOfDay(for: Date()) // Start of today
//        guard let localEndDate = convertUTCToLocal(utcDate: endDate) else {
//            print("can't convert date to local end date to steps")
//            return
//        }
//        let startDate = calendar.date(byAdding: .day, value: numberOfDays, to: endDate)! // 14 days ago
//        guard let localStartDate = convertUTCToLocal(utcDate: startDate) else {
//            print("can't convert date to local start date to steps")
//            return
//        }
//        print("Query Start Date: \(startDate)")
//        print("Query End Date: \(endDate)")
//        // Create a predicate for the query
//        let predicate = HKQuery.predicateForSamples(withStart: localStartDate, end: localEndDate, options: [])
//        // Create the sample query for steps
//        let tzName = TimeZone.current
//
//        print("time zone is \(calendar.timeZone)")
//        let query = HKSampleQuery(sampleType: stepData, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//          if let error = error {
//            print("Error fetching steps data: \(error.localizedDescription)")
//            completion([], error)
//            return
//          }
//          // Dictionary to group step samples by day
//          var stepsDataDict: [String: (samples: [StepSampleModel], totalSteps: Int, firstTimestamp: Date?)] = [:]
//          // Process the results
//          if let results = results as? [HKQuantitySample] {
//            for sample in results {
//              let stepCount = Int(sample.quantity.doubleValue(for: HKUnit.count()))
//                guard let localDate = convertLocalToUTC(localDate: sample.startDate) else {
//                    print("can't convert date to local date to steps")
//                    return
//                }
//                let timestamp = localDate
//              // Format the date to group by day (excluding time)
//              let dateFormatter = DateFormatter()
//              dateFormatter.dateFormat = "MM-dd-yyyy"
//              let dateString = dateFormatter.string(from: timestamp)
//              // Create a StepSampleModel for each sample
//              let stepSample = StepSampleModel(date: dateString, stepCount: stepCount, dateWithTimeStamp: timestamp)
//              // Group the data by date string
//              if stepsDataDict[dateString] == nil {
//                stepsDataDict[dateString] = (samples: [], totalSteps: 0, firstTimestamp: timestamp)
//              }
//              stepsDataDict[dateString]?.samples.append(stepSample)
//              stepsDataDict[dateString]?.totalSteps += stepCount
//              // Update the first timestamp if necessary
//              if let currentFirstTimestamp = stepsDataDict[dateString]?.firstTimestamp {
//                if timestamp < currentFirstTimestamp {
//                  stepsDataDict[dateString]?.firstTimestamp = timestamp
//                }
//              }
//            }
//          }
//          // Create an array to store the merged data for each day
//          var mergedStepsData: [StepDataModel] = []
//          for (dateString, stepData) in stepsDataDict {
//            // Ensure the first timestamp is not nil
//            guard let firstTimestamp = stepData.firstTimestamp else {
//              continue
//            }
//            // Create a TotalSteps object for the day
//            let totalSteps = TotalSteps(dateWithTimeStamp: firstTimestamp, totalSteps: stepData.totalSteps)
//            // Create a StepDataModel for the day
//            let dailyStepData = StepDataModel(
//              date: dateString,
//              totalSteps: totalSteps,
//              samples: stepData.samples
//            )
//            mergedStepsData.append(dailyStepData)
//          }
//          // Sort the data by the total steps dateWithTimeStamp in ascending order
//          mergedStepsData.sort { $0.totalSteps.dateWithTimeStamp < $1.totalSteps.dateWithTimeStamp }
//          // Return the sorted and merged steps data
//          completion(mergedStepsData, nil)
//        }
//        // Execute the query
//        healthStore.execute(query)
//      }
//    func retrieveStepsForWeek(numberOfDays: Int, completion: @escaping ([StepDataModel], Error?) -> Void) {
//        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
//            print("Step count identifier not available")
//            return
//        }
//
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Determine the date range
//        let endDate = calendar.startOfDay(for: Date()) // Start of today
//        guard let startDate = calendar.date(byAdding: .day, value: numberOfDays, to: endDate) else {
//            print("Error calculating start date")
//            return
//        }
//
//        print("Query Start Date: \(startDate)")
//        print("Query End Date: \(endDate)")
//
//        // Create a predicate for the query
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
//
//        // Create the query for aggregated data
//        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
//            if let error = error {
//                print("Error fetching step data: \(error.localizedDescription)")
//                completion([], error)
//                return
//            }
//
//            var stepsDataArray: [StepDataModel] = []
//
//            if let result = result, let sumQuantity = result.sumQuantity() {
//                // Total steps for the query interval
//                let totalSteps = Int(sumQuantity.doubleValue(for: HKUnit.count()))
//
//                // Start and end dates for the aggregated data
//                let startDate = result.startDate
//                let endDate = result.endDate
//
//                // Convert UTC dates to local dates
//                guard let localStartDate = convertUTCToLocal(utcDate: startDate),
//                      let localEndDate = convertUTCToLocal(utcDate: endDate) else {
//                    print("Can't convert UTC dates to local")
//                    return
//                }
//
//                // Format date string
//                let dateString = dateFormatter.string(from: localStartDate)
//
//                // Create a TotalSteps object
//                let totalStepsModel = TotalSteps(dateWithTimeStamp: localStartDate, totalSteps: totalSteps)
//
//                // Create a StepDataModel
//                let stepDataModel = StepDataModel(
//                    date: dateString,
//                    totalSteps: totalStepsModel,
//                    samples: [] // `HKStatisticsQuery` does not provide individual samples
//                )
//
//                stepsDataArray.append(stepDataModel)
//            }
//
//            // Return the result
//            completion(stepsDataArray, nil)
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }
    func retrieveStepsForWeek(numberOfDays: Int) async throws -> [StepDataModel] {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Step count identifier not available")
            throw NSError(domain: "HealthKitError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Step count identifier not available"])
        }

        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        // Determine the date range
        let utcEndDate = calendar.startOfDay(for: Date()) // Start of today in UTC
        guard let _ = convertUTCToLocal(utcDate: utcEndDate) else {
            print("Can't convert UTC to local end date")
            throw NSError(domain: "HealthKitError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Can't convert UTC to local end date"])
        }

        let utcStartDate = calendar.date(byAdding: .day, value: numberOfDays, to: utcEndDate)! // Number of days ago in UTC
        guard let _ = convertUTCToLocal(utcDate: utcStartDate) else {
            print("Can't convert UTC to local start date")
            throw NSError(domain: "HealthKitError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Can't convert UTC to local start date"])
        }

        // Set up the query interval
        let anchorDate = calendar.startOfDay(for: Date())
        var dateComponents = DateComponents()
        dateComponents.day = 1 // Interval of 1 day

        let predicate = HKQuery.predicateForSamples(withStart: utcStartDate, end: utcEndDate, options: [])

        let maxRetries = 2  // Maximum retries for each date
        var retries = 0

        while retries <= maxRetries {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    let query = HKStatisticsCollectionQuery(
                        quantityType: stepType,
                        quantitySamplePredicate: predicate,
                        options: .cumulativeSum,
                        anchorDate: anchorDate,
                        intervalComponents: dateComponents
                    )

                    query.initialResultsHandler = { _, results, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }

                        var stepsDataArray: [StepDataModel] = []

                        results?.enumerateStatistics(from: utcStartDate, to: utcEndDate, with: { statistics, _ in
                            if let sum = statistics.sumQuantity() {
                                let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                                let utcDate = statistics.startDate
                                guard let localDate = convertUTCToLocal(utcDate: utcDate) else {
                                    print("Can't convert UTC to local date")
                                    return
                                }
                                let dateString = dateFormatter.string(from: localDate)

                                // Create a TotalSteps object for the day
                                let totalSteps = TotalSteps(dateWithTimeStamp: localDate, totalSteps: stepCount)

                                // Create a StepDataModel for the day
                                let dailyStepData = StepDataModel(
                                    date: dateString,
                                    totalSteps: totalSteps,
                                    samples: [] // No individual samples because we are using aggregate data
                                )

                                stepsDataArray.append(dailyStepData)
                            }
                        })

                        // Sort the data by the total steps dateWithTimeStamp in ascending order
                        stepsDataArray.sort { $0.totalSteps.dateWithTimeStamp < $1.totalSteps.dateWithTimeStamp }

                        continuation.resume(returning: stepsDataArray)
                    }

                    // Execute the query
                    healthStore.execute(query)
                }
            } catch {
                print("Error fetching steps data: \(error.localizedDescription)")
                retries += 1
                if retries > maxRetries {
                    throw error // Throw error after max retries
                } else {
                    print("Retrying fetch steps data, attempt \(retries)")
                }
            }
        }

        throw NSError(domain: "HealthKitError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Max retries exceeded"])
    }
    // working hk collection query 5 feb 2025
//    func retrieveStepsForWeek(numberOfDays: Int, completion: @escaping ([StepDataModel], Error?) -> Void) {
//        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
//            print("Step count identifier not available")
//            return
//        }
//
//        let calendar = Calendar.current
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//
//        // Determine the date range
//        let utcEndDate = calendar.startOfDay(for: Date()) // Start of today in UTC
//        guard let localEndDate = convertUTCToLocal(utcDate: utcEndDate) else {
//            print("Can't convert UTC to local end date")
//            return
//        }
//        let utcStartDate = calendar.date(byAdding: .day, value: numberOfDays, to: utcEndDate)! // Number of days ago in UTC
//        guard let localStartDate = convertUTCToLocal(utcDate: utcStartDate) else {
//            print("Can't convert UTC to local start date")
//            return
//        }
//
//        // Set up the query interval
//        let anchorDate = calendar.startOfDay(for: Date())
//        var dateComponents = DateComponents()
//        dateComponents.day = 1 // Interval of 1 day
//
//        let predicate = HKQuery.predicateForSamples(withStart: utcStartDate, end: utcEndDate, options: [])
//
//        // Create the statistics collection query
//        let query = HKStatisticsCollectionQuery(
//            quantityType: stepType,
//            quantitySamplePredicate: predicate,
//            options: .cumulativeSum,
//            anchorDate: anchorDate,
//            intervalComponents: dateComponents
//        )
//
//        let maxRetries = 2  // Maximum retries for each date
//        var retries = 0
//
//        // Retry mechanism for the query
//        func executeQuery() {
//            healthStore.execute(query)
//        }
//
//        query.initialResultsHandler = { _, results, error in
//            if let error = error {
//                print("Error fetching steps data: \(error.localizedDescription)")
//                if retries < maxRetries {
//                    retries += 1
//                    print("Retrying fetch steps data, attempt \(retries)")
//                    executeQuery()  // Retry fetching data
//                } else {
//                    completion([], error)  // Return error after max retries
//                }
//                return
//            }
//
//            var stepsDataArray: [StepDataModel] = []
//
//            results?.enumerateStatistics(from: utcStartDate, to: utcEndDate, with: { statistics, _ in
//                if let sum = statistics.sumQuantity() {
//                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
//                    let utcDate = statistics.startDate
//                    guard let localDate = convertUTCToLocal(utcDate: utcDate) else {
//                        print("Can't convert UTC to local date")
//                        return
//                    }
//                    let dateString = dateFormatter.string(from: localDate)
//
//                    // Create a TotalSteps object for the day
//                    let totalSteps = TotalSteps(dateWithTimeStamp: localDate, totalSteps: stepCount)
//
//                    // Create a StepDataModel for the day
//                    let dailyStepData = StepDataModel(
//                        date: dateString,
//                        totalSteps: totalSteps,
//                        samples: [] // No individual samples because we are using aggregate data
//                    )
//
//                    stepsDataArray.append(dailyStepData)
//                }
//            })
//
//            // Sort the data by the total steps dateWithTimeStamp in ascending order
//            stepsDataArray.sort { $0.totalSteps.dateWithTimeStamp < $1.totalSteps.dateWithTimeStamp }
//
//            // Return the sorted and aggregated steps data
//            completion(stepsDataArray, nil)
//        }
//
//        // Execute the query initially
//        executeQuery()
//    }

//    private func totalStepsForDate(_ dateString: String) -> Int {
//        // Your input date string should match the format "dd/MM/yyyy"
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd-MM-yyyy" // Ensure date format matches
//        // Convert the input date string to a Date object
//        guard let inputDate = dateFormatter.date(from: dateString) else {
//            print("Invalid date format")
//            return 0
//        }
//        // Iterate through stepsDataArray to sum up steps for the input date
//        var totalSteps = 0
//        for data in stepsDataArray {
//            // Compare the StepDataModel's date directly with inputDate
//            if Calendar.current.isDate(data.date, inSameDayAs: inputDate) {
//                totalSteps += data.totalSteps ?? 0
//            }
//        }
//        //print("Total steps for \(dateString): \(totalSteps)")
//        return totalSteps
//    }
}

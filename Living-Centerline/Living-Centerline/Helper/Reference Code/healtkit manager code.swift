//
//  healtkit manager code.swift
//  Living-Centerline
//
//  Created by Developer on 10/10/24.
//

//import Foundation
// MARK: heart data retrieval method
//    func fetchHeartRateSamplesForWeek(completion: @escaping ([String: [String: Double]]) -> Void) {
//        guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
//            completion([:])
//            return
//        }
//        // Set up a predicate for the last 7 days
//        let calendar = Calendar.current
//        let endDate = Date()
//        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
//
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//
//        // Sort by date
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
//
//        // Create the query
//        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (_, results, error) in
//
//            guard error == nil else {
//                print("Error: \(error!.localizedDescription)")
//                completion([:])
//                return
//            }
//            // Organize the heart rate data by date and hour
//            var heartRateData: [String: [Double]] = [:]
//            var heartRateCounts: [String: [Int]] = [:] // To keep track of sample counts for averaging
//
//            if let heartRateSamples = results as? [HKQuantitySample] {
//                // Initialize data structure for each day
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "dd-MM-yyyy" // Format for date key
//                let hourFormatter = DateFormatter()
//                hourFormatter.dateFormat = "HH:mm" // Format for hour key
//
//                for sample in heartRateSamples {
//                    let date = sample.startDate
//                    let dateKey = dateFormatter.string(from: date)
//                    let hourKey = hourFormatter.string(from: date)
//
//                    // Initialize the array for the date if it doesn't exist
//                    if heartRateData[dateKey] == nil {
//                        heartRateData[dateKey] = Array(repeating: 0.0, count: 24) // 24 hours
//                        heartRateCounts[dateKey] = Array(repeating: 0, count: 24) // Count for averaging
//                    }
//
//                    // Calculate the hour index
//                    if let hourIndex = Int(hourKey) {
//                        // Add heart rate to the corresponding hour
//                        heartRateData[dateKey]?[hourIndex] += sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
//                        // Increment the count for that hour
//                        heartRateCounts[dateKey]?[hourIndex] += 1
//                    }
//                }
//            }
//            // Now calculate averages for each hour and organize into a nested dictionary
//            var averageHeartRateData: [String: [String: Double]] = [:]
//            for (date, rates) in heartRateData {
//                var hourlyAverages: [String: Double] = [:]
//                for (index, totalRate) in rates.enumerated() {
//                    let count = heartRateCounts[date]?[index] ?? 1 // Avoid division by zero
//                    let average = count > 0 ? totalRate / Double(count) : 0.0
//
//                    // Create hour key
//                    let hourKey = String(format: "%02d", index) // Format hour as "HH"
//                    hourlyAverages[hourKey] = average
//                }
//                averageHeartRateData[date] = hourlyAverages
//            }
//
//            // Call the completion with organized data
//            completion(averageHeartRateData)
//        }
//        // Execute the query
//        let healthStore = HKHealthStore()
//        healthStore.execute(query)
//    }
// MARK: - heart rate sample for week
//func fetchHeartRateSamplesForWeek(completion: @escaping([HeartDataModel]) -> Void) {
//    guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
//        return
//    }
//    let calendar = Calendar.current
//    let endDate = Date()
//    let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
//    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
//    let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (_, results, error) in
//        guard error == nil else {
//            print("Error: \(error!.localizedDescription)")
//            return
//        }
//        var heartRateData: [String: [Int: Double]] = [:]
//        var heartRateCounts: [String: [Int: Int]] = [:]
//        if let heartRateSamples = results as? [HKQuantitySample] {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "dd-MM-yyyy"
//            for sample in heartRateSamples {
//                let date = sample.startDate
//                let dateKey = dateFormatter.string(from: date)
//                let hour = calendar.component(.hour, from: date) // Extract hour directly
//                // Initialize dictionaries if they don't exist for the given date
//                if heartRateData[dateKey] == nil {
//                    heartRateData[dateKey] = [:]
//                    heartRateCounts[dateKey] = [:]
//                }
//                let heartRateValue = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
//                // Accumulate the heart rate value and increment the count
//                heartRateData[dateKey]?[hour, default: 0.0] += heartRateValue
//                heartRateCounts[dateKey]?[hour, default: 0] += 1
//            }
//        }
//        // Convert dictionary to array of HeartDataModel
//        var averageHeartRateData: [HeartDataModel] = []
//        for (date, hourlyRates) in heartRateData {
//            var hourlyModels: [HourModel] = []
//            for (hour, totalRate) in hourlyRates {
//                let count = heartRateCounts[date]?[hour] ?? 1
//                let average = totalRate / Double(count)
//                let hourKey = String(format: "%02d", hour) // Format hour as "HH"
//                // Create HourModel and append to hourlyModels
//                let hourModel = HourModel(hourValue: hourKey, heartRateValue: average)
//                hourlyModels.append(hourModel)
//            }
//            // Create HeartDataModel for this date and append it to the result
//            let heartDataModel = HeartDataModel(date: date, hourmodel: hourlyModels)
//            averageHeartRateData.append(heartDataModel)
//        }
//        completion(averageHeartRateData)
//    }
//    let healthStore = HKHealthStore()
//    healthStore.execute(query)
//}

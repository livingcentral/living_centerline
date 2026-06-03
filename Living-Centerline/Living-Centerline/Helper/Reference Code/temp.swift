//
//  temp.swift
//  Living-Centerline
//
//  Created by Developer on 02/10/24.
//

//import Foundation
//import HealthKit
//
//class HealthKitManager {
//    private let healthStore = HKHealthStore()
//    
//    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
//    
//    // Function to fetch heart rate data for a particular date
//    func fetchHeartRateAverage(for date: Date, completion: @escaping ([String: Double]?, Error?) -> Void) {
//        let calendar = Calendar.current
//        var components = calendar.dateComponents([.year, .month, .day], from: date)
//        
//        // Start and end of the day
//        components.hour = 0
//        let startDate = calendar.date(from: components)!
//        components.hour = 23
//        components.minute = 59
//        let endDate = calendar.date(from: components)!
//        
//        // Create the query
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
//        
//        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, results, error) in
//            
//            guard let results = results as? [HKQuantitySample], error == nil else {
//                completion(nil, error)
//                return
//            }
//            
//            // Process the results
//            self.calculateHourlyAverage(from: results, completion: completion)
//        }
//        
//        // Execute the query
//        healthStore.execute(query)
//    }
//    
//    // Function to calculate average heart rate per hour
//    private func calculateHourlyAverage(from samples: [HKQuantitySample], completion: @escaping ([String: Double]?, Error?) -> Void) {
//        var hourlySum: [String: (total: Double, count: Int)] = [:]
//        
//        let calendar = Calendar.current
//        
//        // Aggregate heart rates by hour
//        for sample in samples {
//            let date = sample.startDate
//            let hourString = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
//            
//            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
//            if let _ = hourlySum[hourString] {
//                hourlySum[hourString]!.total += heartRate
//                hourlySum[hourString]!.count += 1
//            } else {
//                hourlySum[hourString] = (total: heartRate, count: 1)
//            }
//        }
//        
//        // Calculate averages
//        var hourlyAverage: [String: Double] = [:]
//        for (hour, sum) in hourlySum {
//            hourlyAverage[hour] = sum.total / Double(sum.count)
//        }
//        
//        // Return results
//        completion(hourlyAverage, nil)
//    }
//}
//import UIKit
//
//class ViewController: UIViewController {
//    
//    private let healthKitManager = HealthKitManager()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let specificDate = Date() // Replace with your desired date
//        healthKitManager.fetchHeartRateAverage(for: specificDate) { (averages, error) in
//            if let error = error {
//                print("Error fetching heart rate data: \(error)")
//                return
//            }
//            if let averages = averages {
//                print("Hourly Averages: \(averages)")
//            }
//        }
//    }
//}

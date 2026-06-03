//
//  retrieveheartsample.swift
//  Living-Centerline
//
//  Created by Developer on 03/10/24.
//

//import Foundation
//homescreenvc
//    // MARK: - retrieve heart sample
//    private func retrieveHeartData(completion: @escaping ([[Date : Int]]) -> Void) {
//        fetchLatestHeartRateSample { samples in
//            guard let samples = samples else {
//                print("heart samples are not available")
//                return
//            }
//            self.heartCount += samples.count
//            for index in 0..<samples.count {
//                print("heart rate for \(samples[index].startDate) is \(samples[index].quantity)")
//                let myDate = samples[index].startDate
//                let heartDataString = "\(samples[index].quantity)".replacingOccurrences(of: " count/min", with: "")
//                guard let heartValue = Int(heartDataString) else { return }
//                let heartArray = [(myDate) : heartValue]
//                self.heartDataArray.append(heartArray)
//                for index in self.heartDataArray {
//                    for keys in index.keys {
//                        if keys == myDate {
//                            print("element present")
//                        } else {
//                            let formatter = DateFormatter()
//                            formatter.dateFormat = "HH:mm"
//                            let myTime = formatter.string(from: myDate)
//                            guard let properTime = myTime.toTime() else { return }
//                            let properDate = keys.getFormattedDate(format: "dd/MM/yyyy")
//                            let timeWise = []
//                            let dateWiseData = [myDate : [myTime : heartValue]]
////                            self.heartDataDateWise.append(hourModel(date: properDate, hourValue: "\(myTime)", heartRateValue: heartValue))
//                        }
//                    }
//            }
//
//            }
//            completion(self.heartDataArray)
//        }
//    }


//private func fetchLatestHeartRateSample(
//    completion: @escaping (_ samples: [HKQuantitySample]?) -> Void) {
//        /// Create sample type for the heart rate
//        guard let sampleType = HKObjectType
//            .quantityType(forIdentifier: .heartRate) else {
//            completion(nil)
//            return
//        }
//        /// Predicate for specifiying start and end dates for the query
//        let predicate = HKQuery
//            .predicateForSamples(
//                withStart: Date.distantPast,
//                end: Date(),
//                options: .strictEndDate)
//        /// Set sorting by date.
//        let sortDescriptor = NSSortDescriptor(
//            key: HKSampleSortIdentifierStartDate,
//            ascending: false)
//        /// Create the query
//        let query = HKSampleQuery(
//            sampleType: sampleType,
//            predicate: predicate,
//            limit: Int(HKObjectQueryNoLimit),
//            sortDescriptors: [sortDescriptor]) { (_, results, error) in
//                
//                guard error == nil else {
//                    print("Error: \(error!.localizedDescription)")
//                    return
//                }
//                completion(results as? [HKQuantitySample])
//            }
//        /// Execute the query in the health store
//        let healthStore = HKHealthStore()
//        healthStore.execute(query)
//    }

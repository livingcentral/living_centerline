//
//  helathDataRetrieval.swift
//  Living-Centerline
//
//  Created by Developer on 03/10/24.
//

//import Foundation
//home screen vc
//    private func fetchHealthData() {
//        let dispatchGroup = DispatchGroup()
//        var fetchedDataCount = 0
//        var fetchedDataTypes: [String] = []
//
//        // Fetch weight data
//        dispatchGroup.enter()
//        fetchWeightData {
//            fetchedDataCount += 1
//            fetchedDataTypes.append("Weight")
//            dispatchGroup.leave()
//        }
//
//        // Fetch height data
//        dispatchGroup.enter()
//        fetchHeightData {
//            fetchedDataCount += 1
//            fetchedDataTypes.append("Height")
//            dispatchGroup.leave()
//        }
//
//        // Fetch body mass index data
//        dispatchGroup.enter()
//        fetchBodyMassIndexData {
//            fetchedDataCount += 1
//            fetchedDataTypes.append("Body Mass Index")
//            dispatchGroup.leave()
//        }
//
//        // Fetch waist circumference data
//        dispatchGroup.enter()
//        fetchWaistCircumferenceData {
//            fetchedDataCount += 1
//            fetchedDataTypes.append("Waist Circumference")
//            dispatchGroup.leave()
//        }
//
//        // Fetch step count data
//        dispatchGroup.enter()
//        fetchStepCountData {
//            fetchedDataCount += 1
//            fetchedDataTypes.append("Step Count")
//            dispatchGroup.leave()
//        }
//
//        // Fetch active energy burned data
//        dispatchGroup.enter()
//        fetchActiveEnergyBurnedData {
//            fetchedDataCount += 1
//            fetchedDataTypes.append("Active Energy Burned")
//            dispatchGroup.leave()
//        }
//
//        // Notify when all data has been fetched
//        dispatchGroup.notify(queue: .main) {
//            print("Total fetched data points: \(fetchedDataCount)")
//            print("Fetched data types: \(fetchedDataTypes.joined(separator: ", "))")
//        }
//    }


//    private func fetchWeightData(completion: @escaping () -> Void) {
//        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
//        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard let results = results as? [HKQuantitySample], error == nil else {
//                print("Error fetching weight data: \(String(describing: error?.localizedDescription))")
//                completion()
//                return
//            }
//
//            for sample in results {
//                let weight = sample.quantity.doubleValue(for: HKUnit.pound())
//                print("Weight: \(weight) lbs")
//            }
//            completion()
//        }
//
//        healthStore.execute(query)
//    }

//    private func fetchHeightData(completion: @escaping () -> Void) {
//        let heightType = HKObjectType.quantityType(forIdentifier: .height)!
//        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard let results = results as? [HKQuantitySample], error == nil else {
//                print("Error fetching height data: \(String(describing: error?.localizedDescription))")
//                completion()
//                return
//            }
//
//            for sample in results {
//                let height = sample.quantity.doubleValue(for: HKUnit.inch())
//                print("Height: \(height) inches")
//            }
//            completion()
//        }
//
//        healthStore.execute(query)
//    }

//    private func fetchBodyMassIndexData(completion: @escaping () -> Void) {
//        let bmiType = HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!
//        let query = HKSampleQuery(sampleType: bmiType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard let results = results as? [HKQuantitySample], error == nil else {
//                print("Error fetching body mass index data: \(String(describing: error?.localizedDescription))")
//                completion()
//                return
//            }
//
//            for sample in results {
//                let bmi = sample.quantity.doubleValue(for: HKUnit.count())
//                print("Body Mass Index: \(bmi)")
//            }
//            completion()
//        }
//
//        healthStore.execute(query)
//    }

//    private func fetchWaistCircumferenceData(completion: @escaping () -> Void) {
//        let waistType = HKObjectType.quantityType(forIdentifier: .waistCircumference)!
//        let query = HKSampleQuery(sampleType: waistType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard let results = results as? [HKQuantitySample], error == nil else {
//                print("Error fetching waist circumference data: \(String(describing: error?.localizedDescription))")
//                completion()
//                return
//            }
//
//            for sample in results {
//                let waistCircumference = sample.quantity.doubleValue(for: HKUnit.inch())
//                print("Waist Circumference: \(waistCircumference) inches")
//            }
//            completion()
//        }
//
//        healthStore.execute(query)
//    }

//    private func fetchStepCountData(completion: @escaping () -> Void) {
//        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
//        let query = HKSampleQuery(sampleType: stepCountType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard let results = results as? [HKQuantitySample], error == nil else {
//                print("Error fetching step count data: \(String(describing: error?.localizedDescription))")
//                completion()
//                return
//            }
//
//            for sample in results {
//                let stepCount = sample.quantity.doubleValue(for: HKUnit.count())
//                //print("Step Count: \(stepCount) steps")
//            }
//            completion()
//        }
//
//        healthStore.execute(query)
//    }

//    private func fetchActiveEnergyBurnedData(completion: @escaping () -> Void) {
//        let energyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
//        let query = HKSampleQuery(sampleType: energyBurnedType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
//            guard let results = results as? [HKQuantitySample], error == nil else {
//                print("Error fetching active energy burned data: \(String(describing: error?.localizedDescription))")
//                completion()
//                return
//            }
//
//            for sample in results {
//                let energyBurned = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
//                print("Active Energy Burned: \(energyBurned) kcal")
//            }
//            completion()
//        }
//
//        healthStore.execute(query)
//    }

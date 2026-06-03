//
//  HealthManager.swift
//  Living-Centerline
//
//  Created by Developer on 02/10/24.
//

import Foundation
import HealthKit

enum HealthKitError: Error {
    case dataTypesUnavailable
    case missingNumberOfDays
    case invalidNumberOfDays
    case incompleteData
    case authorizationDenied
}

class HealthKitManager {
    
    let healthStore = HKHealthStore()
    // Managers
    let stepsManager = StepsManager()
    let sleepManager = SleepManager()
    let hrvManager = HRVManager()
    let restingHeartManager = RestingHeartManager()
    let activeEnergyManager = ActiveEnergyManager()
    let restingEnergyManager = RestingEnergyManager()
    // Models
    var stepsDataArray: [StepDataModel]?
    var sleepDataArray: [SleepPhaseModel]?
    var hrvDataArray: [HRVDataModel]?
    var restingHeartDataArray: [RestingHeartDataModel]?
    var activeEnergyDataArray: [ActiveEnergyModel]?
    var restingEnergyDataArray: [RestingEnergyModel]?
    var healthData = [HealthDateModel]()
    // Dispatch group
    let dispatchGroup = DispatchGroup()
    // let dispatchGroup2 = DispatchGroup()
    // User Default
    let defaults = UserDefaults.standard
    
    // MARK: - HealthKit authorisation method
    func requestHealthKitAuthorization(completion: @escaping (Result<[HealthDateModel], Error>) -> Void) {
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
              let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let caloriesBurn = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingEnergy = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned),
              let restingHeart = HKSampleType.quantityType(forIdentifier: .restingHeartRate),
              let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(.failure(HealthKitError.dataTypesUnavailable))
            return
        }
        
        // Define the health data types to read
        let healthKitTypesToRead: Set<HKObjectType> = [
            stepCount,
            hrv,
            caloriesBurn,
            restingEnergy,
            restingHeart,
            sleepAnalysis
        ]
        
        dispatchGroup.enter()
        print("HealthKit popup presented once.")
        LogManager.shared.addLog(data: "#HealthKitManager health kit popup presented once.")
        sendLogData()
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypesToRead) { [weak self] success, error in
            guard let self = self else { return }
            self.dispatchGroup.leave()
            
            if let error = error {
                LogManager.shared.addLog(data: "#HealthKitManager \(error)")
                sendLogData()
                completion(.failure(error))
                return
            }
            
            if success {
                healthData.removeAll()
                LogManager.shared.addLog(data: "#HealthKitManager health data success")
                guard var numberOfDays = defaults.object(forKey: "numberOfHealthData") as? Int else {
                    completion(.failure(HealthKitError.missingNumberOfDays))
                    LogManager.shared.addLog(data: "#HealthKitManager \(HealthKitError.missingNumberOfDays)")
                    sendLogData()
                    return
                }
                numberOfDays += 1
                let days = numberOfDays
                sendLogData()
                if numberOfDays > 1 {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Task {
                            await self.fetchSleepData(numberOfDays: days)
                            await self.fetchStepsData(numberOfDays: days)
                            await self.fetchHRVData(numberOfDays: days)
                            await self.fetchRestingHeartData(numberOfDays: days)
                            await self.fetchActiveEnergyBurnedData(numberOfDays: days)
                            await self.fetchRestingEnergyData(numberOfDays: days)
                        }
//                        self.fetchRestingHeartData(numberOfDays: numberOfDays)
//                        self.fetchActiveEnergyBurnedData(numberOfDays: numberOfDays)
//                        self.fetchRestingEnergyData(numberOfDays: numberOfDays)
//                        self.fetchHRVData(numberOfDays: numberOfDays)
                    }
                } else {
                    print("Fetch \(numberOfDays) records failed")
                    LogManager.shared.addLog(data: "#HealthKitManager \(HealthKitError.invalidNumberOfDays)")
                    sendLogData()
                    completion(.failure(HealthKitError.invalidNumberOfDays))
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
                        guard let self else { return }
                        if stepsDataArray != nil ||
                            restingHeartDataArray != nil ||
                            sleepDataArray != nil ||
                            activeEnergyDataArray != nil ||
                            hrvDataArray != nil ||
                            restingEnergyDataArray != nil {
                            
                            guard let numberOfDays = defaults.object(forKey: "numberOfHealthData") as? Int else {
                                LogManager.shared.addLog(data: "#HealthKitManager \(HealthKitError.missingNumberOfDays)")
                                sendLogData()
                                completion(.failure(HealthKitError.missingNumberOfDays))
                                return
                            }
                            
                            print("All health data retrieval done.")
                            LogManager.shared.addLog(data: "#HealthKitManager All health data retrieval done.")
                            sendLogData()
                            self.mergeAllHealthData(numberOfDays: numberOfDays) { [ weak self] healthData in
                                guard let self else { return }
                                self.healthData = healthData
                                print("steps data count \(stepsDataArray?.count ?? 0)")
                                print("sleep data count \(sleepDataArray?.count ?? 0)")
                                print("restingHeart data count \(restingHeartDataArray?.count ?? 0)")
                                print("active energy data count \(activeEnergyDataArray?.count ?? 0)")
                                print("hrv data count \(hrvDataArray?.count ?? 0)")
                                print("resting energy data count \(restingEnergyDataArray?.count ?? 0)")
                                LogManager.shared.addLog(data: "#HealthKitManager \(healthData)")
                                sendLogData()
                                completion(.success(healthData))
                            }
                        } else {
                            print("Health data retrieval has an issue.")
                            LogManager.shared.addLog(data: "#HealthKitManager \(HealthKitError.incompleteData)")
                            sendLogData()
                            completion(.failure(HealthKitError.incompleteData))
                        }
                    }
                }
            } else {
                print("Couldn't get permission to access health data.")
                LogManager.shared.addLog(data: "#HealthKitManager \(HealthKitError.authorizationDenied)")
                sendLogData()
                completion(.failure(HealthKitError.authorizationDenied))
            }
        }
    }
    
    func fetchTodayHealthData(completion: @escaping (Result<HealthDateModel, Error>) -> Void) {
        // Ensure the required data types are available
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
              let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let caloriesBurn = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingEnergy = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned),
              let restingHeart = HKSampleType.quantityType(forIdentifier: .restingHeartRate),
              let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(.failure(HealthKitError.dataTypesUnavailable))
            return
        }
        
        let healthStore = HKHealthStore()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictEndDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        
        var healthData = HealthDateModel(date: startOfDay)
        
        let dispatchGroup = DispatchGroup()
        
        // Fetch Step Count
        dispatchGroup.enter()
        let stepQuery = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching steps: \(error.localizedDescription)")
                return
            }
            if let result = result, let sum = result.sumQuantity() {
                let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                healthData.totalSteps = TotalSteps(dateWithTimeStamp: startOfDay, totalSteps: stepCount)
            }
        }
        healthStore.execute(stepQuery)
        // Fetch HRV
        dispatchGroup.enter()
        let hrvQuery = HKSampleQuery(sampleType: hrv, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, results, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching HRV: \(error.localizedDescription)")
                return
            }
            if let sample = results?.first as? HKQuantitySample {
                let hrvValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                healthData.hrv = HRVValue(hrvValue: hrvValue, dateWithTimeStamp: sample.endDate)
            }
        }
        healthStore.execute(hrvQuery)
        
        // Fetch Active Energy Burned
        dispatchGroup.enter()
        let activeEnergyQuery = HKStatisticsQuery(quantityType: caloriesBurn, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching active energy: \(error.localizedDescription)")
                return
            }
            if let result = result, let sum = result.sumQuantity() {
                let activeCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                healthData.activeCalorieBurned = ActiveEnergyValue(activeEnergy: activeCalories, dateWithTimeStamp: startOfDay)
            }
        }
        healthStore.execute(activeEnergyQuery)
        
        // Fetch Resting Energy Burned
        dispatchGroup.enter()
        let restingEnergyQuery = HKStatisticsQuery(quantityType: restingEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching resting energy: \(error.localizedDescription)")
                return
            }
            if let result = result, let sum = result.sumQuantity() {
                let restingEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
                healthData.restingEnergy = RestingEnergyValue(restingEnergy: restingEnergy, dateWithTimeStamp: startOfDay)
            }
        }
        healthStore.execute(restingEnergyQuery)
        
        // Fetch Resting Heart Rate
        dispatchGroup.enter()
        let restingHeartQuery = HKSampleQuery(sampleType: restingHeart, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, results, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching resting heart rate: \(error.localizedDescription)")
                return
            }
            if let sample = results?.first as? HKQuantitySample {
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                healthData.restingHeartRate = RestingHeartValue(heartValue: heartRate, dateWithTimeStamp: sample.endDate)
            }
        }
        healthStore.execute(restingHeartQuery)
        
        // Fetch Sleep Analysis
        dispatchGroup.enter()
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysis, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            defer { dispatchGroup.leave() }
            if let error = error {
                print("Error fetching sleep data: \(error.localizedDescription)")
                return
            }
            if let sleepSamples = results as? [HKCategorySample] {
                var totalSleepDuration: TimeInterval = 0
                
                for sample in sleepSamples {
                    let sleepDuration = sample.endDate.timeIntervalSince(sample.startDate)
                    totalSleepDuration += sleepDuration
                    if #available(iOS 16.0, *) {
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            healthData.remSleep = RemSleep(dateWithTimeStamp: sample.startDate, remSleep: sleepDuration)
                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                            healthData.coreSleep = CoreSleep(dateWithTimeStamp: sample.startDate, coreSleep: sleepDuration)
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            healthData.deepSleep = DeepSleep(dateWithTimeStamp: sample.startDate, deepSleep: sleepDuration)
                        case HKCategoryValueSleepAnalysis.awake.rawValue:
                            healthData.awakeTime = AwakeTime(dateWithTimeStamp: sample.startDate, awakeTime: sleepDuration)
                        default:
                            continue
                        }
                    } else {
                        // Fallback on earlier versions
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            healthData.totalSleep = TotalSleep(dateWithTimeStamp: sample.startDate, totalSleep: totalSleepDuration)
                        }
                    }
                    if #available(iOS 16.0, *) {
                        healthData.totalSleep = TotalSleep(dateWithTimeStamp: startOfDay, totalSleep: totalSleepDuration)
                    }
                }
            }
        }
        healthStore.execute(sleepQuery)
        
        // Notify when all data is fetched
        dispatchGroup.notify(queue: .main) {
            completion(.success(healthData))
        }
    }
   
    private func fetchStepsData(numberOfDays: Int) async {
        dispatchGroup.enter()
        LogManager.shared.addLog(data: "#HealthKitManager fetch step data executing")
        sendLogData()
        func fetchWithRetry(retries: Int = 3) {
            Task {
                do {
                    let stepsData = try await stepsManager.retrieveStepsForWeek(numberOfDays: -(numberOfDays - 1))
                    LogManager.shared.addLog(data: "#HealthKitManager \(stepsData)")
                    stepsDataArray = stepsData
                    
                    guard let stepsDataArray = stepsDataArray else {
                        print("No data found in steps data")
                        LogManager.shared.addLog(data: "#HealthKitManager No data found in steps data")
                        sendLogData()
                        dispatchGroup.leave()
                        return
                    }
                    
                    if stepsDataArray.count == abs(numberOfDays - 1) {
                        // Successfully retrieved sufficient data
                        LogManager.shared.addLog(data: "#HealthKitManager Successfully retrieved sufficient data")
                        sendLogData()
                        dispatchGroup.leave()
                    } else if retries > 0 {
                        LogManager.shared.addLog(data: "#HealthKitManager Insufficient steps data fetched: \(stepsDataArray.count). Retrying... Remaining retries: \(retries)")
                        print("Insufficient steps data fetched: \(stepsDataArray.count). Retrying... Remaining retries: \(retries)")
                        fetchWithRetry(retries: retries - 1)
                    } else {
                        LogManager.shared.addLog(data: "#HealthKitManager Insufficient steps data after retries. Count: \(stepsDataArray.count)")
                        print("Insufficient steps data after retries. Count: \(stepsDataArray.count)")
                        sendLogData()
                        dispatchGroup.leave()
                    }
                } catch {
                    LogManager.shared.addLog(data: "#HealthKitManager Error retrieving steps: \(error.localizedDescription)")
                    print("Error retrieving steps: \(error.localizedDescription)")
                    sendLogData()
                    dispatchGroup.leave()
                }
            }
        }
        // Start the fetch with retries
        LogManager.shared.addLog(data: "#HealthKitManager fetch with retries")
        sendLogData()
        fetchWithRetry()
    }
    // working 5 feb
//    private func fetchStepsData(numberOfDays: Int) {
//        dispatchGroup.enter()
//        func fetchWithRetry(retries: Int = 3) {
//            stepsManager.retrieveStepsForWeek(numberOfDays: -(numberOfDays-1)) { [weak self] stepsData,error  in
//                guard let self else {
//                    return
//                }
//                // Handle the response
//                if let error = error {
//                    dispatchGroup.leave()
//                    // Log the error if needed and leave the dispatch group
//                    print("Error retrieving steps: \(error.localizedDescription)")
//                    return
//                }
//                stepsDataArray = stepsData
//                guard let stepsDataArray = stepsDataArray else {
//                    print("no data found in steps data")
//                    return
//                }
//                if stepsDataArray.count == abs(numberOfDays - 1) {
//                    // Successfully retrieved sufficient data
//                    // print("Active energy data are fetched: \(activeEnergyData.count)")
//                    dispatchGroup.leave()
//                } else if retries > 0 {
//                    print("Insufficient steps data fetched: \(stepsDataArray.count). Retrying... Remaining retries: \(retries)")
//                    fetchWithRetry(retries: retries - 1)
//                } else {
//                    print("Insufficient steps data after retries. Count: \(stepsDataArray.count)")
//                    dispatchGroup.leave()
//                }
//            }
//        }
//        // Start the fetch with retries
//        fetchWithRetry()
//    }
    
    // MARK: - fetch sleep data
    private func fetchSleepData(numberOfDays: Int) async {
        //        sleepManager.retrieveSleepPhases(for: "12/10/2024") { remSleep, coreSleep, deepSleep in
        //            print("REM Sleep: \(remSleep / 3600) hours")  // Convert seconds to hours
        //            print("Core Sleep: \(coreSleep / 3600) hours")
        //            print("Deep Sleep: \(deepSleep / 3600) hours")
        //        }
        // Fetch sleep data
        LogManager.shared.addLog(data: "#HealthKitManager fetch sleep data called")
        sendLogData()
        dispatchGroup.enter()
        //        sleepManager.retrieveSleepDataForWeek(numberOfDays: -numberOfDays) { [weak self] sleepData in
        //            guard let self else { return }
        //            self.sleepDataArray = sleepData
        //
        //        }
        let sleepData = await sleepManager.retrieveSleepDataForWeek(numberOfDays: -numberOfDays)
        LogManager.shared.addLog(data: "#HealthKitManager fetch sleep data \(sleepData)")
        sendLogData()
        self.sleepDataArray = sleepData
        
        //            for sleep in sleepData {
        //                //print("Date: \(sleep.date), core sleep \(sleep.coreSleep), rem sleep \(sleep.remSleep), deep sleep \(sleep.deepSleep), sleep duration \(sleep.sleepDuration)")
        //            }
        // print("sleep data are fetched \(sleepDataArray?.count)")
        
        dispatchGroup.leave()
    }
    // MARK: - fetch HRV data
    private func fetchHRVData(numberOfDays: Int) async {
        dispatchGroup.enter()
        LogManager.shared.addLog(data: "#HealthKitManager fetch HRV data called")
        sendLogData()
        // Function to fetch HRV data with retry logic
        func fetchWithRetry(retries: Int = 3) {
            Task {
                do {
                    let hrvDataArray = await hrvManager.fetchHRVDataForWeek(numberOfDays: -numberOfDays)
                    LogManager.shared.addLog(data: "#HealthKitManager hrv data array executing")
                    sendLogData()
                    await MainActor.run {
                        self.hrvDataArray = hrvDataArray
                        LogManager.shared.addLog(data: "#HealthKitManager \(hrvDataArray)")
                    }
                    
                    if hrvDataArray.count >= abs(numberOfDays) {
                        LogManager.shared.addLog(data: "#HealthKitManager hrv data matches")
                        sendLogData()
                        dispatchGroup.leave()
                    } else if retries > 0 {
                        LogManager.shared.addLog(data: "#HealthKitManager Insufficient HRV data fetched: \(hrvDataArray.count). Retrying... Remaining retries: \(retries)")
                        print("Insufficient HRV data fetched: \(hrvDataArray.count). Retrying... Remaining retries: \(retries)")
                        fetchWithRetry(retries: retries - 1)
                    } else {
                        LogManager.shared.addLog(data: "#HealthKitManager Insufficient HRV data after retries. Count: \(hrvDataArray.count)")
                        print("Insufficient HRV data after retries. Count: \(hrvDataArray.count)")
                        sendLogData()
                        dispatchGroup.leave()
                    }
                } catch {
                    LogManager.shared.addLog(data: "#HealthKitManager Error fetching HRV data: \(error.localizedDescription)")
                    sendLogData()
                    print("Error fetching HRV data: \(error.localizedDescription)")
                    if retries > 0 {
                        LogManager.shared.addLog(data: "#HealthKitManager Retrying due to error... Remaining retries: \(retries)")
                        print("Retrying due to error... Remaining retries: \(retries)")
                        fetchWithRetry(retries: retries - 1)
                    } else {
                        LogManager.shared.addLog(data: "#HealthKitManager HRV dispatch group leave")
                        sendLogData()
                        dispatchGroup.leave()
                    }
                }
            }
        }
        // Start the fetch with retries
        LogManager.shared.addLog(data: "#HealthKitManager HRV fetch with retries")
        sendLogData()
        fetchWithRetry()
    }
    // working 5 feb
//    private func fetchHRVData(numberOfDays: Int) {
//        dispatchGroup.enter()
//        
//        // Function to fetch HRV data with retry logic
//        func fetchWithRetry(retries: Int = 3) {
//            hrvManager.fetchHRVDataForWeek(numberOfDays: -numberOfDays) { [weak self] hrvDataArray in
//                guard let self else {
//                    return
//                }
//                
//                // Assign fetched data to the local array
//                self.hrvDataArray = hrvDataArray
//                
//                if hrvDataArray.count >= abs(numberOfDays) {
//                    // Successfully retrieved sufficient data
//                    // print("HRV data are fetched: \(hrvDataArray.count)")
//                    dispatchGroup.leave()
//                } else if retries > 0 {
//                    print("Insufficient HRV data fetched: \(hrvDataArray.count). Retrying... Remaining retries: \(retries)")
//                    fetchWithRetry(retries: retries - 1)
//                } else {
//                    print("Insufficient HRV data after retries. Count: \(hrvDataArray.count)")
//                    dispatchGroup.leave()
//                }
//            }
//        }
//        
//        // Start the fetch with retries
//        fetchWithRetry()
//    }
    
    // MARK: - fetch resting heart data
    private func fetchRestingHeartData(numberOfDays: Int) async {
        let maxRetries = 3
        var currentRetry = 0

        dispatchGroup.enter()
        LogManager.shared.addLog(data: "#HealthKitManager resting heart fetch started#")
        while currentRetry < maxRetries {
            do {
                // Fetch resting heart rate data asynchronously
                let restingHeartData = await restingHeartManager.fetchRestingHeartRate(numberOfDays: -numberOfDays)
                LogManager.shared.addLog(data: "#HealthKitManager fetch resting heart data asynchronously")
                sendLogData()
                // Safely unwrap and map the fetched data
                self.restingHeartDataArray = restingHeartData.map { model in
                    RestingHeartDataModel(
                        date: model.date,
                        heartRate: model.heartRate,
                        dateWithTimeStamp: model.dateWithTimeStamp,
                        samples: model.samples
                    )
                }
                LogManager.shared.addLog(data: "#HealthKitManager fetch resting heart restingHeartDataArray")
                // Check if the data meets the required count
                if let restingHeartDataArray = self.restingHeartDataArray, restingHeartDataArray.count >= abs(numberOfDays) {
                    LogManager.shared.addLog(data: "#HealthKitManager Check if the data meets the required count")
                    sendLogData()
                    // Print the successful data fetch
                    for i in 0..<restingHeartDataArray.count {
                       // let date = restingHeartDataArray[i].date
                      //  let avgHeartRate = restingHeartDataArray[i].heartRate.heartValue
                        // print("Date: \(date), Avg Resting Heart Rate: \(avgHeartRate) BPM")
                    }
                    break // Exit loop on success
                } else {
                    currentRetry += 1
                    LogManager.shared.addLog(data: "#HealthKitManager Resting heart rate retry \(currentRetry) - Fetched \(self.restingHeartDataArray?.count ?? 0) entries, expected \(abs(numberOfDays)).")
                    print("Resting heart rate retry \(currentRetry) - Fetched \(self.restingHeartDataArray?.count ?? 0) entries, expected \(abs(numberOfDays)).")

                    if currentRetry >= maxRetries {
                        LogManager.shared.addLog(data: "#HealthKitManager Max retries reached. Final data count: \(self.restingHeartDataArray?.count ?? 0).")
                        print("Max retries reached. Final data count: \(self.restingHeartDataArray?.count ?? 0).")
                    }
                    sendLogData()
                }
            } catch {
                LogManager.shared.addLog(data: "#HealthKitManager Error fetching resting heart rate data: \(error.localizedDescription)")
                sendLogData()
                print("Error fetching resting heart rate data: \(error.localizedDescription)")
                break // Exit loop on failure
            }
        }
        dispatchGroup.leave()
    }

    // working 5 feb
//    private func fetchRestingHeartData(numberOfDays: Int) {
//        let maxRetries = 3
//        var currentRetry = 0
//        
//        func fetchAndValidateRestingHeartData() {
//            dispatchGroup.enter()
//            restingHeartManager.fetchRestingHeartRate(numberOfDays: -numberOfDays) { [weak self] restingHeartData in
//                guard let self = self else {
//                    self?.dispatchGroup.leave()
//                    return
//                }
//                
//                // Safely unwrap and map the fetched data
//                self.restingHeartDataArray = restingHeartData.map { model in
//                    RestingHeartDataModel(
//                        date: model.date,
//                        heartRate: model.heartRate,
//                        dateWithTimeStamp: model.dateWithTimeStamp,
//                        samples: model.samples
//                    )
//                }
//                
//                // Check if the data meets the required count
//                if let restingHeartDataArray = self.restingHeartDataArray, restingHeartDataArray.count >= abs(numberOfDays) {
//                    //   print("Successfully fetched resting heart data with \(restingHeartDataArray.count) entries.")
//                    for i in 0..<restingHeartDataArray.count {
//                        let date = restingHeartDataArray[i].date
//                        let avgHeartRate = restingHeartDataArray[i].heartRate.heartValue
//                        // print("Date: \(date), Avg Resting Heart Rate: \(avgHeartRate) BPM")
//                    }
//                    self.dispatchGroup.leave()
//                } else {
//                    currentRetry += 1
//                    print("resting heart Retry \(currentRetry) - Fetched \(self.restingHeartDataArray?.count ?? 0) entries, expected \(abs(numberOfDays)).")
//                    
//                    if currentRetry < maxRetries {
//                        self.dispatchGroup.leave() // Leave the previous attempt's dispatch group
//                        fetchAndValidateRestingHeartData() // Retry
//                    } else {
//                        print("Max retries reached. Final data count: \(self.restingHeartDataArray?.count ?? 0).")
//                        self.dispatchGroup.leave()
//                    }
//                }
//            }
//        }
//        
//        fetchAndValidateRestingHeartData()
//    }
    
    // MARK: - fetch active energy burned
    private func fetchActiveEnergyBurnedData(numberOfDays: Int) async {
        dispatchGroup.enter()
        LogManager.shared.addLog(data: "#HealthKitManager fetch active energy burned data started")
        sendLogData()
        // Function to fetch active energy burned data with retry logic
        func fetchWithRetry(retries: Int = 3) async {
            do {
                // Fetch active energy data asynchronously
                let activeEnergyData = await activeEnergyManager.fetchActiveEnergyBurned(numberOfDays: -numberOfDays)
                LogManager.shared.addLog(data: "#HealthKitManager Fetch active energy data asynchronously")

                // Assign fetched data to the local array
                self.activeEnergyDataArray = activeEnergyData
                LogManager.shared.addLog(data: "#HealthKitManager Assign fetched data to the local array")
                sendLogData()
                if activeEnergyData.count >= abs(numberOfDays) {
                    // Successfully retrieved sufficient data
                    LogManager.shared.addLog(data: "#HealthKitManager Successfully retrieved sufficient data")
                    sendLogData()
                    dispatchGroup.leave()
                } else if retries > 0 {
                    LogManager.shared.addLog(data: "#HealthKitManager Insufficient active energy data fetched: \(activeEnergyData.count). Retrying... Remaining retries: \(retries)")
                    print("Insufficient active energy data fetched: \(activeEnergyData.count). Retrying... Remaining retries: \(retries)")
                    await fetchWithRetry(retries: retries - 1) // Retry with decremented retry count
                } else {
                    LogManager.shared.addLog(data: "#HealthKitManager Insufficient active energy data after retries. Count: \(activeEnergyData.count)")
                    print("Insufficient active energy data after retries. Count: \(activeEnergyData.count)")
                    sendLogData()
                    dispatchGroup.leave()
                }
            } catch {
                LogManager.shared.addLog(data: "#HealthKitManager Error fetching active energy data: \(error.localizedDescription)")
                sendLogData()
                print("Error fetching active energy data: \(error.localizedDescription)")
                dispatchGroup.leave()
            }
        }

        // Start the fetch with retries using async/await
        Task {
            LogManager.shared.addLog(data: "#HealthKitManager Start the fetch with retries using async/await")
            sendLogData()
            await fetchWithRetry()
        }
    }
    // working 5 feb
//    private func fetchActiveEnergyBurnedData(numberOfDays: Int) {
//        dispatchGroup.enter()
//        
//        // Function to fetch active energy burned data with retry logic
//        func fetchWithRetry(retries: Int = 3) {
//            activeEnergyManager.fetchActiveEnergyBurned(numberOfDays: -numberOfDays) { [weak self] activeEnergyData in
//                guard let self else {
//                    return
//                }
//                
//                // Assign fetched data to the local array
//                self.activeEnergyDataArray = activeEnergyData
//                
//                if activeEnergyData.count >= abs(numberOfDays) {
//                    // Successfully retrieved sufficient data
//                    // print("Active energy data are fetched: \(activeEnergyData.count)")
//                    dispatchGroup.leave()
//                } else if retries > 0 {
//                    print("Insufficient active energy data fetched: \(activeEnergyData.count). Retrying... Remaining retries: \(retries)")
//                    fetchWithRetry(retries: retries - 1)
//                } else {
//                    print("Insufficient active energy data after retries. Count: \(activeEnergyData.count)")
//                    dispatchGroup.leave()
//                }
//            }
//        }
//        
//        // Start the fetch with retries
//        fetchWithRetry()
//    }
    
    private func fetchRestingEnergyData(numberOfDays: Int) async {
        dispatchGroup.enter()
        LogManager.shared.addLog(data: "#HealthKitManager fetch resting energy data started")
        sendLogData()
        // Function to fetch resting energy data with retry logic
        func fetchWithRetry(retries: Int = 3) async {
            do {
                // Fetch resting energy data asynchronously
                let restingEnergyData = await restingEnergyManager.fetchRestingEnergyBurned(numberOfDays: -numberOfDays)
                LogManager.shared.addLog(data: "#HealthKitManager Fetch resting energy data asynchronously")
                // Assign fetched data to the local array
                self.restingEnergyDataArray = restingEnergyData
                LogManager.shared.addLog(data: "#HealthKitManager Assign fetched data to the local array")
                sendLogData()
                if restingEnergyData.count >= abs(numberOfDays) {
                    // Successfully retrieved sufficient data
                    LogManager.shared.addLog(data: "#HealthKitManager Successfully retrieved sufficient data")
                    sendLogData()
                    dispatchGroup.leave()
                } else if retries > 0 {
                    LogManager.shared.addLog(data: "#HealthKitManager Insufficient resting energy data fetched: \(restingEnergyData.count). Retrying... Remaining retries: \(retries)")
                    print("Insufficient resting energy data fetched: \(restingEnergyData.count). Retrying... Remaining retries: \(retries)")
                    await fetchWithRetry(retries: retries - 1) // Retry with decremented retry count
                } else {
                    LogManager.shared.addLog(data: "#HealthKitManager Insufficient resting energy data after retries. Count: \(restingEnergyData.count)")
                    sendLogData()
                    print("Insufficient resting energy data after retries. Count: \(restingEnergyData.count)")
                    dispatchGroup.leave()
                }
            } catch {
                LogManager.shared.addLog(data: "#HealthKitManager Error fetching resting energy data: \(error.localizedDescription)")
                sendLogData()
                print("Error fetching resting energy data: \(error.localizedDescription)")
                dispatchGroup.leave()
            }
        }

        // Start the fetch with retries using async/await
        Task {
            LogManager.shared.addLog(data: "#HealthKitManager Start the fetch with retries using async/await")
            sendLogData()
            await fetchWithRetry()
        }
    }
        // working 5 feb
//    private func fetchRestingEnergyData(numberOfDays: Int) {
//        dispatchGroup.enter()
//        
//        // Function to fetch resting energy data with retry logic
//        func fetchWithRetry(retries: Int = 3) {
//            restingEnergyManager.fetchRestingEnergyBurned(numberOfDays: -numberOfDays) { [weak self] restingEnergyData in
//                guard let self else {
//                    return
//                }
//                
//                // Assign fetched data to the local array
//                self.restingEnergyDataArray = restingEnergyData
//                
//                if restingEnergyData.count >= abs(numberOfDays) {
//                    // Successfully retrieved sufficient data
//                    // print("Resting energy data are fetched: \(restingEnergyData.count)")
//                    dispatchGroup.leave()
//                } else if retries > 0 {
//                    print("Insufficient resting energy data fetched: \(restingEnergyData.count). Retrying... Remaining retries: \(retries)")
//                    fetchWithRetry(retries: retries - 1)
//                } else {
//                    print("Insufficient resting energy data after retries. Count: \(restingEnergyData.count)")
//                    dispatchGroup.leave()
//                }
//            }
//        }
//        
//        // Start the fetch with retries
//        fetchWithRetry()
//    }
   
    // MARK: merge all health data
    private func mergeAllHealthData(numberOfDays: Int, completion: @escaping ([HealthDateModel]) -> Void) {
        LogManager.shared.addLog(data: "#HealthKitManager merge all health data")
        // Get the past 7 days, including today
        let calendar = Calendar.current
        let today = Date()
        var last14Days: [Date] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        sendLogData()
        // Generate the list of dates for the past 14 days, including today
        for i in 1...numberOfDays { // Start from 1 to exclude today
            // print("days \(i)")
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: today) {
                // let dateString = dateFormatter.string(from: pastDate)
                last14Days.append(pastDate)
            }
        }
        // Now loop through the last 7 days
        for date in last14Days {
            LogManager.shared.addLog(data: "#HealthKitManager Now loop through the last 7 days")
            sendLogData()
            // Find step data for the current date
            let currentDate = dateFormatter.string(from: date)
            
            let stepsEntry = stepsDataArray?.first { $0.date == currentDate }
            let mySteps = stepsEntry?.totalSteps
            let emptySteps = TotalSteps(dateWithTimeStamp: Date(), totalSteps: 0)
            let totalSteps = (stepsEntry == nil) ? nil : mySteps ?? emptySteps
            // Find heart rate data for the current date
            //            let heartEntry = heartDataArray.first { $0.date == date }
            //            let hourModel = (heartEntry == nil) ? nil : hourData  ?? []
            // Find sleep data for the current date
            
            let sleepEntry = sleepDataArray?.first { $0.date == currentDate }
            
            let emptyTotalSleep = TotalSleep(dateWithTimeStamp: Date(), totalSleep: 0.0)
            let myTotalSleep = sleepEntry?.totalSleep
            let totalSleep = (sleepEntry == nil) ? nil : myTotalSleep
            
            let myRemSleep = sleepEntry?.remSleep
            let emptyRemSleep = RemSleep(dateWithTimeStamp: Date(), remSleep: 0.0)
            let remSleep = (sleepEntry == nil) ? nil : myRemSleep
            
            let emptyCoreSleep = CoreSleep(dateWithTimeStamp: Date(), coreSleep: 0.0)
            let myCoreSleep = sleepEntry?.coreSleep
            let coreSleep = (sleepEntry == nil) ? nil : myCoreSleep
            
            let emptyDeepSleep = DeepSleep(dateWithTimeStamp: Date(), deepSleep: 0.0)
            let myDeepSleep = sleepEntry?.deepSleep
            let deepSleep = (sleepEntry == nil) ? nil : myDeepSleep
            
            let emptyAwakeTime = AwakeTime(dateWithTimeStamp: Date(), awakeTime: 0.0)
            let myAwakeTime = sleepEntry?.awakeTime
            let awakeTime = (sleepEntry == nil) ? nil : myAwakeTime
            
            let activeEnergyEntry = activeEnergyDataArray?.first { $0.date == currentDate }
            let myActiveEnergy = activeEnergyEntry?.activeEnergy
            let activeCalorieBurned = (activeEnergyEntry == nil) ? nil : myActiveEnergy
            
            let restingEnergyEntry = restingEnergyDataArray?.first { $0.date == currentDate }
            let myRestingEnergy = restingEnergyEntry?.restingEnergy
            let restingEnergy = (restingEnergyEntry == nil) ? nil : myRestingEnergy
            
            let restingEntry = restingHeartDataArray?.first { $0.date == currentDate }
            let myRestingHeart = restingEntry?.heartRate
         //   let emptyRestingHeart = RestingHeartValue(heartValue: 0.0, dateWithTimeStamp: Date())
            let restingHeartRate = (myRestingHeart == nil) ? nil : myRestingHeart 
            
            let hrvEntry = hrvDataArray?.first { $0.date == currentDate }
            let emptyHRV = HRVValue(hrvValue: 0.0, dateWithTimeStamp: Date())
            let myHrv = hrvEntry?.hrvValue
            let hrv = (hrvEntry == nil) ? nil : myHrv
            
            // Create the HealthDateModel and append it to healthData
            healthData.append(HealthDateModel(date: date, totalSteps: totalSteps, totalSleep: totalSleep, remSleep: remSleep, coreSleep: coreSleep, deepSleep: deepSleep, awakeTime: awakeTime, activeCalorieBurned: activeCalorieBurned,restingEnergy: restingEnergy , restingHeartRate: restingHeartRate, hrv: hrv))
            
            //print("Final healthData array: \(healthData)")
        }
        healthData.sort { $0.date < $1.date }
        LogManager.shared.addLog(data: "#HealthKitManager \(healthData)")
        sendLogData()
        completion(healthData)
    }
    //    private func mergeAllHealthData() {
    //        // Get the past 7 days, including today
    //        let calendar = Calendar.current
    //        let today = Date()
    //        var last14Days: [String] = []
    //        let dateFormatter = DateFormatter()
    //        dateFormatter.dateFormat = "dd-MM-yyyy"
    //
    //        // Generate the list of dates for the past 14 days, including today
    //        for i in 0..<14 {
    //            if let pastDate = calendar.date(byAdding: .day, value: -i, to: today) {
    //                let dateString = dateFormatter.string(from: pastDate)
    //                last14Days.append(dateString)
    //            }
    //        }
    //        // Now loop through the last 7 days
    //        for date in last14Days {
    //            //print("Processing data for date: \(date)")
    //            // Find step data for the current date
    //            //let dateFormatter = DateFormatter()
    //            //guard let dateObj = dateFormatter.date(from: date) else { return }
    //            //dateFormatter.dateFormat = "dd/MM/yyyy"
    //           // let formattedDate = dateFormatter.string(from: dateObj)
    //            let stepsEntry = stepsDataArray?.first { $0.date == date }
    //            let mySteps = stepsEntry?.totalSteps
    //            let totalSteps = (stepsEntry == nil) ? nil : mySteps ?? 0
    //            // Find heart rate data for the current date
    //            //            let heartEntry = heartDataArray.first { $0.date == date }
    //            //            let hourModel = (heartEntry == nil) ? nil : hourData  ?? []
    //            // Find sleep data for the current date
    //            let sleepEntry = sleepDataArray?.first { $0.date == date }
    //            let myTotalSleep: Double = sleepEntry?.totalSleep ?? 0.0
    //            let totalSleep = (sleepEntry == nil) ? nil : myTotalSleep
    //            let myRemSleep = sleepEntry?.remSleep ?? 0.0
    //            let remSleep = (sleepEntry == nil) ? nil : myRemSleep
    //            let myCoreSleep = sleepEntry?.coreSleep ?? 0.0
    //            let coreSleep = (sleepEntry == nil) ? nil : myCoreSleep
    //            let myDeepSleep = sleepEntry?.deepSleep ?? 0.0
    //            let deepSleep = (sleepEntry == nil) ? nil : myDeepSleep
    //            let activeEnergyEntry = activeEnergyDataArray?.first { $0.date == date }
    //            let myActiveEnergy = activeEnergyEntry?.activeEnergy ?? 0.0
    //            let activeCalorieBurned = (activeEnergyEntry == nil) ? nil : myActiveEnergy
    //            let restingEntry = restingHeartDataArray?.first { $0.date == date }
    //            let myRestingHeart = restingEntry?.heartRate ?? 0.0
    //            let restingHeartRate = (restingEntry == nil) ? nil : myRestingHeart
    //            let hrvEntry = hrvDataArray?.first { $0.date == date }
    //            let myHrv = hrvEntry?.hrvValue ?? 0.0
    //            let hrv = (hrvEntry == nil) ? nil : myHrv
    //
    //            let myDate = Date()
    //            print(date)
    //            // sending Date() instead of date
    //            // Create the HealthDateModel and append it to healthData
    ////            healthData.append(HealthDateModel(date: date, totalSteps: totalSteps, totalSleep: totalSleep, remSleep: remSleep, coreSleep: coreSleep, deepSleep: deepSleep, activeCalorieBurned: activeCalorieBurned, restingHeartRate: restingHeartRate, hrv: hrv))
    //            healthData.append(HealthDateModel(date: myDate, totalSteps: totalSteps, totalSleep: totalSleep, remSleep: remSleep, coreSleep: coreSleep, deepSleep: deepSleep, activeCalorieBurned: activeCalorieBurned, restingHeartRate: restingHeartRate, hrv: hrv))
    //        }
    //
    //        //print("Final healthData array: \(healthData)")
    //    }
    // MARK: - HRV fetch data
    //    func fetchHRVDataForWeek(completion: @escaping ([HRVDataModel]) -> Void) {
    //        // Define the HRV quantity type
    //        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
    //            print("HRV Type is not available")
    //            return
    //        }
    //        // Set the date range (last 7 days)
    //        let calendar = Calendar.current
    //        let endDate = Date()
    //        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
    //        // Create a predicate for the query
    //        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
    //        // Sort the results by date in ascending order
    //        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
    //        // Create the sample query
    //        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
    //            guard error == nil else {
    //                print("Error fetching HRV data: \(error!.localizedDescription)")
    //                return
    //            }
    //            var hrvDataDict: [String: [Double]] = [:]
    //            let dateFormatter = DateFormatter()
    //            dateFormatter.dateFormat = "dd-MM-yyyy"
    //            // Process each HRV sample
    //            if let hrvSamples = results as? [HKQuantitySample] {
    //                for sample in hrvSamples {
    //                    let date = sample.startDate
    //                    let dateString = dateFormatter.string(from: date)
    //                    // Get the HRV value in milliseconds
    //                    let hrvValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    //                    // Add HRV values to the dictionary grouped by date
    //                    if hrvDataDict[dateString] == nil {
    //                        hrvDataDict[dateString] = []
    //                    }
    //                    hrvDataDict[dateString]?.append(hrvValue)
    //                }
    //            }
    //            // Create an array to store the averaged HRV data
    //            var hrvDataArray: [HRVDataModel] = []
    //            for (date, hrvValues) in hrvDataDict {
    //                // Calculate the average HRV for each day
    //                let averageHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)
    //                let hrvData = HRVDataModel(date: date, hrvValue: averageHRV)
    //                hrvDataArray.append(hrvData)
    //            }
    //            // Return the data
    //            completion(hrvDataArray)
    //        }
    //        // Execute the query
    //        healthStore.execute(query)
    //    }
    //        // MARK: - Fetch resting heart rate
    //    func fetchRestingHeartRate(completion: @escaping ([RestingHeartDataModel]) -> Void) {
    //        let calendar = Calendar.current
    //        let endDate = Date()
    //        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
    //        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: []) // Removed strictEndDate for testing
    //        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
    //            print("Heart Rate Type is not available")
    //            return
    //        }
    //        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
    //            if let error = error {
    //                print("Error fetching heart rate data: \(error.localizedDescription)")
    //                completion([])
    //                return
    //            }
    //            var heartRateDataDict: [String: [Double]] = [:]
    //            if let results = results as? [HKQuantitySample] {
    //                for sample in results {
    //                    let heartRateValue = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
    //                    let heartRateDate = sample.startDate
    //
    //                    let formattedDate = heartRateDate.getFormattedDate(format: "dd/MM/yyyy")
    //                    //print("Heart rate sample: \(heartRateValue) on \(formattedDate)")
    //
    //                    // Adjust the criteria or remove it for now to check if you're receiving the data
    //                    if heartRateValue > 50 && heartRateValue < 90 { // Loosen the range for testing
    //                        if heartRateDataDict[formattedDate] == nil {
    //                            heartRateDataDict[formattedDate] = []
    //                        }
    //                        heartRateDataDict[formattedDate]?.append(heartRateValue)
    //                    }
    //                }
    //            }
    //            var heartRateData: [RestingHeartDataModel] = []
    //            for (date, values) in heartRateDataDict {
    //                if let minHeartRate = values.min() {
    //                    let heartRateModel = RestingHeartDataModel(date: date, heartRate: minHeartRate)
    //                    heartRateData.append(heartRateModel)
    //                }
    //            }
    //            completion(heartRateData)
    //        }
    //        healthStore.execute(query)
    //    }
    //    // MARK: - Fetch active energy burned
    //        func fetchActiveEnergyBurned(completion: @escaping ([ActiveEnergyModel]) -> Void) {
    //            // Set the predicate to fetch active energy data for the last 7 days
    //            let calendar = Calendar.current
    //            let endDate = Date()
    //            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
    //            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
    //            // Set the active energy burned type
    //            guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
    //                print("Active Energy Burned Type is not available")
    //                return
    //            }
    //            // Create a sample query
    //            let query = HKSampleQuery(sampleType: activeEnergyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
    //                // Handle errors
    //                if let error = error {
    //                    print("Error fetching active energy data: \(error.localizedDescription)")
    //                    completion([])
    //                    return
    //                }
    //                // Initialize an array to hold active energy data
    //                var activeEnergyData: [ActiveEnergyModel] = []
    //                // Iterate through the results
    //                if let results = results as? [HKQuantitySample] {
    //                    for sample in results {
    //                        let activeEnergyValue = sample.quantity.doubleValue(for: HKUnit.kilocalorie()) // Get value in kilocalories
    //                        let activeEnergyDate = sample.startDate // or sample.endDate, depending on your preference
    //
    //                        let energyModel = ActiveEnergyModel(date: "\(activeEnergyDate.getFormattedDate(format: "dd/MM/yyyy"))", activeEnergy: activeEnergyValue)
    //                        activeEnergyData.append(energyModel)
    //                    }
    //                }
    //                // Return the active energy data via the completion handler
    //                completion(activeEnergyData)
    //            }
    //            // Execute the query
    //            healthStore.execute(query)
    //        }
}

extension HealthKitManager {
    
    private func sendLogData() {
        LogManager.shared.sendLogsToServer() { result in
            switch result {
                case .success(let value):
                print("Successfully sent log data from HealthKitManager: \(value)")
            case .failure(let error):
                print("Error sending log data from HealthKitManager: \(error)")
            }
        }
    }
}

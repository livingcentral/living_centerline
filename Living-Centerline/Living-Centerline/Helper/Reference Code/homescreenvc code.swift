//
//  homescreenVC code.swift
//  Living-Centerline
//
//  Created by Developer on 10/10/24.
//

//import Foundation
// MARK: - Fetch heart data
//private func fetchHeartRateData() {
//    dispatchGroup.enter()
//    self.healthKitManager.fetchHeartRateSamplesForWeek { [weak self] averageHeartRateData in
//        guard let self else {
//            self?.dispatchGroup.leave()
//            return
//        }
//        dispatchGroup.leave()
//        // Assign the fetched data to heartDataArray
//        self.heartDataArray = averageHeartRateData
//        // Iterate through the array of HeartDataModel
//        for heartData in averageHeartRateData {
//            let date = heartData.date
//            let hourModels = heartData.hourmodel
//            // Sort hours in ascending order (if necessary)
//            let sortedHourModels = hourModels.sorted { $0.hourValue < $1.hourValue }
//            // Reset hourlyData for each date
//            self.hourlyData = []
//            for hourModel in sortedHourModels {
//                // Append the HourModel to hourlyData
//                self.hourlyData.append(hourModel)
//            }
//            // Append the HeartDataModel with sorted hourlyData
//           // self.heartDataArray.append(HeartDataModel(date: date, hourmodel: self.hourlyData))
//            //print("heart data is \n \(self.heartDataArray)")
//        }
//        // Sort the data by date in ascending and descending order
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd/MM/yyyy"
//        let sortedDataAscending = self.healthData.sorted {
//            guard let firstDate = dateFormatter.date(from: $0.date),
//                  let secondDate = dateFormatter.date(from: $1.date) else { return false }
//            return firstDate < secondDate
//        }
//        let sortedDataDescending = self.healthData.sorted {
//            guard let firstDate = dateFormatter.date(from: $0.date),
//                  let secondDate = dateFormatter.date(from: $1.date) else { return false }
//            return firstDate > secondDate
//        }
//        // Print sorted data in descending order
//        print("\nSorted in Descending Order:")
//        for data in sortedDataDescending {
//            //print("Date: \(data.date), Total Steps: \(data.totalSteps)")
//        }
//    }
//}

// MARK: - fetch sleep data
//    private func fetchSleepData() {
//        // Fetch sleep data
//        dispatchGroup.enter()
//        self.healthKitManager.retrieveSleepDataForWeek { [weak self] sleepData in
//            guard let self else {
//                self?.dispatchGroup.leave()
//                return
//            }
//            dispatchGroup.leave()
//            for sleep in sleepData {
//                //print("Date: \(sleep.date), core sleep \(sleep.coreSleep), rem sleep \(sleep.remSleep), deep sleep \(sleep.deepSleep), sleep duration \(sleep.sleepDuration)")
//            }
//            self.sleepDataArray = sleepData
//        }
//    }
// MARK: - fetch HRV data
//    private func fetchHRVData() {
//        dispatchGroup.enter()
//        healthKitManager.fetchHRVDataForWeek { [weak self] hrvDataArray in
//            guard let self else {
//                self?.dispatchGroup.leave()
//                return
//            }
//            dispatchGroup.leave()
//            self.hrvDataArray = hrvDataArray
//            for hrvData in hrvDataArray {
//                // print("Date: \(hrvData.date), HRV: \(hrvData.hrvValue) ms")
//
//            }
//        }
//    }
// MARK: - fetch resting heart data
//    private func fetchRestingHeartData() {
//        dispatchGroup.enter()
//        healthKitManager.fetchRestingHeartRate { [weak self] restingHeartData in
//            guard let self else {
//                self?.dispatchGroup.leave()
//                return
//            }
//            for model in restingHeartData {
//                restingHeartDataArray.append(RestingHeartDataModel(date: model.date, heartRate: model.heartRate))
//                //print("Date: \(model.date), Resting Heart Rate: \(model.heartRate) BPM")
//            }
//            dispatchGroup.leave()
//        }
//    }
// MARK: - fetch active energy burned
//    private func fetchActiveEnergyBurnedData() {
//        dispatchGroup.enter()
//        healthKitManager.fetchActiveEnergyBurned { [weak self] activeEnergyData in
//            guard let self else {
//                self?.dispatchGroup.leave()
//                return
//            }
//            dispatchGroup.leave()
//            activeEnergyDataArray = activeEnergyData
//            for model in activeEnergyData {
//                //print("Date: \(model.date), Active Energy Burned: \(model.activeEnergy) kcal")
//            }
//        }
//    }

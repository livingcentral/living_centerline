//
//  HealthSyncManager.swift
//  Living-Centerline
//
//  Created by Rajal Sardhara on 27/11/24.
//

import UIKit
import CoreData
import ProgressHUD

protocol HealthSyncDelegate:AnyObject {
    func fetchMissingHealthData()
}

class HealthSyncManager {
    // MARK: Variables declarations
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //Singleton instance
    var context:NSManagedObjectContext!
    
    let healthKitManager = HealthKitManager()
    var healthData = [HealthDateModel]()
    let defaults = UserDefaults.standard
    var daysListArray = [String]()
    weak var delegate: HealthSyncDelegate?
    
    // MARK: Methods to Open, Store and Fetch data
    func openDatabase(isSave: Bool, lastSyncDate: Date) {
        context = appDelegate.persistentContainer.viewContext
        LogManager.shared.addLog(data: "#HealthSyncManager open database")
        print("open database")
        // let entity = NSEntityDescription.entity(forEntityName: "HealthSync", in: context)
        //let HealthSync = NSManagedObject(entity: entity!, insertInto: context)
        
        _ = (isSave == true) ? saveData(isSync: false, lastSyncDate: lastSyncDate) : fetchData(lastSyncDate1: lastSyncDate)
    }
    
    func saveData(isSync: Bool, lastSyncDate: Date) {
        LogManager.shared.addLog(data: "#HealthSyncManager save data called")
        let testDate = getDate(forDaysAgo: 7) //lastSyncDate
        LogManager.shared.addLog(data: "#HealthSyncManager test date\(testDate)")
        let currentDate = Date()//.getFormattedDate(format: "MM-dd-yyyy")
        let dataFetch: NSFetchRequest<HealthSync> = HealthSync.fetchRequest()
        dataFetch.sortDescriptors = [NSSortDescriptor(key: "lastSyncDate", ascending: false)] // Sort by date descending
        
        do {
            context = appDelegate.persistentContainer.viewContext
            
            let results = try context.fetch(dataFetch)
            
            if results.isEmpty {
                // No existing entries, insert the new one
               // let testDate = getDate(forDaysAgo: 30) //lastSyncDate
                let dataAdd = HealthSync(context: context)
                dataAdd.lastSyncDate = lastSyncDate
                dataAdd.isSync = true
                LogManager.shared.addLog(data: "#HealthSyncManager Inserted new sync data: \(lastSyncDate)")
                print("Inserted new sync data: \(lastSyncDate)")
                sendLogData()
            } else {
                // Keep only the first entry (latest)
                if let latestEntry = results.first {
                    let localLastSyncDate = convertUTCToLocal(utcDate: lastSyncDate)
                    let localCurrentDate = convertUTCToLocal(utcDate: currentDate)
                    latestEntry.lastSyncDate = isSync == true ? localLastSyncDate : localCurrentDate
                    latestEntry.isSync = true
                    LogManager.shared.addLog(data: "#HealthSyncManager Updated latest entry: \(latestEntry.lastSyncDate!)")
                    print("Updated latest entry: \(latestEntry.lastSyncDate!)")
                    sendLogData()
                } else {
                    print("other entry else case executed")
                }
                // Remove all other entries
                if results.count > 1 {
                    let entriesToDelete = results.dropFirst() // All entries except the first one
                    for entry in entriesToDelete {
                        context.delete(entry)
                        sendLogData()
                    }
                    LogManager.shared.addLog(data: "#HealthSyncManager Deleted \(entriesToDelete.count) older entries.")
                    print("Deleted \(entriesToDelete.count) older entries.")
                    sendLogData()
                } else {
                    print("result.count is 1 or less")
                }
            }
            // Save the context
            LogManager.shared.addLog(data: "#HealthSyncManager Saving changes to Core Data...")
            print("Saving changes to Core Data...")
            try context.save()
            LogManager.shared.addLog(data: "#HealthSyncManager Data sync successfully updated with local DB")
            print("Data sync successfully updated with local DB")
            sendLogData()
        } catch {
            LogManager.shared.addLog(data: "#HealthSyncManager Error during Core Data operation: \(error)")
            LogManager.shared.addLog(data: "#HealthSyncManager Failed to save data.")
            print("Error during Core Data operation: \(error)")
            print("Failed to save data.")
            sendLogData()
        }
        //    UserDBObj.setValue(currentDate, forKey: "lastSyncDate")
        //  UserDBObj.setValue(true, forKey: "isSync")
    }
    
    func getDate(forDaysAgo daysAgo: Int) -> Date {
        LogManager.shared.addLog(data: "#HealthSyncManager get days ago date")
        let calendar = Calendar.current
        guard let calculatedDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
            LogManager.shared.addLog(data: "#HealthSyncManager Failed to calculate the date")
            sendLogData()
            fatalError("Failed to calculate the date")
        }
        sendLogData()
        return calculatedDate
    }
    
    func clearCoreData(context: NSManagedObjectContext) {
        // Get the list of all entities in the Core Data model
        LogManager.shared.addLog(data: "#HealthSyncManager Get the list of all entities in the Core Data model")
        guard let persistentStoreCoordinator = context.persistentStoreCoordinator else { return }
        let entities = persistentStoreCoordinator.managedObjectModel.entities
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            fetchRequest.includesPropertyValues = false // Fetch only references, not the property data
            
            do {
                let objects = try context.fetch(fetchRequest)
                for object in objects {
                    guard let managedObject = object as? NSManagedObject else { continue }
                    context.delete(managedObject)
                }
                sendLogData()
            } catch {
                LogManager.shared.addLog(data: "#HealthSyncManager Failed to fetch or delete objects for entity \(entity.name ?? "Unknown"): \(error)")
                print("Failed to fetch or delete objects for entity \(entity.name ?? "Unknown"): \(error)")
                sendLogData()
            }
        }
        // Save the context to persist the deletions
        do {
            try context.save()
            LogManager.shared.addLog(data: "#HealthSyncManager Core Data cleared successfully!")
            print("Core Data cleared successfully!")
            sendLogData()
        } catch {
            LogManager.shared.addLog(data: "#HealthSyncManager Failed to save context after clearing Core Data: \(error)")
            print("Failed to save context after clearing Core Data: \(error)")
            sendLogData()
        }
    }
    
    func fetchData(lastSyncDate1: Date) {
        LogManager.shared.addLog(data: "#HealthSyncManager fetch data called")
        //  ProgressHUD.dismiss()
        DispatchQueue.main.async {
            ProgressHUD.animate("Sync in Progress")
        }
        context = appDelegate.persistentContainer.viewContext
        print("Fetching Data..")
        LogManager.shared.addLog(data: "#HealthSyncManager Fetching Data..")
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "HealthSync")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            if let filteredResults = result.compactMap({ $0 as? NSManagedObject }).filter({
                ($0.value(forKey: "isSync") as? Bool) == true &&
                ($0.value(forKey: "lastSyncDate") as? Date) != nil
            }).first {
                //print("Filtered result: \(filteredResults)")
                if let lastSyncDate = filteredResults.value(forKey: "lastSyncDate") as? Date {
                    LogManager.shared.addLog(data: "#HealthSyncManager lastSyncDate: \(lastSyncDate)")
                    print("lastSyncDate: \(lastSyncDate)")
                    
                    guard let currentLocal = convertUTCToLocal(utcDate: Date()), let lastSyncDateLocal = convertUTCToLocal(utcDate: lastSyncDate) else {
                        LogManager.shared.addLog(data: "#HealthSyncManager could not convert lastSyncDate to local date")
                        print("could not convert lastSyncDate to local date")
                        sendLogData()
                        return
                    }
//                        let dateDifference = differenceBetweenTwoDatesString(dateString1: lastSyncDateLocal.getFormattedDate(format: "MM-dd-yyyy"), dateString2: currentLocal)
                    let dateDifference = differenceBetweenTwoDates(startDate: lastSyncDateLocal, endDate: currentLocal)
                    LogManager.shared.addLog(data: "#HealthSyncManager difference is \(dateDifference)")
                    sendLogData()
                    print("difference is \(dateDifference)")
                    if dateDifference > 1 {
                        let difference = dateDifference == 30 ? 30 : dateDifference - 1
                        defaults.set(difference, forKey: "numberOfHealthData")
                        LogManager.shared.addLog(data: "#HealthSyncManager request health kit authorisation")
                        healthData.removeAll()
                        sendLogData()
                        healthKitManager.requestHealthKitAuthorization { [weak self] result in
                            guard let self else { return }
                            switch result {
                            case .success(let healthData) :
                                LogManager.shared.addLog(data: "#HealthSyncManager health data received \(healthData)")
                                self.healthData = healthData
                                print("healthdata count \(healthData.count)")
                                
                                print("send health data")
                                LogManager.shared.addLog(data: "#HealthSyncManager send health data")
                                sendLogData()
                                sendHealthData(lastSyncDate: lastSyncDate1)
                                
                            case .failure(let error):
                                LogManager.shared.addLog(data: "#HealthSyncManager \(error)")
                                sendLogData()
                                print("Failed to fetch health data: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        ProgressHUD.succeed("data already in sync", delay: 1.5)
                        healthData.removeAll()
                        LogManager.shared.addLog(data: "#HealthSyncManager no need to sync health data")
                        print("no need to sync health data")
                        sendLogData()
                        delegate?.fetchMissingHealthData()
                    }
                }
            } else {
                // print("No matching result found.")
                LogManager.shared.addLog(data: "#HealthSyncManager no data is sync yet get 30 days data here")
                print("no data is sync yet get 30 days data here")
                defaults.set(30, forKey: "numberOfHealthData")
                sendLogData()
                healthKitManager.requestHealthKitAuthorization { [weak self] result in
                    guard let self else { return }
                    switch result {
                        
                    case .success(let healthData) :
                        LogManager.shared.addLog(data: "#HealthSyncManager success \(healthData)")
                        self.healthData = healthData
                        print("healthdata count \(healthData.count)")
                        //ProgressHUD.dismiss()
                        LogManager.shared.addLog(data: "#HealthSyncManager send health data \(lastSyncDate1)")
                        sendLogData()
                        sendHealthData(lastSyncDate: lastSyncDate1)
                        
                    case .failure(let error) :
                        LogManager.shared.addLog(data: "#HealthSyncManager Failed to fetch health data: \(error.localizedDescription)")
                        sendLogData()
                        print("Failed to fetch health data: \(error.localizedDescription)")
                    }
                    //openDatabase(isSave: true)
                }
            }
        } catch {
            LogManager.shared.addLog(data: "#HealthSyncManager Fetching data Failed")
            sendLogData()
            print("Fetching data Failed")
        }
    }
    
//    func differenceBetweenTwoDatesString(dateString1: String, dateString2: Date) -> Int {
//        // DateFormatter to parse the MM-dd-yyyy format
//        LogManager.shared.addLog(data: "#HealthSyncManager differenceBetweenTwoDatesString \(dateString1) and \(dateString2)")
//        var difference = 0
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM-dd-yyyy"
//        
//        // Convert the date strings into Date objects
//        guard let date1 = dateFormatter.date(from: dateString1) else {
//            print("Invalid date format.")
//            LogManager.shared.addLog(data: "#HealthSyncManager Invalid date format.")
//            sendLogData()
//            return 0
//        }
//        
//        // Calculate the difference in days between the two dates
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.day], from: date1, to: dateString2)
//        
//        if let dayDifference = components.day {
//            difference = dayDifference
//        }
//        LogManager.shared.addLog(data: "#HealthSyncManager difference \(difference)")
//        sendLogData()
//        return difference
//    }
    
    private func differenceBetweenTwoDates(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        guard let days = calendar.dateComponents([.day],
                                                 from: calendar.startOfDay(for: startDate),
                                                 to: calendar.startOfDay(for: endDate)).day else {
            return 0
        }
        return days
    }


    // MARK: - submit health data
    private func sendHealthData(lastSyncDate: Date) {
        ProgressHUD.animate("Syncing with server")
        LogManager.shared.addLog(data: "#HealthSyncManager sendHealthData \(lastSyncDate)")
        sendLogData()
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            APIManager.shareInstance.postHealthData(token: userToken, url: API.submitHealthData, healthData: healthData) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let success):
                    if success {
                        LogManager.shared.addLog(data: "#HealthSyncManager sendHealthData \(success)")
                        print(result)
                        ProgressHUD.succeed("Data Sync Successfully", delay: 2.5)
                        print("health Data sent successfully")
                        
                        defaults.set(0, forKey: "numberOfHealthData")
                        self.healthData.removeAll()
                        LogManager.shared.addLog(data: "#HealthSyncManager open database is save true")
                        self.openDatabase(isSave: true, lastSyncDate: lastSyncDate)
                        LogManager.shared.addLog(data: "#HealthSyncManager delegate?.fetchMissingHealthData()")
                        sendLogData()
                        delegate?.fetchMissingHealthData()
                        //  ProgressHUD.dismiss()
                    }
                case .failure(let error):
                    LogManager.shared.addLog(data: "#HealthSyncManager \(error)")
                    sendLogData()
                    ProgressHUD.failed("Error uploading the data", delay: 1.5)
                    ProgressHUD.colorBackground = .red
                    print("Failed to send health data: \(error.localizedDescription)")
                }
            }
            //Api.postHealthData(token: userToken, url: API.submitHealthData)
        }
    }
}

extension HealthSyncManager {
    
    private func sendLogData() {
        LogManager.shared.sendLogsToServer() { result in
            switch result {
            case .success(let value):
                print("Successfully sent log data from health sync screen: \(value)")
            case .failure(let error):
                print("Error sending log data from health sync screen: \(error)")
            }
        }
    }
}

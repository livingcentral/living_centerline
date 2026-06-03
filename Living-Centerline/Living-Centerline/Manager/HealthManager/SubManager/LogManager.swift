//
//  LogManager.swift
//  Living-Centerline
//
//  Created by APPLE on 2/21/25.
//

import Foundation

class LogManager {
    
    static let shared = LogManager() // Singleton instance
    
    private var logs: [LogModel] = [] // In-memory log storage
    private let apiCallQueue = DispatchQueue(label: "com.livingCenterline.apiCallQueue") // Serial queue for API calls

    private init() {}

    // Function to add a log entry
    func addLog(data: Any) {
        let newLog = LogModel(data: data as! String)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.append(newLog) // Add the new log to the in-memory array
        }
    }
    
    // Function to get logs from the in-memory array
    func getLogsFromArray() -> [LogModel] {
        return logs // Return the logs array
    }
    
    // Send logs to the server (using the provided token and URL)
    func sendLogsToServer(completion: @escaping (Result<Bool, Error>) -> Void) {
        let logs = getLogsFromArray() // Get logs from the array
        
        // Ensure the logs are wrapped in the correct structure
        if logs.count > 0 {
            
            let payload: [String: Any] = ["data": logs.map { $0.toDictionary() }]
            
            // Convert the payload to JSON
            let token = UserDefaults.standard.value(forKey: "userToken") as? String ?? ""
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) {
                if !token.isEmpty {
                    // Enqueue the API call to ensure sequential processing
                    apiCallQueue.async {
                        APIManager.shareInstance.sendLogsToAPI(token: token, url: API.sendLog, logs: logs) { success in
                            if success {
                                // Clear logs if successfully sent
                                print("Logs were successfully sent.")
                                self.clearLogs()
                            }
                            completion(success ? .success(true) : .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to send logs"])))
                        }
                    }
                } else {
                    print("No token found, cannot send logs")
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token found"])))
                }
            } else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode logs"])))
            }
        } else {
            print("logs is empty")
        }
    }

    // Clear all logs after they have been successfully sent to the server
    private func clearLogs() {
        logs.removeAll() // Remove all logs from the array
    }
}



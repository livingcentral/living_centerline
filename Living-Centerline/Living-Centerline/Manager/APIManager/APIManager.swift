
//  APIManager.swift
//  Living-Centerline
//  Created by MACMonterio on 19/09/2024.

import Foundation
//import Alamofire 5.8.1

class APIManager {
    static let shareInstance = APIManager()
    // MARK: Register API Calling
    func callingRegisterApi(fName: String, lName: String, email: String, password: String, completion: @escaping (Result<Any, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success(["success": true, "message": "Mock registration accepted", "token": MockData.token]))
            return
        }

        
        let url = API.register_url
        
        let parameters : [String: Any] = [
            "first_name": fName,
            "last_name": lName,
            "email": email,
            "password": password
        ]
        
        guard let apiUrl = URL(string: url) else {
            print("URL is not valid URL ...")
            return
        }
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("Body is empty ..")
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
           // guard let self else { return }
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Response"])))
                return
            }
            
            // Check the status code to see if the email is already registered
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        completion(.success(jsonResponse))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                    }
                } catch {
                    completion(.failure(error))
                }
                
                
            default:
                if let jsonresponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorMessage = jsonresponse["message"] as? String {
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }else{
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            }
        }.resume()
    }
    // MARK: Login API Calling
    func callingLogInApi(email: String, password: String, completion: @escaping (Result<GetProfileModel, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            MockData.seedUserDefaults()
            completion(.success(MockData.profile))
            return
        }

        guard let url = URL(string: API.login_url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error encoding parameters"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let apiResponse = try JSONDecoder().decode(GetProfileModel.self, from: data)
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            } else {
                do {
                    // Parse error response properly
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = jsonObject["message"] as? String {
                        let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                        completion(.failure(error))
                    } else {
                        let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
                        completion(.failure(error))
                    }
                } catch {
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to parse error message"])))
                }
            }
        }
        task.resume()
    }

    // MARK: - GetProfile Api Calling
    func callingGetProfileApi(completion: @escaping (Result<GetProfileModel, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            MockData.seedUserDefaults()
            completion(.success(MockData.profile))
            return
        }

        // Fetch the user token from UserDefaults
        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        // Construct the URL
        guard let url = URL(string: API.getProfile_url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(usersToken, forHTTPHeaderField: "Authorization")  // Use the token directly as in the Alamofire example
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Pass any errors to the completion handler
                print("Request failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Ensure there is valid response data
            guard let data = data else {
                print("No data received.")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            // Log raw response data for debugging
       //     print("Raw Response Data: \(String(decoding: data, as: Unicode.UTF8.self))")
            
            // Attempt to decode the JSON response into the GetProfileModel
            do {
                
                let apiResponse = try JSONDecoder().decode(GetProfileModel.self, from: data)
                completion(.success(apiResponse))
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        // Start the task
        task.resume()
    }
    // MARK: Get OTP APi Calling
    func callingSendOTPApi(email: String, completion: @escaping (Result<Any, Error>) -> Void) {
        let url = API.sendToPassword_url
        
        let parameters : [String: Any] = [
            "email": email
        ]
        guard let apiUrl = URL(string: url)else{
            print("URL is not Valid....")
            return
        }
        guard let httBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("Body is Empty...")
            return
        }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = httBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Response"])))
                return
            }
            
            switch httpResponse.statusCode{
            case 200...299:
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        completion(.success(jsonResponse))
                    }else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                    }
                } catch {
                    completion(.failure(error))
                }
                
            default:
                if let jsonresponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorMessage = jsonresponse["message"] as? String {
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            }
        }.resume()
    }
    // MARK: Verify OTP API call
    func callingVerifyOTPApi(email: String, otp: String, completion: @escaping (Result<Any, Error>) -> Void) {
        let url = API.verifyOTPPassword_url
        
        // Prepare the request body with email and OTP
        let parameters: [String: Any] = [
            "email": email,
            "otp": otp
        ]
        
        guard let apiUrl = URL(string: url) else {
            print("Invalid URL")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("Invalid request body")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request body"])))
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        completion(.success(jsonResponse))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                    }
                } catch {
                    completion(.failure(error))
                }
                
            default:
                if let jsonresponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorMessage = jsonresponse["message"] as? String {
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }else{
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            }
        }.resume()
    }
    // MARK: Reset NewPassword Set
    func callingSetNewPasswordApi(email: String, otp: String, password: String, completion: @escaping (Result<Any, Error>) -> Void) {
        let url = URL(string: API.forgotPassword_url)!
        
        // Prepare the request body with email, OTP, and password
        let parameters: [String: Any] = [
            "email": email,
            "otp": otp,
            "password": password
        ]
        
        // Convert parameters to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid parameters"])))
            return
        }
        
        // Create a URLRequest object
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Create a URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors
            if let error = error {
                completion(.failure(error))
                return
            }
            // Check if response is valid and handle response data
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if (200...299).contains(statusCode) {
                    // Try to parse the JSON response
                    if let data = data,
                       let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                        completion(.success(jsonResponse))
                    } else {
                        completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                    }
                } else if statusCode == 409 {
                    let errorMessage = "OTP is invalid, please request a new one."
                    completion(.failure(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                } else {
                    let errorResponse = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse])))
                }
            }
        }
        // Start the task
        task.resume()
    }
    // MARK: Logout Api
    func callingLogoutApi(completion: @escaping (Result<Any, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success(["success": true, "message": "Mock logout accepted"]))
            return
        }

        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        let url = URL(string: API.logout_url)!
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(usersToken)", forHTTPHeaderField: "Authorization")  // Add Bearer token
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check if there was an error
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Check for valid response data
            if let httpResponse = response as? HTTPURLResponse, let data = data {
                do {
                    // Try to decode the data into JSON
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                        print("JSON Response: \(jsonResponse)")
                        completion(.success(jsonResponse))  // Pass the response in case of success
                    } else {
                        let responseString = String(data: data, encoding: .utf8) ?? "Invalid response"
                        print("Response String: \(responseString)")
                        let errorMessage = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString])
                        completion(.failure(errorMessage))
                    }
                }
            } else {
                print("Received an unexpected error")
                let unknownError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
                completion(.failure(unknownError))
            }
        }
        
        // Start the task
        task.resume()
    }
    // MARK: Delete User Account Api
    func callingDeleteAccountApi(completion: @escaping (Result<Any, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success(["success": true, "message": "Mock delete accepted"]))
            return
        }

        // Fetch the user token from UserDefaults
        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        // Construct the URL
        guard let url = URL(string: API.delete_url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(usersToken, forHTTPHeaderField: "Authorization")  // Removed "Bearer" prefix
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle error
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Handle valid response data
            if let httpResponse = response as? HTTPURLResponse {
                // Check for successful status code
                if (200...299).contains(httpResponse.statusCode) {
                    // Handle success
                    if let data = data {
                        // Try to decode the data into JSON
                        if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                            print("Response JSON: \(jsonResponse)")
                            completion(.success(jsonResponse))  // Pass the response in case of success
                        } else {
                            let responseString = String(data: data, encoding: .utf8) ?? "Invalid response"
                            print("Response String: \(responseString)")
                            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: responseString])))
                        }
                    } else {
                        let responseString = "No data received."
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: responseString])))
                    }
                } else {
                    // Handle HTTP errors
                    let responseString = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                    print("Error: HTTP Status Code \(httpResponse.statusCode)")
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString])))
                }
            } else {
                let unknownError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
                completion(.failure(unknownError))
            }
        }
        
        // Start the task
        task.resume()
    }
    // MARK: EditProfile Api Calling
    func callingEditProfileApi(first_name: String, last_name: String, completion: @escaping (Result<Any, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success(["success": true, "message": "Mock profile update accepted"]))
            return
        }

        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        // Construct the URL
        guard let url = URL(string: API.editProfile_url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Prepare the request body with first name and last name
        let parameters: [String: Any] = [
            "first_name": first_name,
            "last_name": last_name
        ]
        
        // Convert parameters to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize JSON"])))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(usersToken, forHTTPHeaderField: "Authorization")  // No "Bearer" prefix here
        request.httpBody = jsonData
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check for valid response and status code
            if let httpResponse = response as? HTTPURLResponse, let data = data {
                if (200...299).contains(httpResponse.statusCode) {
                    do {
                        // Try to decode the data into JSON
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            completion(.success(jsonResponse))
                        } else {
                            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    // Handle HTTP errors
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    if httpResponse.statusCode == 409 {
                        completion(.failure(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "Enter valid name..."])))
                    } else {
                        completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                }
            } else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
            }
        }
        // Start the task
        task.resume()
    }
    
    // MARK: GetQuestion API Calling...
    func callingGetQuestionApi(completion: @escaping (Result<GetQuestionModel, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            MockData.seedUserDefaults()
            completion(.success(MockData.questions))
            return
        }

        // Fetch the user token from UserDefaults
        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        // Construct the URL
        guard let url = URL(string: API.getQuestion_url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(usersToken, forHTTPHeaderField: "Authorization") // Removed "Bearer" prefix
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure there is valid response data
            guard let data = data else {
                print("No data received.")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            // Log raw response data for debugging
            print("Raw Response Data: \(String(decoding: data, as: Unicode.UTF8.self))")  // Uncomment if needed
            
            // Attempt to decode the JSON response into the GetQuestionModel
            do {
                let apiResponse = try JSONDecoder().decode(GetQuestionModel.self, from: data)
                completion(.success(apiResponse))
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        // Start the task
        task.resume()
    }
    
    // MARK: - submit answer API
    func callingSubmitAllAnsApi(questions: [[String: Any]], completion: @escaping (Result<Any, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success(["success": true, "message": "Mock survey submission accepted"]))
            return
        }

        // Validate the URL
        guard let url = URL(string: API.submitSurvey_url) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Fetch the token from UserDefaults
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication token not found."])))
            return
        }
        
        // Create the parameters as a JSON object
        let parameters: [String: Any] = ["questions": questions] // Wrap questions in a dictionary
        
        // Convert parameters to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize JSON"])))
            return
        }
        
        // Debug: Print the JSON string before sending the request
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Sending JSON: \(jsonString)")
        }
        
        // Create the request
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "POST"  // Use POST as specified
        request.addValue(token, forHTTPHeaderField: "Authorization") // No "Bearer" prefix
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set the HTTP body
        request.httpBody = jsonData
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check for valid response and status code
            if let httpResponse = response as? HTTPURLResponse, let data = data {
                if (200...299).contains(httpResponse.statusCode) {
                    do {
                        // Try to decode the data into JSON
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            completion(.success(jsonResponse))
                        } else {
                            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    // Handle HTTP errors
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            } else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
            }
        }
        // Start the task
        task.resume()
    }
    
    // MARK: - Submit health data
    func postHealthData(token: String, url: String, healthData: [HealthDateModel], completion: @escaping (Result<Bool, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success(true))
            return
        }

        // Validate the URL
        guard let url = URL(string: url) else {
            print("Invalid URL")
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Create the request and set the method to POST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization") // Add the authorization header
        
        // Wrap healthData in a HealthDataRequest struct
        let healthDataRequest = HealthDataRequest(data: healthData)
        
        // Convert healthDataRequest to JSON
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(healthDataRequest)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            completion(.failure(error))
            return
        }
        
        // Create the URLSession task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending POST request: \(error)")
                completion(.failure(error))
                return
            }
            // Parse the JSON response for the success status
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(HealthDataResponse.self, from: data)
                    if decodedResponse.success {
                        completion(.success(true))
                    } else {
                        // Return false with an error message if success is false
                        let error = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: decodedResponse.message])
                        completion(.failure(error))
                    }
                } catch {
                    print("Error decoding response: \(error)")
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received."])))
            }
        }
        // Start the task
        task.resume()
    }
    
    // MARK: Get last Sync API Calling...
    func getLastSyncDate(completion: @escaping (Result<LastSyncModel, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.failure(NSError(domain: "MockData", code: 204, userInfo: [NSLocalizedDescriptionKey: "No mock last sync date configured."])))
            return
        }

        // Fetch the user token from UserDefaults
        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        // Construct the URL
        guard let url = URL(string: API.lastSyncDate) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(usersToken, forHTTPHeaderField: "Authorization") // Removed "Bearer" prefix
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure there is valid response data
            guard let data = data else {
                print("No data received.")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            // Log raw response data for debugging
           // print("Raw Response Data: \(String(decoding: data, as: Unicode.UTF8.self))")  // Uncomment if needed
            
            // Attempt to decode the JSON response into the GetQuestionModel
            do {
                let apiResponse = try JSONDecoder().decode(Welcome.self, from: data)
                completion(.success(apiResponse.data))
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        // Start the task
        task.resume()
    }
    
    // MARK: - retrieve missing health data
    func getMissingHealthData(completion: @escaping (Result <[DataClass], Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success([]))
            return
        }

        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        // Construct the URL
        guard let url = URL(string: API.fetchMissingData) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(usersToken, forHTTPHeaderField: "Authorization") // Removed "Bearer" prefix
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure there is valid response data
            guard let data = data else {
                print("No data received.")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            // Log raw response data for debugging
           // print("Raw Response Data: \(String(decoding: data, as: Unicode.UTF8.self))")  // Uncomment if needed
            
            // Attempt to decode the JSON response into the GetQuestionModel
            do {
//                let decoder = JSONDecoder()
//                    decoder.dateDecodingStrategy = .iso8601 // Configure decoder for ISO 8601 date strings
                let apiResponse = try JSONDecoder().decode(MissingHealthDataModel.self, from: data)
                let responseData = apiResponse.data.map { $0.data }
                completion(.success(responseData))
            } catch {
                print("JSON Decoding Error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // MARK: - retrieve missing health dates
    func getMissingHealthDates(completion: @escaping (Result <MissingDates, Error>) -> Void) {
        if AppConfig.usesFixtureData {
            completion(.success(MissingDates(missingDates: [])))
            return
        }

        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
            print("User token not found.")
            return
        }
        
        // Construct the URL
        guard let url = URL(string: API.fetchMissingDates) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(usersToken, forHTTPHeaderField: "Authorization") // Removed "Bearer" prefix
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure there is valid response data
            guard let data = data else {
                print("No data received.")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            // Log raw response data for debugging
           // print("Raw Response Data: \(String(decoding: data, as: Unicode.UTF8.self))")  // Uncomment if needed
            
            // Attempt to decode the JSON response into the GetQuestionModel
            do {
//                let decoder = JSONDecoder()
//                    decoder.dateDecodingStrategy = .iso8601 // Configure decoder for ISO 8601 date strings
                let apiResponse = try JSONDecoder().decode(MissingDatesModel.self, from: data)
                let responseData = apiResponse.data
                completion(.success(responseData))
            } catch {
                print("JSON Decoding Error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // MARK: - Send log data
    func sendLogsToAPI(token: String, url: String, logs: [LogModel], completion: @escaping (Bool) -> Void) {
        if AppConfig.usesFixtureData {
            completion(true)
            return
        }

        guard let apiURL = URL(string: url) else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"

        // Set Authorization and Content-Type headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization") // Removed "Bearer" prefix

        // Wrap the logs into the "data" key and prepare the request body
        var wrappedLogData = [String: Any]()
        wrappedLogData["data"] = logs.map { $0.toDictionary() } // Convert each log to a dictionary

        // Print the wrapped data to check before sending
        if let wrappedJsonData = try? JSONSerialization.data(withJSONObject: wrappedLogData, options: .prettyPrinted) {
           // if let jsonString = String(data: wrappedJsonData, encoding: .utf8) {
               // print("Sending JSON data to server: \(jsonString)")  // Print what we are sending to the server
           // }

            // Set the body with wrapped JSON data
            request.httpBody = wrappedJsonData
        } else {
            print("Error serializing wrapped log data")
            completion(false)
            return
        }

        // Create the URLSession task to send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending logs: \(error)")
                completion(false)
                return
            }

            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(logResposnseModel.self, from: data)
                    if decodedResponse.success {
                        completion(true)
                    } else {
                        print("Server error: \(decodedResponse.message)")
                        completion(false)
                    }
                } catch {
                    print("Error decoding response: \(error)")
                    completion(false)
                }
            } else {
                print("No response data")
                completion(false)
            }
        }
        // Start the task
        task.resume()
    }
}

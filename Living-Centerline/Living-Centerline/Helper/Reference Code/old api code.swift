//
//  old api code.swift
//  Living-Centerline
//
//  Created by Developer on 10/10/24.
//

//import Foundation
//import Alamofire
// API Manager
//    func callingLogInApi(email: String, password: String, completion: @escaping (Result<Any, Error>) -> Void) {
//        let url = API.login_url
//
//        let parameters: [String: Any] = [
//            "email": email,
//            "password": password
//        ]
//
//        // Make the request using Alamofire
//        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: ["Accept": "application/json", "Content-Type": "application/json"])
//            .validate(statusCode: 200...299) // Automatically handles 2xx responses
//            .responseJSON { response in
//                switch response.result {
//                case .success(let jsonResponse):
//                    // Handle the successful case
//                    if let jsonResponse = jsonResponse as? [String: Any] {
//                        completion(.success(jsonResponse))
//                    } else {
//                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
//                    }
//
//                case .failure(let error):
//                    // Extract error message based on status code
//                    if let data = response.data {
//                        do {
//                            if let jsonresponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                               let errorMessage = jsonresponse["message"] as? String {
//                                completion(.failure(NSError(domain: "", code: response.response?.statusCode ?? 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
//                            } else {
//                                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
//                                completion(.failure(NSError(domain: "", code: response.response?.statusCode ?? 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
//                            }
//                        } catch {
//                            completion(.failure(error))
//                        }
//                    } else {
//                        // If no error data is available, return the general error
//                        completion(.failure(error))
//                    }
//                }
//            }
//    }
//    func callingSetNewPasswordApi(email: String, otp: String, password: String, completion: @escaping (Result<Any, Error>) -> Void) {
//        let url = API.forgotpassword_url
//
//        // Prepare the request body with email, OTP, and password
//        let parameters: [String: Any] = [
//            "email": email,
//            "otp": otp,
//            "password": password // Ensure correct casing ("password" instead of "Password")
//        ]
//
//        // Set headers
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json"
//        ]
//
//        // Make the PATCH request using Alamofire
//        AF.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
//            switch response.result {
//            case .success(let jsonResponse):
//                print("JSON Response: \(jsonResponse)")
//                completion(.success(jsonResponse))
//
//            case .failure(let error):
//                if let httpStatusCode = response.response?.statusCode {
//                    switch httpStatusCode {
//                    case 409:
//                        let errorMessage = "OTP is invalid, please request a new one."
//                        completion(.failure(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
//
//                    default:
//                        let errorResponse = String(data: response.data ?? Data(), encoding: .utf8) ?? "Unknown error"
//                        completion(.failure(NSError(domain: "", code: httpStatusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse])))
//                    }
//                } else {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }

//    func callingLogoutApi(completion: @escaping (Result<Any, Error>) -> Void) {
//        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
//            print("User token not found.")
//            return
//        }
//
//        let url = API.logout_url
//
//        // Set headers
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json",
//            "Authorization": "\(usersToken)"
//        ]
//
//        // Make DELETE request using Alamofire
//        AF.request(url, method: .delete, headers: headers).response { response in
//            // Try to decode the response data, even if the status code is an error
//            if let data = response.data {
//                // Try to convert the data into a JSON object for better readability
//                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
//                    print("Response JSON: \(json)")  // Print the JSON response
//                } else if let responseString = String(data: data, encoding: .utf8) {
//                    print("Response String: \(responseString)")  // Print raw string if it's not valid JSON
//                } else {
//                    print("Received non-decodable response.")
//                }
//            }
//
//            switch response.result {
//            case .success(let jsonResponse):
//                print("JSON Response: \(jsonResponse)")
//                completion(.success(jsonResponse))
//            case .failure(let error):
//                if let httpStatusCode = response.response?.statusCode {
//                    print("Error: HTTP Status Code \(httpStatusCode)")  // Print status code
//                }
//                completion(.failure(error))  // Pass the error to completion
//            }
//        }
//    }
//    func callingDeleteAccountApi(completion: @escaping (Result<Any, Error>) -> Void) {
//        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
//            print("User token not found.")
//            return
//        }
//
//        let url = API.delete_url
//
//        // Set headers
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json",
//            "Authorization": "\(usersToken)"
//        ]
//        print("abhi\(usersToken)")
//
//        // Make DELETE request using Alamofire
//        AF.request(url, method: .delete, headers: headers).response { response in
//            // Try to decode the response data, even if the status code is an error
//            if let data = response.data {
//                // Try to convert the data into a JSON object for better readability
//                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
//                    print("Response JSON: \(json)")  // Print the JSON response
//                } else if let responseString = String(data: data, encoding: .utf8) {
//                    print("Response String: \(responseString)")  // Print raw string if it's not valid JSON
//                } else {
//                    print("Received non-decodable response.")
//                }
//            }
//
//            switch response.result {
//            case .success(let jsonResponse):
//                print("JSON Response: \(jsonResponse)")
//                completion(.success(jsonResponse))
//            case .failure(let error):
//                if let httpStatusCode = response.response?.statusCode {
//                    print("Error: HTTP Status Code \(httpStatusCode)")  // Print status code
//                }
//                completion(.failure(error))  // Pass the error to completion
//            }
//        }
//    }
//    func callingEditProfileApi(first_name: String, last_name: String,  completion: @escaping (Result<Any, Error>) -> Void) {
//        guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
//            print("User token not found.")
//            return
//        }
//
//        let url = API.editprofile_url
//
//        // Prepare the request body with email, OTP, and password
//        let parameters: [String: Any] = [
//            "first_name": first_name,
//            "last_name": last_name
//        ]
//
//        // Set headers
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json",
//            "Authorization": "\(usersToken)"
//        ]
//
//        // Make the PATCH request using Alamofire
//        AF.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
//            switch response.result {
//            case .success(let jsonResponse):
//                print("JSON Response: \(jsonResponse)")
//                completion(.success(jsonResponse))
//
//            case .failure(let error):
//                if let httpStatusCode = response.response?.statusCode {
//                    switch httpStatusCode {
//                    case 409:
//                        let errorMessage = "Enter Valid name..."
//                        completion(.failure(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
//
//                    default:
//                        let errorResponse = String(data: response.data ?? Data(), encoding: .utf8) ?? "Unknown error"
//                        completion(.failure(NSError(domain: "", code: httpStatusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse])))
//                    }
//                } else {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    func callingSubmitAnsApi(id: String, value: Int?, completion: @escaping (Result<Any, Error>) -> Void) {
//        let url = API.submitsurvay_url
//
//        // Fetch the token from UserDefaults
//        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
//            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication token not found."])))
//            return
//        }
//
//        let parameters: [String: Any] = [
//            "Id": id,
//            "value": value ?? NSNull() // Handles nil value by using NSNull
//        ]
//
//        // Set headers including Authorization token
//        let headers: HTTPHeaders = [
//            "Accept": "application/json",
//            "Content-Type": "application/json",
//            "Authorization": "\(token)" // Adding the Bearer token here
//        ]
//
//        // Make the request using Alamofire
//        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
//            .validate(statusCode: 200...299) // Automatically handles 2xx responses
//            .responseJSON { response in
//                switch response.result {
//                case .success(let jsonResponse):
//                    // Handle the successful case
//                    if let jsonResponse = jsonResponse as? [String: Any] {
//                        completion(.success(jsonResponse))
//                    } else {
//                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
//                    }
//
//                case .failure(let error):
//                    // Extract error message based on status code
//                    if let data = response.data {
//                        do {
//                            if let jsonresponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                               let errorMessage = jsonresponse["message"] as? String {
//                                completion(.failure(NSError(domain: "", code: response.response?.statusCode ?? 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
//                            } else {
//                                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
//                                completion(.failure(NSError(domain: "", code: response.response?.statusCode ?? 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
//                            }
//                        } catch {
//                            completion(.failure(error))
//                        }
//                    } else {
//                        // If no error data is available, return the general error
//                        completion(.failure(error))
//                    }
//                }
//            }
//    }
//    func callingGetProfileApi(completion: @escaping (Result<GetProfileModel, Error>) -> Void) {
//        guard let usersToken = UserDefaults.standard.string(forKey: "userToken")else {
//
//            print("User token not found.")
//            return
//        }
//
//        let url = API.getprofile_url
//
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json",
//            "Authorization": "\(usersToken)"
//        ]
//
//        AF.request(url, method: .get, headers: headers).responseData { response in
//            switch response.result {
//            case .success:
//                guard let data = response.data else {
//                    print("No data received.")
//                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
//                    return
//                }
//                // Log raw response data
//                print("Raw Response Data: \(String(decoding: data, as: Unicode.UTF8.self))")
//                // Attempt to decode or print JSON
//                do {
//                    let apiResponse = try JSONDecoder().decode(GetProfileModel.self, from: data)
//                    completion(.success(apiResponse))
//                } catch {
//                    print("JSON Decoding Error: \(error.localizedDescription)")
//                    completion(.failure(error))
//                }
//            case .failure(let error):
//                print("Error: \(error.localizedDescription)")
//                completion(.failure(error))
//            }
//        }
//    }
//func callingGetQuestionApi(completion: @escaping (Result<GetQuestionModel, Error>) -> Void) {
//    guard let usersToken = UserDefaults.standard.string(forKey: "userToken") else {
//        print("User token not found.")
//        return
//    }
//    
//    let url = API.getquestion_url
//    
//    let headers: HTTPHeaders = [
//        "Content-Type": "application/json",
//        "Authorization": "\(usersToken)"
//    ]
//    
//    AF.request(url, method: .get, headers: headers).responseData { response in
//        switch response.result {
//        case .success:
//            guard let data = response.data else {
//                print("No data received.")
//                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
//                return
//            }
//            
//            // Log raw response data
//            //   print("Raw Response Data: \(String(data: data, encoding: .utf8) ?? "Invalid Data")")
//            
//            // Attempt to decode or print JSON
//            do {
//                let apiResponse = try JSONDecoder().decode(GetQuestionModel.self, from: data)
//                completion(.success(apiResponse))
//            } catch {
//                // print("JSON Decoding Error: \(error.localizedDescription)")
//                completion(.failure(error))
//            }
//            
//        case .failure(let error):
//            //   print("Error: \(error.localizedDescription)")
//            completion(.failure(error))
//        }
//    }
//}

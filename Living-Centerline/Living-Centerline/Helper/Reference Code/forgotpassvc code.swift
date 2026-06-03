//
//  forgotpassvc code.swift
//  Living-Centerline
//
//  Created by Developer on 10/10/24.
//

//import Foundation
// continue button
//        guard let email = emailTextField.text else {
//            showAlert("Error", "Please make sure the email field is filled.")
//            return
//        }
//        // Validate email input
//        var errorMessage = ""
//
//        if email.isEmpty {
//            errorMessage = "The email field is required."
//        } else if !Validator.validateEmail(email) {
//            errorMessage = "Please enter a valid email address."
//        }
//
//        // Show error if validation fails
//        if !errorMessage.isEmpty {
//            showAlert("Validation Error", errorMessage)
//            return
//        }
//        ProgressHUD.animate()
//        self.view.isUserInteractionEnabled = false
//
//        // Call the Send OTP API if the email is valid
//        APIManager.shareInstance.callingSendOTPApi(email: email) { result in
//            DispatchQueue.main.async {
//                self.view.isUserInteractionEnabled = true
//            }
//            ProgressHUD.dismiss()
//            switch result {
//            case .success(let response):
//                // Print the response for debugging purposes
//                print("OTP successfully sent, navigating to the next screen.")
//                print(response)
//
//                // Navigate to the next screen on the main thread
//                DispatchQueue.main.async {
//                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                    if let homeScreenVC = storyboard.instantiateViewController(withIdentifier: "OTPVerificationVC") as? OTPVerificationVC {
//                        homeScreenVC.email = email
//                        self.navigationController?.pushViewController(homeScreenVC, animated: true)
//                    }
//                }
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    print("Final \(error)") // This prints the full error for debugging
//
//                    // Extract the error message from the localized description
//                    let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred."
//
//                    // Show the alert with the extracted error message
//                    self.showAlert("OTP Send Failed", errorMessage)
//                }
//            }
//        }

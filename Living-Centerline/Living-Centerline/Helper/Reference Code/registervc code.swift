//
//  registervc code.swift
//  Living-Centerline
//
//  Created by Developer on 10/10/24.
//

//import Foundation
// signup button code
// Unwrapping UITextField values safely
//        guard let firstName = firstNameTextField.text,
//              let lastName = lastNameTextField.text,
//              let email = emailIdTextField.text,
//              let password = passwordTextField.text,
//              let confirmPassword = confirmPasswordTextField.text else {
//            showAlert("Error", "Please make sure all fields are filled.")
//            return
//        }
//        var errorMessage = ""
//        // Check if first name is empty
//        if firstName.isEmpty {
//            errorMessage = "The first name field is required."
//        } else if !Validator.validateFirstName(firstName) {
//            if firstName.rangeOfCharacter(from: CharacterSet.letters.inverted) != nil {
//                errorMessage = "The first name must contain only alphabetic characters."
//            } else if firstName.count < 2 {
//                errorMessage = "The first name must be at least 2 alphabetic characters."
//            }
//        }
//        // If there was an error in first name validation, show it and stop further execution
//        if !errorMessage.isEmpty {
//            showAlert("Validation Error", errorMessage)
//            return
//        }
//        // Check if last name is empty
//        if lastName.isEmpty {
//            errorMessage = "The last name field is required."
//        } else if !Validator.validateLastName(lastName) {
//            if lastName.rangeOfCharacter(from: CharacterSet.letters.inverted) != nil {
//                errorMessage = "The last name must contain only alphabetic characters."
//            } else if lastName.count < 2 {
//                errorMessage = "The last name must be at least 2 alphabetic characters."
//            }
//        }
//        // If there was an error in last name validation, show it and stop further execution
//        if !errorMessage.isEmpty {
//            showAlert("Validation Error", errorMessage)
//            return
//        }
//        // Check if email is empty or invalid
//        if email.isEmpty {
//            errorMessage = "The email address field is required."
//        } else if !Validator.validateEmail(email) {
//            errorMessage = "Please enter a valid email address."
//        }
//
//        // If there was an error in email validation, show it and stop further execution
//        if !errorMessage.isEmpty {
//            showAlert("Validation Error", errorMessage)
//            return
//        }
//        // Check if password is empty or invalid
//        if password.isEmpty {
//            errorMessage = "The password field is required."
//        } else if password.count < 8 {
//            errorMessage = "Password must be at least 8 characters long."
//        }
//        // If there was an error in password validation, show it and stop further execution
//        if !errorMessage.isEmpty {
//            showAlert("Validation Error", errorMessage)
//            return
//        }
//        // Check if confirm password matches
//        if confirmPassword.isEmpty {
//            errorMessage = "The confirm password field is required."
//        } else if password != confirmPassword {
//            errorMessage = "Passwords do not match."
//        }
//        // If there was an error in confirm password validation, show it and stop further execution
//        if !errorMessage.isEmpty {
//            showAlert("Validation Error", errorMessage)
//            return
//        }
//        ProgressHUD.animate()
//        self.view.isUserInteractionEnabled = false
//
//        // If all validations pass, proceed with registration API call
//        let parameters: [String: Any] = [
//            "first_name": firstName,
//            "last_name": lastName,
//            "email": email,
//            "password": password
//        ]
//
//        APIManager.shareInstance.callingRegisterApi(fName: firstName, lName: lastName, email: email, password: password) { Result in
//            DispatchQueue.main.async {
//                ProgressHUD.dismiss()
//                self.view.isUserInteractionEnabled = true
//            }
//            switch Result {
//            case .success(let response):
//                print(response)
//                // Extract the token from the response
//                if let responseDict = response as? [String: Any],
//                   let data = responseDict["data"] as? [String: Any],
//                   let token = data["token"] as? String {
//
//                    // Store the token in UserDefaults
//                    UserDefaults.standard.set(token, forKey: "userToken")
//              //      UserDefaults.standard.synchronize()  // Synchronize to make sure it’s saved immediately
//                    print("Token stored successfully: \(token)")
//                } else {
//                    print("Error: Unable to extract token from response")
//                }
//                // Navigate to the next screen
//                DispatchQueue.main.async {
//                    self.navigateToViewController(withIdentifier: "HomeScreenVC", storyboardName: "HomeSC")
//                }
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    print("Final \(error)") // This prints the full error for debugging
//
//                    // Extract the error message from the localized description
//                    let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred."
//
//                    // Show the alert with the extracted error message
//                    self.showAlert("Signup Failed", errorMessage)
//                }
//            }
//        }

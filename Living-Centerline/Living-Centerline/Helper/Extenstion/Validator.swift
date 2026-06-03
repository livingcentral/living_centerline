//
//  Validator.swift
//  Living-Centerline
//
//  Created by MACMonterio on 18/09/2024.
//

// Validator.swift
import Foundation
class Validator {
    // Validate Email
    static func validateEmail(_ email: String?) -> Bool {
        guard let email = email else { return false }
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    // Validate Password (Minimum length: 6)
    static func validatePassword(_ password: String?) -> Bool {
        guard let password = password else { return false }
        return password.count >= 8
    }
    // Validate Confirm Password (Checks if it matches the original password)
    static func validateConfirmPassword(_ password: String?, confirmPassword: String?) -> Bool {
        guard let password = password, let confirmPassword = confirmPassword else { return false }
        return password == confirmPassword
    }
    static func validateFirstName(_ firstName: String?) -> Bool {
            guard let firstName = firstName else { return false }
            let firstNameRegex = "^[A-Za-z]{2,}$"
            let firstNamePredicate = NSPredicate(format: "SELF MATCHES %@", firstNameRegex)
            return firstNamePredicate.evaluate(with: firstName)
        }
    // Validate Last Name (Only letters, minimum 2 characters)
    static func validateLastName(_ lastName: String?) -> Bool {
        guard let lastName = lastName else { return false }
        let lastNameRegex = "^[A-Za-z]{2,}$"
        let lastNamePredicate = NSPredicate(format: "SELF MATCHES %@", lastNameRegex)
        return lastNamePredicate.evaluate(with: lastName)
    }
}



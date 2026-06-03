//
//  UiDate Formatter Extension.swift
//  Living-Centerline
//
//  Created by Developer on 01/10/24.
//

import UIKit
extension Date {
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
    
}
extension String {
    
    func toTime(withFormat format: String = "HH:mm")-> Date?{
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Calcutta")
        dateFormatter.locale = Locale(identifier: "en-IN")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
    
    func toDate(format: String = "dd/MM/yyyy") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current // Set time zone if necessary
        return dateFormatter.date(from: self)
    }
    
    func dateAfter15Days(dateFormat: String = "dd/MM/yyyy") -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")  // Locale for consistency
        
        // Convert the string to a Date object
        guard let date = dateFormatter.date(from: self) else {
            print("Invalid date format")
            return nil
        }
        
        // Add 15 days to the date
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: 14, to: date) {
            // Convert the new date back to a string in "dd/MM/yyyy" format
            return dateFormatter.string(from: newDate)
        }
        
        return nil
    }
    
    // Function to convert ISO 8601 date string to "dd/MM/yyyy" format
        func convertToDateFormat(_ format: String = "dd/MM/yyyy") -> String? {
            // Create a DateFormatter for the input ISO 8601 date string
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Matching the input format
            inputFormatter.locale = Locale(identifier: "en_US_POSIX") // Ensures correct behavior
            
            // Convert the string to a Date object
            if let date = inputFormatter.date(from: self) {
                // Create a DateFormatter for the output format
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = format
                outputFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                // Convert Date back to the desired string format
                return outputFormatter.string(from: date)
            }
            return nil
        }
    
    func convertDateFormat(inputDate: String) -> String? {
        // Create a date formatter to parse the input date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy" // Define the input format
        
        // Convert the input string to a Date object
        if let date = dateFormatter.date(from: inputDate) {
            // Create a new date formatter for the desired output format
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d MMMM, yyyy" // Desired format: 15 September, 2024
            
            // Convert the Date object back to a string in the desired format
            let outputDate = outputFormatter.string(from: date)
            return outputDate
        } else {
            // Return nil if the input date string is invalid
            return nil
        }
    }
    // Function to compare submission date with a future date (both in dd/MM/yyyy format)
       func isBefore(futureDateString: String, dateFormat: String = "dd/MM/yyyy") -> Bool {
           // Create a DateFormatter to parse the dates
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = dateFormat
           dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Use POSIX for consistent date parsing
           
           // Convert both strings to Date objects
           guard let submissionDate = dateFormatter.date(from: self),
                 let futureDate = dateFormatter.date(from: futureDateString) else {
               // Return false if date parsing fails
               print("Date parsing failed")
               return false
           }
           
           // Compare the two dates
           return submissionDate < futureDate
       }
}
extension Date {
    var dayBefore: Date {
            return Calendar.current.date(byAdding: .day, value: -1, to: self)!
        }
    func toString(withFormat format: String = "dd/MM/yyy") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-IN")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Calcutta")
        dateFormatter.calendar = Calendar(identifier: .persian)
        dateFormatter.dateFormat = format
        let str = dateFormatter.string(from: self)
        return str
    }
}

func convertUTCToLocal(utcDate: Date) -> Date? {
    let localTimeZone = TimeZone.current // Device's Local Time Zone
    let secondsFromGMT = localTimeZone.secondsFromGMT(for: utcDate)
    return Calendar.current.date(byAdding: .second, value: secondsFromGMT, to: utcDate)
}

func convertLocalToUTC(localDate: Date) -> Date? {
    let timeZone = TimeZone(identifier: "UTC") // UTC Time Zone
    let secondsFromGMT = timeZone?.secondsFromGMT(for: localDate) ?? 0
    return Calendar.current.date(byAdding: .second, value: -secondsFromGMT, to: localDate)
}

extension Optional where Wrapped == String {
    func toDateConvert(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> Date? {
        guard let self = self else { return nil } // Safely unwrap optional string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.date(from: self)
    }
}

//
//  TimeIntervalExtension.swift
//  Living-Centerline
//
//  Created by Developer on 03/10/24.
//

import Foundation
extension TimeInterval {
    func toTimeString() -> String {
        // Convert the total seconds into hours, minutes, and seconds
        let hours = Int(self / 3600)
        let minutes = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        
        // If hours are 0, return "No sleep"
        if hours == 0 {
            return "No sleep"
        }
        // Initialize an empty result string
        var result = ""
        // Append hours if they are greater than 0
        if hours > 0 {
            result += "\(hours) hour" + (hours > 1 ? "s " : " ")
        }
        // Append minutes if they are greater than 0
        if minutes > 0 {
            result += "\(minutes) minute" + (minutes > 1 ? "s " : " ")
        }
        // Append seconds if they are greater than 0 and there are no minutes
        if seconds > 0 && minutes == 0 {
            result += "\(seconds) second" + (seconds > 1 ? "s" : "")
        }
        // Return the final string, trimmed to remove any unnecessary spaces
        return result.trimmingCharacters(in: .whitespaces)
    }
}

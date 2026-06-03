//
//  Constant.swift
//  Living-Centerline
//
//  Created by MACMonterio on 19/09/2024.
//
// change file
import Foundation

struct API {
 static let base_url = "https://lcimobile-b264dc803a4b.herokuapp.com/api/v1" // production
//    static let base_url = "https://sbrlzs11-3000.inc1.devtunnels.ms/api/v1"
    static let register_url = "\(base_url)/user/signup"
    static let login_url = "\(base_url)/user/login"
    static let getProfile_url = "\(base_url)/user/get-profile"
    static let sendToPassword_url = "\(base_url)/user/send-forgot-password-otp"
    static let verifyOTPPassword_url = "\(base_url)/user/verify-forgot-password-otp"
    static let forgotPassword_url = "\(base_url)/user/forgot-password"
    static let logout_url = "\(base_url)/user/logout"
    static let delete_url = "\(base_url)/user/delete-account"
    static let editProfile_url = "\(base_url)/user/edit-profile"
    static let getQuestion_url = "\(base_url)/question/get-questions"
   // static let submitQuestions_url = "\(base_url)/question/submit-survey"
    static let submitSurvey_url = "\(base_url)/question/submit-survey"
    static let submitHealthData = "\(base_url)/health/submit-health-data"
    static let lastSyncDate = "\(base_url)/health/get-last-sync-date"
    static let fetchMissingData = "\(base_url)/health/retrieve-missing-health-access-data"
    static let fetchMissingDates = "\(base_url)/health/retrieve-missing-dates"
    static let sendLog = "\(base_url)/user/track-app-logs"
    // for testing purpose
    static let isTestingOn = false
}

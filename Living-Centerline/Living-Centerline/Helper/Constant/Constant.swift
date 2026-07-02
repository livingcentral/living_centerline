//
//  Constant.swift
//  Living-Centerline
//
//  Created by MACMonterio on 19/09/2024.
//
// change file
import Foundation

#if SCREENSHOT_FIXTURES
enum ScreenshotScreen: String {
    case home
    case survey
    case settings
    case login
}

struct AppConfig {
    static var screenshotScreen: ScreenshotScreen {
        guard let screenName = launchArgumentValue(for: "-LCIScreenshotScreen"),
              let screen = ScreenshotScreen(rawValue: screenName.lowercased()) else {
            return .home
        }
        return screen
    }

    private static func launchArgumentValue(for key: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let keyIndex = arguments.firstIndex(of: key),
              arguments.indices.contains(keyIndex + 1) else {
            return nil
        }
        return arguments[keyIndex + 1]
    }
}

struct MockData {
    static let token = "mock-token-james-t-kirk"

    private static let defaultScale = ScaleDetails(options: [
        Option(text: "Never", value: 1),
        Option(text: "Rarely", value: 2),
        Option(text: "Sometimes", value: 3),
        Option(text: "Often", value: 4),
        Option(text: "Almost always", value: 5)
    ])

    static let profile = GetProfileModel(
        success: true,
        message: "Mock profile loaded",
        data: UserProfileData(
            firstName: "James T.",
            lastName: "Kirk",
            email: "james.kirk@example.test",
            submissionDate: "2026-06-24T12:00:00.000+0000",
            token: token
        )
    )

    static let questions = GetQuestionModel(
        success: true,
        message: "Mock questions loaded",
        data: [
            GetQuestionData(
                _id: "mock-apr-001",
                text: "How connected and supported have you felt in your closest relationships this week?",
                sequence: 1,
                scaleDetails: defaultScale,
                selectedValue: "Often"
            ),
            GetQuestionData(
                _id: "mock-who-001",
                text: "How often have you felt calm, rested, and emotionally steady this week?",
                sequence: 2,
                scaleDetails: defaultScale,
                selectedValue: "Sometimes"
            ),
            GetQuestionData(
                _id: "mock-aaq-001",
                text: "When difficult thoughts showed up, how well were you able to keep moving toward what matters?",
                sequence: 3,
                scaleDetails: defaultScale,
                selectedValue: "Often"
            ),
            GetQuestionData(
                _id: "mock-fin-001",
                text: "How confident do you feel about your current cash flow and short-term financial resilience?",
                sequence: 4,
                scaleDetails: defaultScale,
                selectedValue: "Sometimes"
            )
        ]
    )

    static let selectedOptions: [String: Int] = [
        "mock-apr-001": 4,
        "mock-who-001": 3
    ]

    static func seedUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "userToken")
        defaults.set(questions.data.count, forKey: "questionCount")
        defaults.set(selectedOptions, forKey: "selectedOptions")

        if let encodedQuestions = try? JSONEncoder().encode(questions.data) {
            defaults.set(encodedQuestions, forKey: "questionData")
        }
    }
}
#endif

struct API {
 static let base_url = "https://lcimobile-b264dc803a4b.herokuapp.com/api/v1" // production
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
#if SCREENSHOT_FIXTURES
    static let isTestingOn = true
#else
    static let isTestingOn = false
#endif
}

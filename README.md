# Living Centerline iOS App

This repository contains the iOS client for Living Centerline. It is a UIKit/Storyboard Swift app that handles user login, profile management, wellness surveys, HealthKit collection, local health-sync tracking, and upload of health and survey data to the mobile API.

The main Xcode project is nested under `Living-Centerline/`.

## Related Repositories

In the same parent folder there are two related Node/Mongo repositories:

- `../lciback-stage` - web/dashboard API for client records, wellness engineer login, recommendations, notes, financial data, charts, and batch seed endpoints.
- `../lcidaily` - daily worker that reads mobile health/survey data and updates the LCI dashboard database with Body, Mind, Financial, Overall, recommendation, score, and trend values.

This iOS app does not call `lciback-stage` directly. Its API constants point to the mobile backend:

```swift
https://lcimobile-b264dc803a4b.herokuapp.com/api/v1
```

## What Is Here

- `Living-Centerline.xcodeproj` - Xcode project and shared scheme.
- `Living-Centerline/App` - app and scene delegates, notification handling, keyboard manager setup, and launch wiring.
- `Living-Centerline/Storyboard` - login/signup and home/survey/settings storyboards.
- `Living-Centerline/Living Centerline/Controller` - view controllers for authentication, survey flow, home, next survey, and settings.
- `Living-Centerline/Living Centerline/Model` - Codable models for auth, profile, survey, HealthKit, health sync, and API responses.
- `Living-Centerline/Manager/APIManager` - central HTTP API calls.
- `Living-Centerline/Manager/HealthManager` - HealthKit authorization and retrieval for steps, sleep, HRV, resting heart rate, active energy, resting energy, and log submission.
- `Living-Centerline/Manager/HealthSyncManager` - Core Data backed sync tracking.
- `Living-Centerline/Helper` - constants, common UI helpers, extensions, and reference/old code.
- `HealthSyncModel.xcdatamodeld` - Core Data model for health sync state.
- `Resource/Assets.xcassets` and `Resource/Font` - app images, icons, app icon, and SF Pro display fonts.

## Main User Flows

- Authentication: signup, login, forgot password, OTP verification, password reset, logout, delete account.
- Profile: fetch and edit user profile.
- Survey: retrieve questions, render options, submit survey answers.
- HealthKit: request authorization, collect supported Apple Health data, merge per-day records, submit health payloads, and retrieve missing-date sync state from the server.
- Home/settings: display next survey date, sync state, profile settings, and account actions.
- Logging: app logs are queued locally and posted to the mobile API.

## API Configuration

API endpoints are defined in:

```text
Living-Centerline/Living-Centerline/Helper/Constant/Constant.swift
```

Important constants:

- `API.base_url` - currently production Heroku mobile API.
- `API.isTestingOn` - `true` only when the app is compiled with `SCREENSHOT_FIXTURES`; otherwise `false`.

The app expects the mobile backend to expose:

- `/user/signup`
- `/user/login`
- `/user/get-profile`
- `/user/send-forgot-password-otp`
- `/user/verify-forgot-password-otp`
- `/user/forgot-password`
- `/user/logout`
- `/user/delete-account`
- `/user/edit-profile`
- `/question/get-questions`
- `/question/submit-survey`
- `/health/submit-health-data`
- `/health/get-last-sync-date`
- `/health/retrieve-missing-health-access-data`
- `/health/retrieve-missing-dates`
- `/user/track-app-logs`

## Build Configurations

The app currently has three Xcode build configurations:

- `Release` - production-only behavior. It does not compile screenshot fixtures, fixture data, internal environment selectors, or screenshot routing.
- `Debug` - developer build behavior against the configured production mobile API. It does not compile screenshot fixtures.
- `Screenshot` - simulator screenshot build. It defines `SCREENSHOT_FIXTURES`, compiles local fixture data, bypasses network/HealthKit where needed, and supports deterministic startup screens.

In `Screenshot` builds, select a startup screen with:

```bash
-LCIScreenshotScreen login
-LCIScreenshotScreen home
-LCIScreenshotScreen survey
-LCIScreenshotScreen settings
```

The screenshot fixture currently represents:

```text
Name: James T. Kirk
Displayed name: James T. Kirk
Email: james.kirk@example.test
Token: mock-token-james-t-kirk
Last survey submission: 2026-06-24T12:00:00.000+0000
Question fixture count: 4
Preselected answers: 2 of 4
```

In `Screenshot`, the app seeds `UserDefaults`, returns local profile/question data, treats health data as available, and accepts survey/profile/logout/delete/log calls without using the network. This code is excluded from normal `Debug` and `Release` builds.

## Dependencies

Swift Package Manager dependencies are pinned in `Package.resolved`:

- `IQKeyboardManager` 6.5.0
- `ProgressHUD` 14.1.3

The project also uses Apple frameworks including UIKit, UserNotifications, HealthKit, and Core Data.

## Build And Run

1. Open `Living-Centerline/Living-Centerline.xcodeproj` in Xcode.
2. Select the `Living-Centerline` scheme.
3. Use a real iPhone for HealthKit testing. The iOS Simulator has limited HealthKit behavior and may not contain representative health data.
4. Confirm signing settings:
   - Bundle identifier: `com.looseimpediment.CenterLine`
   - Team currently configured in the project: `ZXVDFU2WXR`
   - Deployment target: iOS 15.0
5. Build and run.

## GitHub Simulator Screenshots

The GitHub Actions workflow builds the simulator app with the `Screenshot` configuration, boots a temporary iPhone simulator, launches each fixture screen, and uploads screenshots as the `living-centerline-simulator` artifact.

Current screenshots:

- `login.png`
- `home.png`
- `survey.png`
- `settings.png`

## Appetize Upload

The iOS workflow can also upload the simulator `.app` build to Appetize on pushes to `main` or manual `workflow_dispatch` runs. Pull requests do not upload to Appetize.

Configure these GitHub Actions repository secrets under:

```text
Settings -> Secrets and variables -> Actions -> Repository secrets
```

- `APPETIZE_API_KEY` - required. Appetize REST API token.
- `APPETIZE_PUBLIC_KEY` - optional for the first run. After the first successful upload, copy the `publicKey` printed in the Actions log into this secret so later runs update the same Appetize app.

The uploaded simulator app uses the existing iOS bundle and version metadata:

```text
Bundle identifier: com.looseimpediment.CenterLine
Version: 1.0
Build: 29
```

## HealthKit And Entitlements

HealthKit is enabled in:

```text
Living-Centerline/Living-Centerline/Living-Centerline.entitlements
```

Health usage strings are set through Xcode build settings in the project file:

- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`
- `NSHealthClinicalHealthRecordsShareUsageDescription`

If HealthKit authorization fails, check signing, entitlements, device capability, and the Health app data available for the test account.

## Known Issues And Security Review Items

- The Xcode project previously contained obfuscated shell script build settings that decoded to `curl ... | sh` commands against external `.ru` domains, including `figmacat.ru`, `trinitysol.ru`, and `windsecure.ru`. Those malicious entries have been removed on the `fix/issue-1-remove-malware-build-script` branch; still treat any machine that built earlier revisions as potentially compromised.
- Several `xcuserdata` files are committed under the Xcode project. These are user-specific IDE state files and normally do not belong in source control.
- Some controller files contain hard-coded test values for emails/passwords or form fields. Review before production builds.
- `Helper/Reference Code` contains old and experimental code. It is useful context, but do not assume it is active app behavior.
- API base URLs are hard-coded in Swift rather than provided by build configuration.

## New Developer Orientation

Start in this order:

1. Read `Constant.swift` to understand which backend this app is talking to.
2. Read `APIManager.swift` to see request/response shapes.
3. Read `HomeScreenVC.swift` and `HealthKitManager.swift` together; most sync behavior crosses those files.
4. Read the `Model/HealthData` and `Model/HealthSync` folders to understand the payloads and local sync state.
5. Review the two related backend READMEs in `../lciback-stage` and `../lcidaily` to understand where dashboard scoring and daily processing happen after mobile data is uploaded.

//
//  NextSurveyVC.swift
//  Living-Centerline
//
//  Created by MACMonterio on 19/09/2024.
//

import UIKit
import ProgressHUD

class NextSurveyVC: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var healthStatusImageView: UIImageView!
    @IBOutlet weak var settingButton: UIButton!
    // UI label
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var healthStatusLabel: UILabel!
   
    // MARK: Properties
    var dueDate = ""
    var isDataAvailable = false
    private let healthKitManager = HealthKitManager()
    // model array
    var stepsDataArray = [StepDataModel]()
    //var heartDataArray = [HeartDataModel]()
    //var hourlyData = [HourModel]()
    var sleepDataArray = [SleepPhaseModel]()
    var healthData = [HealthDateModel]()
    var hrvDataArray = [HRVDataModel]()
    var restingHeartDataArray = [RestingHeartDataModel]()
    var activeEnergyDataArray = [ActiveEnergyModel]()
    var userData = [UserProfileData]()
    // Dispatch group
    let dispatchGroup = DispatchGroup()
    // MARK: View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            configureUI()
        }
    }
    
    @objc func willEnterForeground() {
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                configureUI()
            }
            if userToken == "" {
                navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configureUI () {
        let screenHeight = self.view.frame.height
        let fontScaleFactor = screenHeight / 812
        welcomeLabel.font = UIFont(name: "SFProDisplay-Regular", size: 12 * fontScaleFactor)
        usernameLabel.font = UIFont(name: "SFProDisplay-Medium", size: 16 * fontScaleFactor)
        settingButton.isUserInteractionEnabled = true
        guard let userName = userData.first else { return }
        usernameLabel.text = "\(userName.firstName) \(userName.lastName)"
        dueDateLabel.text = dueDate
        requestHealthKitAuthorization()
    }
    // MARK: - request authorization
    private func requestHealthKitAuthorization() {
#if SCREENSHOT_FIXTURES
        if API.isTestingOn {
            isDataAvailable = true
            validatingHealthData()
            return
        }
#endif

        ProgressHUD.animate()
        dispatchGroup.enter()
        healthKitManager.requestHealthKitAuthorization { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let healthData):
                // Check if health data is available
                guard let healthData2 = healthData.first else {
                    validatingHealthData()
                    return
                }
                
                if healthData2.totalSleep == nil &&
                    healthData2.activeCalorieBurned == nil &&
                    healthData2.hrv == nil &&
                    healthData2.restingHeartRate == nil {
                    
                } else {
                }
                validatingHealthData()
                
                // Update health data property
                self.healthData = healthData
                print("healthdata count \(healthData.count)")
                
            case .failure(let error):
                // Handle the error case
                validatingHealthData()
                print("Failed to fetch health data: \(error.localizedDescription)")
            }
        }

//        healthKitManager.requestHealthKitAuthorization { [weak self] healthData in
//            guard let self else { return }
//            self.healthData = healthData
//            print("healthdata count \(healthData.count)")
//            if healthData.count > 0 {
//                isDataAvailable = true
//                validatingHealthData()
//            } else {
//                isDataAvailable = false
//                validatingHealthData()
//            }
//        }
    }
    // MARK: - validate health data
    private func validatingHealthData() {
        if isDataAvailable {
            //print("Permission Granted to Access step count, sleep data and heart rate")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.updateUI(isInteraction: false,
                              buttonImageName: "app.icn.right",
                         authorizationText: "Collecting Health Data")
            }
        } else {
            cleanUpHealthData()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.updateUI(isInteraction: true,
                              buttonImageName: "app.icn.wrong",
                         authorizationText: "Health data collection not authorized")
                self.healthStatusLabel.text = "Authorize health data collection"
                self.showAlert("Authorization Denied", "You have denied access to health data. Please allow access in Settings to fetch health data.")
            }
            print("Permission Denied to Access step count, sleep data and heart rate")
            // handleAuthorizationDenial()
        }
        settingButton.isUserInteractionEnabled = true
    }
    // MARK: - merge all health data
    private func updateUI(isInteraction: Bool, buttonImageName: String, authorizationText: String) {
        self.healthStatusLabel.isUserInteractionEnabled = isInteraction
        healthStatusImageView.image = UIImage(named: buttonImageName)
        self.healthStatusLabel.text = authorizationText
        ProgressHUD.dismiss()
    }
    
    private func cleanUpHealthData() {
        healthData.removeAll()
        stepsDataArray.removeAll()
        hrvDataArray.removeAll()
        activeEnergyDataArray.removeAll()
        sleepDataArray.removeAll()
        restingHeartDataArray.removeAll()
        //self.hourlyData.removeAll()
    }
    // MARK: button actions
    @IBAction func settingBtnPressed(_ sender: UIButton) {
//        let storyboard = UIStoryboard(name: "HomeSC", bundle: nil)
//        if userData.count == 0 {
//            if let Settingsc = storyboard.instantiateViewController(withIdentifier: "SettingVC") as? SettingVC {
//                Settingsc.isProfileDataAvailable = false
//                self.navigationController?.pushViewController(Settingsc, animated: true)
//            }
//        }
//        else {
//            if let Settingsc = storyboard.instantiateViewController(withIdentifier: "SettingVC") as? SettingVC {
//                Settingsc.firstName = userData.first?.firstName ?? ""
//                Settingsc.lastName = userData.first?.lastName ?? ""
//                Settingsc.email = userData.first?.email ?? ""
//                Settingsc.isProfileDataAvailable = true
//                self.navigationController?.pushViewController(Settingsc, animated: true)
//            }
//        }
    }
}

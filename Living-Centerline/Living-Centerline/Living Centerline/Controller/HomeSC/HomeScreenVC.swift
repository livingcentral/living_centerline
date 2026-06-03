import UIKit
import HealthKit
import ProgressHUD
import CoreData

class HomeScreenVC: UIViewController, SendIsSurveyDoneValueDelegate, HealthSyncDelegate {
    
    // MARK: - Outlets
    @IBOutlet var settingBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var wrongBtn: UIButton!
    // UI Label
    @IBOutlet var authoriseHealthLabel: UILabel!
    @IBOutlet weak var questionCountLabel: UILabel!
    @IBOutlet var questionCompletedLabel: UILabel!
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet weak var nextSurveyDueLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var daysToGoLabel: UILabel!
    // UI View
    @IBOutlet weak var dueDateView: UIView!
    @IBOutlet weak var updateScreenView: UIView!
    @IBOutlet weak var healthDataStatusView: UIView!
    // UI ImageView
    @IBOutlet weak var backgroundImageView: UIImageView!
    // MARK: - Properties
    private var dueDate = ""
    private var isHideDueView = false
    private var firstName = ""
    private var lastName = ""
    private var submissionDate = ""
    private var email = ""
    private var token = ""
    private var myUserToken = ""
    private var isHealthDataAvailable = false
    private var healthSyncManager = HealthSyncManager()
    private let healthKitManager = HealthKitManager()
    // model array
    private var healthData = [HealthDateModel]()
    // Profile Data
    private var profileData = [GetProfileModel]()
    private var userData = [UserProfileData]()
    // Dispatch group
    private let dispatchGroup = DispatchGroup()
    // Core Data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //Singleton instance
    var context:NSManagedObjectContext!
    // User defaults
    let defaults = UserDefaults.standard
    var lastSyncDate = Date()
    var missingHealthData = [DataClass]()
    var missingHealthDates = [String]()
    var updatedHealthData = [HealthDateModel]()
    var updatedHealthIndex = [Int]()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        whereIsMySQLite()
        //configureUI()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
    }
    
    func getlastSyncDate() {
        LogManager.shared.addLog(data: "#Home get last sync date api call")
        sendLogData()
        APIManager.shareInstance.getLastSyncDate { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                LogManager.shared.addLog(data: "#Home \(response)")
                sendLogData()
                let lastSyncDate = response.lastSyncDate as String
                print(lastSyncDate)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                guard let myDate = dateFormatter.date(from: lastSyncDate) else {
                    print("date could not be converted from string to Date")
                    return
                }
                healthSyncManager.delegate = self
                healthSyncManager.saveData(isSync: true, lastSyncDate: myDate)
                healthSyncManager.openDatabase(isSave: false, lastSyncDate: myDate)
            case .failure(let error):
                LogManager.shared.addLog(data: "#Home \(error)")
                sendLogData()
                print(error.localizedDescription)
                print("New user found send 30 days data")
                let testDate = getDate(forDaysAgo: 30) //lastSyncDate
                
                healthSyncManager.delegate = self
                healthSyncManager.saveData(isSync: true, lastSyncDate: testDate)
                healthSyncManager.openDatabase(isSave: false, lastSyncDate: lastSyncDate)
            }
        }
    }
    
    func getDate(forDaysAgo daysAgo: Int) -> Date {
        
        let calendar = Calendar.current
        guard let calculatedDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
            LogManager.shared.addLog(data: "#Home getDate Failed to calculate the date")
            sendLogData()
            fatalError("Failed to calculate the date")
        }
        LogManager.shared.addLog(data: "#Home get previous date \(calculatedDate)")
        return calculatedDate
    }
    
    private func updateTitleLabel(titleName: String, buttonTitle: String) {
        questionCompletedLabel.text = titleName
       // nextSurveyDueLabel.text = titleName
        nextBtn.setTitle(buttonTitle, for: .normal)
    }
    
    @objc func willEnterForeground() {
        if self.viewIfLoaded?.window != nil {
            // viewController is visible
            if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    configureUI()
                    LogManager.shared.addLog(data: "#Home will enter forground called")
                    sendLogData()
                }
                if userToken == "" {
                    LogManager.shared.addLog(data: "#Home will enter forground pop to root")
                    sendLogData()
                    navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    deinit {
        LogManager.shared.addLog(data: "#Home remove observer")
        sendLogData()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI()
    }
    
    private func configureUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let savedOptions = UserDefaults.standard.dictionary(forKey: "selectedOptions") as? [String: Int] {
                updateTitleLabel(titleName: "Health Survey in Progress", buttonTitle: "Resume Now")
                let savedValue = UserDefaults.standard.integer(forKey: "questionCount")
                questionCountLabel.text = "\(savedOptions.count) out of \(savedValue)"
                questionCountLabel.isHidden = false
                if savedOptions.count == 14 {
                    updateTitleLabel(titleName: "Next Health Survey On", buttonTitle: "Next")
                    questionCountLabel.isHidden = true
                }
            } else {
                updateTitleLabel(titleName: "Welcome to Your Health Survey", buttonTitle: "Start Now")
               // questionCountLabel.text = "0 out of 14"
                questionCountLabel.isHidden = true
            }
            uiButtonStatsChange(btnStatus: false)
            uiSetup()
            updateScreenView.isHidden = true
            nextBtn.isHidden = true
            healthDataStatusView.isHidden = true
        }
        
        //retrieveSleepDataForWeek()
        if let userName = usernameLabel.text {
            if userName == "" {
                LogManager.shared.addLog(data: "#Home configureUI - username is empty")
                sendLogData()
                fetchProfileData()
                print("update profile data")
                
            } else {
                LogManager.shared.addLog(data: "#Home configureUI - no need to update profile data")
                sendLogData()
                print("no need to update profile data")
            }
        }
        cleanUpHealthData()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            requestHealthKitAuthorization()
        }
    }
    
    private func dueDateViewVisibleStatus(isVisible: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
          //  nextSurveyDueLabel.isHidden = isVisible ? true : false
            dueDateView.isHidden = isVisible ? true : false
            dueDateLabel.text = dueDate
            backgroundImageView.image = isVisible ? UIImage(named: "app.img.Listimg") : UIImage(named: "app.img.nextsurway")
            questionCompletedLabel.isHidden = false
           // questionCountLabel.isHidden = isVisible ? false : true
            nextBtn.isHidden = isVisible ? false : true
            if dueDateView.isHidden == false {
                updateTitleLabel(titleName: "Next Health Survey On", buttonTitle: "Next")
                questionCountLabel.isHidden = true
            }
        }
    }
    
    private func uiButtonStatsChange(btnStatus: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.settingBtn.isUserInteractionEnabled = btnStatus
            self.nextBtn.isUserInteractionEnabled = btnStatus
            //  ProgressHUD.dismiss()
        }
    }
    
    private func addLabelTapGesture() {
        let labelTapGesture = UITapGestureRecognizer(target : self, action : #selector(self.navigateToPermissionScreen))
        authoriseHealthLabel.addGestureRecognizer(labelTapGesture)
        authoriseHealthLabel.isUserInteractionEnabled = false
    }
    
    func updateIsSurveyDone(isSurveyDone: Bool) {
        print("survey submitted status is \(isSurveyDone)")
        LogManager.shared.addLog(data: "#Home survey submitted status is \(isSurveyDone)")
        sendLogData()
        if isSurveyDone {
            fetchProfileData()
        }
    }
    
    func whereIsMySQLite() {
        LogManager.shared.addLog(data: "#Home screen loaded")
        sendLogData()
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let path = NSPersistentContainer
            .defaultDirectoryURL()
            .absoluteString
            .replacingOccurrences(of: "file://", with: "")
            .removingPercentEncoding
        
        print(path ?? "Not found")
        // MARK: - notification set time
        appDelegate.scheduleNotification(notificationType: "Local Notification with Action", notificationHour: 09, notificationMinute: 00)
        appDelegate.notificationCenter.delegate = self
        UNUserNotificationCenter.current().delegate = self
        //        if API.isTestingOn {
        //            appDelegate.scheduleNotification(notificationType: "Local Notification with Action", notificationHour: 11, notificationMinute: 40)
        //            appDelegate.notificationCenter.delegate = self
        //            UNUserNotificationCenter.current().delegate = self
        //        } else {
        //
        //        }
    }
    
    private func uiSetup() {
        let screenHeight = self.view.frame.height
        let fontScaleFactor = screenHeight / 812
        welcomeLabel.font = UIFont(name: "SFProDisplay-Regular", size: 12 * fontScaleFactor)
        usernameLabel.font = UIFont(name: "SFProDisplay-Medium", size: 16 * fontScaleFactor)
//        questionCompletedLabel.font = UIFont(name: "SFProDisplay-Medium", size: 17 * fontScaleFactor)
        questionCompletedLabel.font = UIFont(name: "SFProDisplay-Bold", size: 20 * fontScaleFactor)
        questionCountLabel.font = UIFont(name: "SFProDisplay-Bold", size: 28 * fontScaleFactor)
        authoriseHealthLabel.font = UIFont(name: "SFProDisplay-Medium", size: 15 * fontScaleFactor)
        nextBtn.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 15 * fontScaleFactor)
        let buttonCornerRadius = 40 * fontScaleFactor
        settingBtn.layer.cornerRadius = buttonCornerRadius / 2
        settingBtn.layer.masksToBounds = true
        // Set initial text for the label
        authoriseHealthLabel.text = "Authorize health data collection"
        addLabelTapGesture()
    }
    
    @objc func navigateToPermissionScreen() {
        guard let settingsUrl = URL(string: "App-prefs:HEALTH&path=SOURCES") else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    // MARK: - request authorisation method
    private func requestHealthKitAuthorization() {
        LogManager.shared.addLog(data: "#Home fetching health data for permission check")
        
        ProgressHUD.animate("Fetching Health data")
        dispatchGroup.enter()
        defaults.set(30, forKey: "numberOfHealthData")
        
        healthKitManager.requestHealthKitAuthorization { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let healthData):
                // Check if health data is available
                for i in 0..<healthData.count {
                    //                    guard let healthData2 = healthData[i] else {
                    //                        isHealthDataAvailable = false
                    //                        validatingHealthData()
                    //                        return
                    //                    }
                    if healthData[i].totalSleep != nil ||
                        healthData[i].activeCalorieBurned != nil ||
                        healthData[i].hrv != nil ||
                        healthData[i].restingHeartRate != nil ||
                        healthData[i].awakeTime != nil ||
                        healthData[i].restingEnergy != nil ||
                        healthData[i].totalSteps != nil {
                        isHealthDataAvailable = true
                        LogManager.shared.addLog(data: "#Home success health data for permission check \n \(healthData)")
                        
                        self.healthData = healthData
                        print("healthdata count \(healthData.count)")
                        // Update health data property
                        //  print(healthData[i])
                        break
                    } else {
                        LogManager.shared.addLog(data: "#Home failed to fetch health data for permission check")
                        isHealthDataAvailable = false
                        ProgressHUD.dismiss()
                    }
                }
                
            case .failure(let error):
                LogManager.shared.addLog(data: "#Home failed to fetch health data for permission check \(error)")
                // Handle the error case
                isHealthDataAvailable = false
                print("Failed to fetch health data: \(error.localizedDescription)")
            }
            validatingHealthData()
        }
    }
    
    private func cleanUpHealthData() {
        healthData.removeAll()
    }
    // MARK: - validate health data
    private func validatingHealthData() {
        LogManager.shared.addLog(data: "#Home validate health data called")
        //  ProgressHUD.animate()
        if isHealthDataAvailable {
            //print("Permission Granted to Access step count, sleep data and heart rate")
            //mergeAllHealthData()
            LogManager.shared.addLog(data: "#Home yes health data available")
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.updateUI(isInteraction: false,
                              buttonImageName: "app.icn.right",
                              authorisationText: "Collecting Health Data")
                // healthSyncManager.openDatabse(isSave: false, lastSyncDate: lastSyncDate)
            }
            sendLogData()
            getlastSyncDate()
        } else {
            LogManager.shared.addLog(data: "#Home no health data available")
            cleanUpHealthData()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.updateUI(isInteraction: true,
                              buttonImageName: "app.icn.wrong",
                              authorisationText: "Health data collection not authorised")
                self.showAlert("Authorisation Denied", "You have denied access to health data. Please allow access in Settings to fetch health data.")
                self.authoriseHealthLabel.text = "Authorise health data collection"
            }
            print("Permission Denied to Access step count, sleep data and heart rate")
            // handleAuthorizationDenial()
        }
        sendLogData()
        animateHiddenView(viewName: updateScreenView)
        animateHiddenView(viewName: nextBtn)
        animateHiddenView(viewName: healthDataStatusView)
        
        self.uiButtonStatsChange(btnStatus: true)
        //        updateScreenView.isHidden = false
        //        nextBtn.isHidden = false
        //        healthDataStatusView.isHidden = false
    }
    
    private func animateHiddenView(viewName: UIView) {
        UIView.transition(with: viewName, duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if viewName == nextBtn {
                    viewName.isHidden = isHideDueView ? false : true
                } else {
                    viewName.isHidden = false
                }
            }
        })
    }
    
    func fetchMissingHealthData() {
        LogManager.shared.addLog(data: "#Home get get missng health dates api")
        sendLogData()
        APIManager.shareInstance.getMissingHealthData { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let healthData):
                LogManager.shared.addLog(data: "#Home \(healthData)")
                sendLogData()
                missingHealthData = healthData
                //   let tempData = healthData
                
                updateMissingHealthData()
            case.failure(let error):
                LogManager.shared.addLog(data: "#Home \(error)")
                sendLogData()
                print("Error fetching missing health data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert("Error", "Failed to get missing health dates from server.")
                }
            }
        }
    }
    
    private func updateMissingHealthData() {
        LogManager.shared.addLog(data: "#Home update missing health data")
        sendLogData()
        updatedHealthIndex.removeAll()
        if !missingHealthData.isEmpty {
            for i in 0..<missingHealthData.count {
                let fetchDate = missingHealthData[i].date
                //            let stepsDate = convertStringToDate(missingHealthData[i].totalSteps?.dateWithTimeStamp)
                //            let totalSleepDate = convertStringToDate(missingHealthData[i].totalSleep?.dateWithTimeStamp)
                //            let remSleepDate = convertStringToDate(missingHealthData[i].remSleep?.dateWithTimeStamp)
                //            let coreSleepDate = convertStringToDate(missingHealthData[i].coreSleep?.dateWithTimeStamp)
                //            let deepSleepDate = convertStringToDate(missingHealthData[i].deepSleep?.dateWithTimeStamp)
                //            let awakeTimeDate = convertStringToDate(missingHealthData[i].awakeTime?.dateWithTimeStamp)
                //            let activeCalorieDate = convertStringToDate(missingHealthData[i].activeCalorieBurned?.dateWithTimeStamp)
                //            let restingEnergyDate = convertStringToDate(missingHealthData[i].restingEnergy?.dateWithTimeStamp)
                //            let restingHeartDate = convertStringToDate(missingHealthData[i].restingHeartRate?.dateWithTimeStamp)
                //            let hrvDate = convertStringToDate(missingHealthData[i].hrv?.dateWithTimeStamp)
                if missingHealthData[i].totalSteps == nil {
                    // if let stepsDate = stepsDate {
                    let fetchSteps = getTotalSteps(forDate: fetchDate, from: healthData) ?? (0, "")
                    var updatedTotalSteps = missingHealthData[i]
                    
                    if fetchSteps == (0 , "") {
                        print("total steps device data already nil")
                    } else {
                        updatedTotalSteps.totalSteps = (MySteps(dateWithTimeStamp: fetchSteps.1, totalSteps: fetchSteps.0))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedTotalSteps
                        //  print(missingHealthData[i])
                        print("total steps updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
                if missingHealthData[i].totalSleep == nil {
                    //   if let totalSleepDate = totalSleepDate {
                    let fetchTotalSleep = getTotalSleep(forDate: fetchDate, from: healthData) ?? (0, "")
                    var updatedTotalSleep = missingHealthData[i]
                    
                    if fetchTotalSleep == (0 , "") {
                        print("total sleep device data already nil")
                    } else {
                        updatedTotalSleep.totalSleep = (MyTotalSleep(dateWithTimeStamp: fetchTotalSleep.1, totalSleep: Double(Int(fetchTotalSleep.0))))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedTotalSleep
                        // print(missingHealthData[i])
                        print("total sleep updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
                if missingHealthData[i].remSleep == nil {
                    //if let remSleepDate = remSleepDate {
                    let fetchRemSleep = getRemSleep(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedRemSleep = missingHealthData[i]
                    
                    if fetchRemSleep == (0 , "") {
                        print("rem sleep device data already nil")
                    } else {
                        updatedRemSleep.remSleep = (MyRemSleep(dateWithTimeStamp: fetchRemSleep.1, remSleep: Double(Int(fetchRemSleep.0))))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedRemSleep
                        //  print(missingHealthData[i])
                        print("rem sleep updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    //}
                }
                if missingHealthData[i].coreSleep == nil {
                    // if let coreSleepDate = coreSleepDate {
                    let fetchCoreSleep = getCoreSleep(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedCoreSleep = missingHealthData[i]
                    
                    if fetchCoreSleep == (0 , "") {
                        print("core sleep device datais already nil")
                        
                    } else {
                        updatedCoreSleep.coreSleep = (MyCoreSleep(dateWithTimeStamp: fetchCoreSleep.1, coreSleep: Double(Int(fetchCoreSleep.0))))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedCoreSleep
                        // print(missingHealthData[i])
                        print("core sleep updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    //}
                }
                if missingHealthData[i].deepSleep == nil {
                    //  if let deepSleepDate = deepSleepDate {
                    let fetchDeepSleep = getDeepSleep(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedDeepSleep = missingHealthData[i]
                    
                    if fetchDeepSleep == (0 , "") {
                        print("deep sleep device data already nil")
                    } else {
                        updatedDeepSleep.deepSleep = (MyDeepSleep(dateWithTimeStamp: fetchDeepSleep.1, deepSleep: Double(Int(fetchDeepSleep.0))))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedDeepSleep
                        //  print(missingHealthData[i])
                        print("deep sleep updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
                if missingHealthData[i].awakeTime == nil {
                    // if let awakeTimeDate = awakeTimeDate {
                    let fetchawakeTime = getAwakeTime(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedAwakeTime = missingHealthData[i]
                    
                    if fetchawakeTime == (0 , "") {
                        print("awake time device data already nil")
                    } else {
                        updatedAwakeTime.awakeTime = (MyAwakeTime(dateWithTimeStamp: fetchawakeTime.1, awakeTime: Double(Int(fetchawakeTime.0))))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedAwakeTime
                        //  print(missingHealthData[i])
                        print("awake time updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
                if missingHealthData[i].activeCalorieBurned == nil {
                    //   if let activeCalorieDate = activeCalorieDate {
                    let fetchActiveCalorie = getActiveCalorie(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedActiveCalorie = missingHealthData[i]
                    
                    if fetchActiveCalorie == (0 , "") {
                        print("active calorie data already nil")
                    } else {
                        updatedActiveCalorie.activeCalorieBurned = (MyActiveEnergyValue(activeEnergy: fetchActiveCalorie.0, dateWithTimeStamp: fetchActiveCalorie.1))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedActiveCalorie
                        // print(missingHealthData[i])
                        print("active calorie updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
                if missingHealthData[i].restingEnergy == nil {
                    //  if let restingEnergyDate = restingEnergyDate {
                    let fetchRestingEnergy = getRestingEnergy(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedRestingEnergy = missingHealthData[i]
                    
                    if fetchRestingEnergy == (0 , "") {
                        print("resting energy data already nil")
                    } else {
                        updatedRestingEnergy.restingEnergy = (MyRestingEnergyValue(restingEnergy: fetchRestingEnergy.0, dateWithTimeStamp: fetchRestingEnergy.1))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedRestingEnergy
                        //   print(missingHealthData[i])
                        print("resting energy updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
                if missingHealthData[i].restingHeartRate == nil {
                    //   if let restingHeartDate = restingHeartDate {
                    let fetchRestingHeartRate = getRestingHeartRate(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedRestingHeartRate = missingHealthData[i]
                    
                    if fetchRestingHeartRate == (0 , "") {
                        print("resting heart data already nil")
                    } else {
                        updatedRestingHeartRate.restingHeartRate = (MyRestingHeartValue(heartValue: fetchRestingHeartRate.0, dateWithTimeStamp: fetchRestingHeartRate.1))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedRestingHeartRate
                        // print(missingHealthData[i])
                        print("resting heart updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
                if missingHealthData[i].hrv == nil {
                    // if let hrvDate = hrvDate {
                    let fetchHRV = getHRV(forDate: fetchDate, from: healthData) ?? (0 , "")
                    var updatedHRV = missingHealthData[i]
                    
                    if fetchHRV == (0 , "") {
                        print("hrv data already nil")
                    } else {
                        updatedHRV.hrv = (MyHRVValue(hrvValue: fetchHRV.0, dateWithTimeStamp: fetchHRV.1))
                        //   _ = (fetchCoreSleep.0 != 0) ? updatedCoreSleep.coreSleep?.coreSleep = fetchCoreSleep.0 :
                        //  _ = (fetchCoreSleep.1 != "") ? updatedCoreSleep.coreSleep?.dateWithTimeStamp = fetchCoreSleep.1 :
                        missingHealthData[i] = updatedHRV
                        // print(missingHealthData[i])
                        print("hrv updated")
                        updatedHealthIndex.appendIfNotExists(i)
                    }
                    // }
                }
            }
            updateMissingData()
            prepareMissingData()
        } else {
            print("data are already updated on server")
            LogManager.shared.addLog(data: "#Home data are already updated on server")
            sendLogData()
        }
        // print(missingHealthData)
    }
    
    private func getMissingHealthData() {
        var fetchMissingData = [HealthDateModel]()
        if healthData.count == 30 {
            for index in 0..<missingHealthDates.count {
                let dateInString = missingHealthDates[index]
                
                // Convert the date string into a Date object (yyyy/MM/dd format)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd"
                guard let targetDate = dateFormatter.date(from: dateInString) else {
                    print("Invalid date format for \(dateInString)")
                    continue
                }
                
                // Now search for the corresponding date in the healthData array
                let matchingHealthData = healthData.filter { healthRecord in
                    // Convert the healthRecord's date to just yyyy/MM/dd format (stripping out time)
                    let healthDateFormatter = DateFormatter()
                    healthDateFormatter.dateFormat = "yyyy/MM/dd"
                    let healthRecordDateString = healthDateFormatter.string(from: healthRecord.date)
                    
                    // Compare the formatted strings, not the full Date objects
                    return healthDateFormatter.string(from: targetDate) == healthRecordDateString
                }
                
                // Now you have the health data for the matching date(s)
                if let record = matchingHealthData.first {
                    // Found the health data for this date, now you can work with `record`
                    print("Found health data for \(dateInString): \(record)")
                    fetchMissingData.append(record)
                    // Do something with the `record` here, like storing or processing it
                } else {
                    // No data found for this date
                    print("No health data found for \(dateInString)")
                }
            }
            print("retrieval success")
            if fetchMissingData.count == missingHealthDates.count && fetchMissingData.count > 0 {
                print("send health data")
                sendMissingHealthData(updatedHealthData: fetchMissingData)
            } else {
                print("failed to get missing health dates data")
            }
        } else {
            print("health data count is not 30 fetch health data")
            requestHealthKitAuthorization()
        }
    }
    
    private func fetchMissingDates() {
        APIManager.shareInstance.getMissingHealthDates { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let missingDates):
                LogManager.shared.addLog(data: "#Home \(missingDates)")
                sendLogData()
                missingHealthDates = missingDates.missingDates
                //   let tempData = healthData
                
                getMissingHealthData()
            case.failure(let error):
                LogManager.shared.addLog(data: "#Home \(error)")
                sendLogData()
                print("Error fetching missing health dates: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert("Error", "Failed to get missing health dates from server.")
                }
            }
        }
    }
    private func prepareMissingData() {
        
        if updatedHealthData.count > 0 {
            sendHealthData()
            LogManager.shared.addLog(data: "#Home missing health data are updated and sent to the server")
            
            print("health data request sent")
        } else {
            LogManager.shared.addLog(data: "#Home data are already updated on server")
            print("health data is missing in device.can't update device on server.")
            fetchMissingDates()
        }
        sendLogData()
    }
    
    private func updateMissingData() {
        LogManager.shared.addLog(data: "#Home update missing data")
        
        for index in updatedHealthIndex {
            var totalSteps: TotalSteps?
            var totalSleep: TotalSleep?
            var remSleep: RemSleep?
            var coreSleep: CoreSleep?
            var deepSleep: DeepSleep?
            var awakeTime: AwakeTime?
            var activeCalorie: ActiveEnergyValue?
            var restingEnergy: RestingEnergyValue?
            var restingHeart: RestingHeartValue?
            var HRV: HRVValue?
            
            let myDate = missingHealthData[index].date
            // Steps data
            let stepsEntry = missingHealthData[index].totalSteps
            if let myStepDate = missingHealthData[index].totalSteps?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myStepData = missingHealthData[index].totalSteps?.totalSteps ?? 0
                let mySteps = TotalSteps(dateWithTimeStamp: myStepDate, totalSteps: myStepData)
                let emptySteps = TotalSteps(dateWithTimeStamp: Date(), totalSteps: 0)
                totalSteps = (stepsEntry == nil) ? nil : mySteps //?? emptySteps
            } else {
                print("can't convert steps date")
            }
            
            // Total sleep data
            let totalSleepEntry = missingHealthData[index].totalSleep
            if let myTotalSleepDate = missingHealthData[index].totalSleep?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myTotalSleepData = missingHealthData[index].totalSleep?.totalSleep ?? 0
                let myTotalSleep = TotalSleep(dateWithTimeStamp: myTotalSleepDate, totalSleep: Double(myTotalSleepData))
                let emptyTotalSleep = TotalSleep(dateWithTimeStamp: Date(), totalSleep: 0)
                totalSleep = (totalSleepEntry == nil) ? nil : myTotalSleep //?? emptyTotalSleep
            } else {
                print("can't convert total sleep date")
            }
            
            // REM sleep data
            let remSleepEntry = missingHealthData[index].remSleep
            if let myRemSleepDate = missingHealthData[index].remSleep?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myRemSleepData = missingHealthData[index].remSleep?.remSleep ?? 0
                let myRemSleep = RemSleep(dateWithTimeStamp: myRemSleepDate, remSleep: Double(myRemSleepData))
                let emptyRemSleep = RemSleep(dateWithTimeStamp: Date(), remSleep: 0)
                remSleep = (remSleepEntry == nil) ? nil : myRemSleep //?? emptyRemSleep
            } else {
                print("can't convert REM sleep date")
            }
            
            // Core sleep data
            let coreSleepEntry = missingHealthData[index].coreSleep
            if let myCoreSleepDate = missingHealthData[index].coreSleep?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myCoreSleepData = missingHealthData[index].coreSleep?.coreSleep ?? 0
                let myCoreSleep = CoreSleep(dateWithTimeStamp: myCoreSleepDate, coreSleep: Double(myCoreSleepData))
                let emptyCoreSleep = CoreSleep(dateWithTimeStamp: Date(), coreSleep: 0)
                coreSleep = (coreSleepEntry == nil) ? nil : myCoreSleep //?? emptyCoreSleep
            } else {
                print("can't convert core sleep date")
            }
            
            // Deep sleep data
            let deepSleepEntry = missingHealthData[index].deepSleep
            if let myDeepSleepDate = missingHealthData[index].deepSleep?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myDeepSleepData = missingHealthData[index].deepSleep?.deepSleep ?? 0
                let myDeepSleep = DeepSleep(dateWithTimeStamp: myDeepSleepDate, deepSleep: Double(myDeepSleepData))
                let emptyDeepSleep = DeepSleep(dateWithTimeStamp: Date(), deepSleep: 0)
                deepSleep = (deepSleepEntry == nil) ? nil : myDeepSleep //?? emptyDeepSleep
            } else {
                print("can't convert deep sleep date")
            }
            
            // Awake time data
            let awakeTimeEntry = missingHealthData[index].awakeTime
            if let myAwakeTimeDate = missingHealthData[index].awakeTime?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myAwakeTimeData = missingHealthData[index].awakeTime?.awakeTime ?? 0
                let myAwakeTime = AwakeTime(dateWithTimeStamp: myAwakeTimeDate, awakeTime: Double(myAwakeTimeData))
                let emptyAwakeTime = AwakeTime(dateWithTimeStamp: Date(), awakeTime: 0)
                awakeTime = (awakeTimeEntry == nil) ? nil : myAwakeTime //?? emptyAwakeTime
            } else {
                print("can't convert awake time date")
            }
            
            // Active calorie data
            let activeCalorieEntry = missingHealthData[index].activeCalorieBurned
            if let myActiveCalorieDate = missingHealthData[index].activeCalorieBurned?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myActiveCalorieData = missingHealthData[index].activeCalorieBurned?.activeEnergy ?? 0
                let myActiveCalorie = ActiveEnergyValue(activeEnergy: myActiveCalorieData, dateWithTimeStamp: myActiveCalorieDate)
                let emptyActiveCalorie = ActiveEnergyValue(activeEnergy: 0, dateWithTimeStamp: Date())
                activeCalorie = (activeCalorieEntry == nil) ? nil : myActiveCalorie //?? emptyActiveCalorie
            } else {
                print("can't convert active calorie date")
            }
            
            // Resting energy data
            let restingEnergyEntry = missingHealthData[index].restingEnergy
            if let myRestingEnergyDate = missingHealthData[index].restingEnergy?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myRestingEnergyData = missingHealthData[index].restingEnergy?.restingEnergy ?? 0
                let myRestingEnergy = RestingEnergyValue(restingEnergy: myRestingEnergyData, dateWithTimeStamp: myRestingEnergyDate)
                let emptyRestingEnergy = RestingEnergyValue(restingEnergy: 0, dateWithTimeStamp: Date())
                restingEnergy = (restingEnergyEntry == nil) ? nil : myRestingEnergy //?? emptyRestingEnergy
            } else {
                print("can't convert resting energy date")
            }
            
            // Resting heart data
            let restingHeartEntry = missingHealthData[index].restingHeartRate
            if let myRestingHeartDate = missingHealthData[index].restingHeartRate?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myRestingHeartData = missingHealthData[index].restingHeartRate?.heartValue ?? 0
                let myRestingHeart = RestingHeartValue(heartValue: myRestingHeartData, dateWithTimeStamp: myRestingHeartDate)
                let emptyRestingHeart = RestingHeartValue(heartValue: 0, dateWithTimeStamp: Date())
                restingHeart = (restingHeartEntry == nil) ? nil : myRestingHeart //?? emptyRestingHeart
            } else {
                print("can't convert resting heart date")
            }
            
            // HRV data
            let hrvEntry = missingHealthData[index].hrv
            if let myHRVDate = missingHealthData[index].hrv?.dateWithTimeStamp.toDate(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
                let myHRVData = missingHealthData[index].hrv?.hrvValue ?? 0
                let myHRV = HRVValue(hrvValue: myHRVData, dateWithTimeStamp: myHRVDate)
                let emptyHRV = HRVValue(hrvValue: 0, dateWithTimeStamp: Date())
                HRV = (hrvEntry == nil) ? nil : myHRV // emptyHRV
            } else {
                print("can't convert HRV date")
            }
            updatedHealthData.append(HealthDateModel(date: myDate, totalSteps: totalSteps, totalSleep: totalSleep, remSleep: remSleep, coreSleep: coreSleep, deepSleep: deepSleep, awakeTime: awakeTime, activeCalorieBurned: activeCalorie,restingEnergy: restingEnergy , restingHeartRate: restingHeart, hrv: HRV))
            // updatedHealthData.append(missingHealthData[index])
        }
        sendLogData()
    }
    
    private func sendHealthData() {
        LogManager.shared.addLog(data: "#Home post health data APi called")
        sendLogData()
        ProgressHUD.animate("Syncing with server")
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            APIManager.shareInstance.postHealthData(token: userToken, url: API.submitHealthData, healthData: updatedHealthData) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let success):
                    LogManager.shared.addLog(data: "#Home post health data success")
                    sendLogData()
                    if success {
                        print(result)
                        ProgressHUD.succeed("Data Sync Completed.", delay: 2.5)
                        print("health Data updated successfully")
                        defaults.set(0, forKey: "numberOfHealthData")
                        //  self.healthData.removeAll()
                        //  ProgressHUD.dismiss()
                        fetchMissingDates()
                    }
                case .failure(let error):
                    LogManager.shared.addLog(data: "#Home \(error)")
                    sendLogData()
                    ProgressHUD.failed("Error uploading the data", delay: 1.5)
                    ProgressHUD.colorBackground = .red
                    print("Failed to send health data: \(error.localizedDescription)")
                }
            }
            //Api.postHealthData(token: userToken, url: API.submitHealthData)
        }
    }
    
    private func sendMissingHealthData(updatedHealthData: [HealthDateModel]) {
        LogManager.shared.addLog(data: "#Home post health data APi called")
        sendLogData()
        ProgressHUD.animate("Syncing with server")
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            APIManager.shareInstance.postHealthData(token: userToken, url: API.submitHealthData, healthData: updatedHealthData) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let success):
                    LogManager.shared.addLog(data: "#Home post health data success")
                    sendLogData()
                    if success {
                        print(result)
                        ProgressHUD.succeed("Missing Data Sync Completed.", delay: 2.5)
                        print("health Data added successfully")
                        defaults.set(0, forKey: "numberOfHealthData")
                        //  self.healthData.removeAll()
                        //  ProgressHUD.dismiss()
                    }
                case .failure(let error):
                    LogManager.shared.addLog(data: "#Home \(error)")
                    sendLogData()
                    ProgressHUD.failed("Error uploading the data", delay: 1.5)
                    ProgressHUD.colorBackground = .red
                    print("Failed to send health data: \(error.localizedDescription)")
                }
            }
            //Api.postHealthData(token: userToken, url: API.submitHealthData)
        }
    }
    
    func convertStringToDate(_ dateString: String?) -> Date? {
        LogManager.shared.addLog(data: "#Home convert string to data")
        guard let dateString = dateString else {
            return nil  // If the string is nil, return nil
        }
        
        // Define the date formats you expect
        let dateFormatter = ISO8601DateFormatter()
        
        // Try to parse the date
        if let date = dateFormatter.date(from: dateString) {
            return date  // Return the parsed date
        } else {
            // If ISO8601 fails, try a different format (e.g., if the format changes)
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Modify the format as per your requirement
            
            if let customDate = customFormatter.date(from: dateString) {
                return customDate
            }
        }
        sendLogData()
        return nil  // Return nil if both formats fail
    }
    
    private func checkSubmissionDate() {
        LogManager.shared.addLog(data: "#Home check submission date")
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            if myUserToken == userToken {
                print("intact survey data")
                LogManager.shared.addLog(data: "#Home intact survey data")
                
            } else {
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "questionData")
                defaults.removeObject(forKey: "selectedOptions")
                print("removed user data")
                LogManager.shared.addLog(data: "#Home remove user data")
            }
        }
        sendLogData()
        let submissionDate = submissionDate.convertToDateFormat("dd/MM/yyyy") ?? ""
        let futureDate = submissionDate.dateAfter15Days() ?? ""
        if  submissionDate == "" && !(submissionDate.isBefore(futureDateString: futureDate)) {
            LogManager.shared.addLog(data: "#Home submission date empty")
            isHideDueView = true
            dueDateViewVisibleStatus(isVisible: isHideDueView)
            //  ProgressHUD.dismiss()
        } else {
            LogManager.shared.addLog(data: "#Home submission date not empty")
            guard let dueDate = submissionDate.dateAfter15Days() else { return }
            if let formattedDate = dueDate.convertDateFormat(inputDate: dueDate) {
                print(formattedDate) // Output: 15 September, 2024
                self.dueDate = formattedDate
                //   ProgressHUD.dismiss()
                
            } else {
                print("Invalid date format")
                // ProgressHUD.dismiss()
            }
            sendLogData()
            let currentDate = getCurrentDate()
            if let days2 = numberOfDaysBetween(startDate: currentDate, endDate: futureDate) {
                print("remaining days \(days2)")
                LogManager.shared.addLog(data: "#Home remaining days \(days2)")
                if days2 <= 0 {
                    print("days are already passed show survey")
                    LogManager.shared.addLog(data: "#Home days are already passed show survey")
                    isHideDueView = true
                    dueDateViewVisibleStatus(isVisible: isHideDueView)
                    //  ProgressHUD.dismiss()
                    
                } else if days2 >= 1 {
                    daysToGoLabel.text = "\(days2) Days to go"
                    LogManager.shared.addLog(data: "#Home \(days2) Days to go")
                    isHideDueView = false
                    dueDateViewVisibleStatus(isVisible: isHideDueView)
                    //   ProgressHUD.dismiss()
                    
                } else {
                    print("submission date is incorrect")
                }
                sendLogData()
            }
            //            if let days = numberOfDaysBetween(startDate: currentDate, endDate: futureDate) {
            //                daysToGoLabel.text = days >= 1 ? "\(days) Days to go" : "\(days) Day to go"
            //            } else {
            //                print("no days in submission and future date")
            //            }
            //            isHideDueView = false
            //            dueDateViewVisibleStatus(isVisible: isHideDueView)
            //            ProgressHUD.dismiss()
        }
    }
    // Function to calculate the number of days between two dates
    func numberOfDaysBetween(startDate: String, endDate: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy" // Define the input date format
        
        // Convert input strings to Date objects
        if let start = dateFormatter.date(from: startDate), let end = dateFormatter.date(from: endDate) {
            let calendar = Calendar.current
            // Calculate the number of days between the two dates
            let components = calendar.dateComponents([.day], from: start, to: end)
            if let days = components.day {
                return days - 1 // Exclude the start and end date by subtracting 1
            } else {
                return nil
            }
        } else {
            // Return nil if either of the dates is invalid
            return nil
        }
    }
    
    func getCurrentDate() -> String {
        let currentDate = Date() // Get the current date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy" // Set the desired date format
        return dateFormatter.string(from: currentDate)
    }
    
    private func updateUI(isInteraction: Bool, buttonImageName: String, authorisationText: String) {
        self.authoriseHealthLabel.isUserInteractionEnabled = isInteraction
        self.wrongBtn.setImage(UIImage(named: buttonImageName), for: .normal)
        self.authoriseHealthLabel.text = authorisationText
        //ProgressHUD.dismiss()
    }
    // MARK: fetch profile data
    private func fetchProfileData() {
        LogManager.shared.addLog(data: "#setting calling get profile api")
        sendLogData()
        dispatchGroup.enter()
        APIManager.shareInstance.callingGetProfileApi { [weak self] result in
            guard let self else { return }
            dispatchGroup.leave()
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true  // Re-enable interactions
                if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
                    self.myUserToken = userToken
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                switch result {
                case .success(let profileResponse):
                    LogManager.shared.addLog(data: "#setting \(profileResponse)")
                    sendLogData()
                    let profileData = profileResponse.data
                    self.usernameLabel.text = "\(profileData.firstName) \(profileData.lastName)"
                    self.firstName = profileData.firstName
                    self.lastName = profileData.lastName
                    self.submissionDate = profileData.submissionDate ?? ""
                    self.email = profileData.email
                    self.token = profileData.token ?? ""
                    DispatchQueue.main.async {
                        self.userData.append(UserProfileData(firstName: self.firstName, lastName: self.lastName, email: self.email, submissionDate: self.submissionDate, token: self.token))
                        print(self.submissionDate)
                        self.checkSubmissionDate()
                    }
                case .failure(let error):
                    LogManager.shared.addLog(data: "#setting \(error)")
                    sendLogData()
                    print("Error fetching profile: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert("Error", "Failed to load profile data.")
                    }
                }
            }
        }
    }
    // MARK: - button actions
    @IBAction func settingButtonPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "HomeSC", bundle: nil)
        if userData.count == 0 {
            LogManager.shared.addLog(data: "#setting setting btn tapped when user data is empty")
            sendLogData()
            if let settingVC = storyboard.instantiateViewController(withIdentifier: "SettingVC") as? SettingVC {
                settingVC.isProfileDataAvailable = false
                self.navigationController?.pushViewController(settingVC, animated: true)
            }
        }
        else {
            LogManager.shared.addLog(data: "#setting setting btn tapped when user data is available")
            sendLogData()
            if let settingVC = storyboard.instantiateViewController(withIdentifier: "SettingVC") as? SettingVC {
                settingVC.firstName = userData.first?.firstName ?? ""
                settingVC.lastName = userData.first?.lastName ?? ""
                settingVC.email = userData.first?.email ?? ""
                settingVC.isProfileDataAvailable = true
                self.navigationController?.pushViewController(settingVC, animated: true)
            }
        }
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#homeScreen next btn tapped")
        sendLogData()
        if let vc = UIStoryboard.init(name: "HomeSC", bundle: Bundle.main).instantiateViewController(withIdentifier: "QuizVC") as? SurveyQuizVC {
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
        //navigateToViewController(withIdentifier: "QuizVC", storyboardName: "HomeSC")
    }
}

extension HomeScreenVC: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle foreground presentation options
        print("Notification received in foreground: \(notification.request.content.body)")
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle user interaction with the notification
        switch response.actionIdentifier {
        case "snoozeAction":
            print("Snooze action tapped")
            LogManager.shared.addLog(data: "#Home snooze tapped")
            sendLogData()
            // Add snooze handling logic here
            UIApplication.shared.applicationIconBadgeNumber = 0
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            break
        default:
            print("Default action tapped")
            LogManager.shared.addLog(data: "#Home default tapped")
            sendLogData()
            UIApplication.shared.applicationIconBadgeNumber = 0
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            break
        }
        // Call completion handler to let the system know the response is handled
        completionHandler()
    }
}
extension HomeScreenVC {
    
    private func sendLogData() {
        LogManager.shared.sendLogsToServer() { result in
            switch result {
            case .success(let value):
                print("Successfully sent log data from home screen: \(value)")
            case .failure(let error):
                print("Error sending log data from home screen: \(error)")
            }
        }
    }
}

import UIKit
import ProgressHUD

protocol SendQuestionValueDelegate {
    func updateSelectedValue(questionId: String, selectedValue: String, answerValue: Int)
}
protocol SendIsSurveyDoneValueDelegate {
    func updateIsSurveyDone(isSurveyDone: Bool)
}

class SurveyQuizVC: UIViewController, SendQuestionValueDelegate {
    
    // MARK: Outlets
    // UI label
    @IBOutlet var questionCount: UILabel!
    @IBOutlet var questionLabel: UILabel!
    @IBOutlet var youAskLabel: UILabel!
    @IBOutlet var questionCountLabel: UILabel!
    // UI button
    @IBOutlet var backBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var saveForLaterBtn: UIButton!
    @IBOutlet var saveAndSubmitBtn: UIButton!
    // Progress View
    @IBOutlet var progressView: UIProgressView!
    // UI Collection View
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    var selectedOptions: [String: Int] = [:]  // Dictionary to store selected option for each question with _id as key
    // var OptionData = [Option]()
    private var currentQuestionIndex = 0
    private var loadOptions = [Bool]()
    //private var isZeroBased = false
    private var isDataAvailable = false
    private var isHealthDataUploaded = false
    private var isSurveyDataUploaded = false
    private let healthKitManager = HealthKitManager()
    // model array
    private var questionData = [GetQuestionData]()
    private var stepsDataArray = [StepDataModel]()
    //var heartDataArray = [HeartDataModel]()
    //var hourlyData = [HourModel]()
    private var sleepDataArray = [SleepPhaseModel]()
    private var healthData = [HealthDateModel]()
    private var hrvDataArray = [HRVDataModel]()
    private var restingHeartDataArray = [RestingHeartDataModel]()
    private var activeEnergyDataArray = [ActiveEnergyModel]()
    var delegate: SendIsSurveyDoneValueDelegate?
    // Dispatch group
    let dispatchGroup = DispatchGroup()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        tableViewSetup()
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
    
    // MARK: - Public methods
    
    func updateSelectedValue(questionId: String, selectedValue: String, answerValue: Int) {
        // ProgressHUD.animate()
        // Loop through the questionData array to find the question with the matching questionId
        // print("got data from table \(questionId) is and value is \(selectedValue)")
        selectedOptions[questionId] = answerValue
        saveSelectedOptions()
        if let index = questionData.firstIndex(where: { $0._id == questionId }) {
            // Update the selectedValue for the found question
            questionData[index].selectedValue = selectedValue
            saveQuestionObject()
            collectionView.reloadData()
            print("answer saved successfully")
            //ProgressHUD.dismiss()
        } else {
            //  print("Question with ID \(questionId) not found")
            //ProgressHUD.dismiss()
        }
    }
    
    // MARK: - Private methods
    
    private func tableViewSetup() {
        LogManager.shared.addLog(data: "#SurveyQuiz loaded")
        sendLogData()
        collectionView.register(UINib(nibName: QuestionCell.identifier, bundle: nil), forCellWithReuseIdentifier: QuestionCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.frame = view.frame.insetBy(dx: -20.0, dy: 0.0)
    }
    
    private func configureUI() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        let screenHeight = self.view.frame.height
        let fontScaleFactor = screenHeight / 812
        
        youAskLabel.font = UIFont(name: "SFProDisplay-Bold", size: 24 * fontScaleFactor)
        questionCountLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        saveForLaterBtn.titleLabel?.font = UIFont(name: "SFProDisplay-Medium", size: 15 * fontScaleFactor)
        saveAndSubmitBtn.titleLabel?.font = UIFont(name: "SFProDisplay-Medium", size: 15 * fontScaleFactor)
        saveForLaterBtn.layer.borderColor = UIColor(red: 0xEE/255.0, green: 0xF0/255.0, blue: 0xF2/255.0, alpha: 1.0).cgColor
        backBtn.layer.cornerRadius = (screenHeight * 44 / 812) / 2
        backBtn.layer.masksToBounds = true
        nextBtn.layer.cornerRadius = (screenHeight * 44 / 812) / 2
        nextBtn.layer.masksToBounds = true
        backBtn.layer.borderColor = UIColor(hex: "#EEF0F2").cgColor
        backBtn.layer.borderWidth = 1.2
        fetchQuestionData()
    }
    
    private func progressBar() {
        let totalQuestions = questionData.count
        guard totalQuestions > 0 else { return }
        let progress = Float(currentQuestionIndex + 1) / Float(totalQuestions)
        UserDefaults.standard.set(questionData.count, forKey: "questionCount")
        progressView.setProgress(progress, animated: true)
    }
    
    private func updateBackAndNextButtonsState() {
        backBtn.isEnabled = currentQuestionIndex > 0
        nextBtn.isEnabled = currentQuestionIndex < questionData.count - 1
    }
    
    private func checkSaveAndSubmitButtonState() {
        if questionData.count == selectedOptions.count {
            saveAndSubmitBtn.isEnabled = true
            saveAndSubmitBtn.backgroundColor = UIColor(hex: "#1682FF")
        } else {
            saveAndSubmitBtn.isEnabled = false
            saveAndSubmitBtn.backgroundColor = .lightGray
        }
    }
    
    // MARK: - Health data retrieval
    private func requestHealthKitAuthorization() {
#if SCREENSHOT_FIXTURES
        if API.isTestingOn {
            isDataAvailable = true
            isHealthDataUploaded = true
            sendSurveyData()
            return
        }
#endif

        ProgressHUD.animate()
        dispatchGroup.enter()
        healthKitManager.requestHealthKitAuthorization { [weak self] result in
            guard let self else { return }
            
            switch result {
                case .success(let healthData) :
                    self.healthData = healthData
                    print("healthdata count \(healthData.count)")
                    if healthData.count > 0 {
                        isDataAvailable = true
                        sendHealthData()
                        dispatchGroup.leave()
                    } else {
                        isDataAvailable = false
                        sendLogData()
                        dispatchGroup.leave()
                    }
                case .failure(let error) :
                    print("Failed to fetch health data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Fetch question data
    private func fetchQuestionData() {
        LogManager.shared.addLog(data: "#SurveyQuiz calling get question api")
        sendLogData()
        ProgressHUD.animate()
        APIManager.shareInstance.callingGetQuestionApi { [weak self] result in
            ProgressHUD.dismiss()
            guard let self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch result {
                    case .success(let questionResponse):
                        LogManager.shared.addLog(data: "#SurveyQuiz \(questionResponse)")
                        sendLogData()
                        var temp = [GetQuestionData]()
                        for data in questionResponse.data {
                            let options = data.scaleDetails.options.sorted { $0.value < $1.value }
                            let scaleData = ScaleDetails(options: options)
                            temp.append(GetQuestionData(_id: data._id, text: data.text, sequence: data.sequence, scaleDetails: scaleData, selectedValue: ""))
                        }
                        self.loadQuestionData()
                        if self.questionData.count > 0 {
                            print("data already present load data")
                        } else {
                            self.questionData = temp
                        }
                        if self.questionData.isEmpty {
                            DispatchQueue.main.async {
                                self.showAlert("Error", "No questions found")
                            }
                            return
                        }
                        self.displayQuestion(at: self.currentQuestionIndex)
                    case .failure(let error):
                        LogManager.shared.addLog(data: "#SurveyQuiz \(error)")
                        sendLogData()
                        print("Error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.loadQuestionData()
                            self.showAlert("Error", "Failed to load Question data")
                        }
                }
            }
        }
    }
    
    // MARK: - load and save options
    private func loadSelectedOptions() {
        // Load selected options from UserDefaults
        if let savedOptions = UserDefaults.standard.dictionary(forKey: "selectedOptions") as? [String: Int] {
            selectedOptions = savedOptions
            print("selected options are loaded \(selectedOptions)")
        }
        checkSaveAndSubmitButtonState()
    }
    
    func saveSelectedOptions() {
        // Save selected options to UserDefaults
        UserDefaults.standard.set(selectedOptions, forKey: "selectedOptions")
        if let savedOptions = UserDefaults.standard.dictionary(forKey: "selectedOptions") as? [String: Int] {
            print("selected options count \(savedOptions.count)")
        }
        saveQuestionObject()
        checkSaveAndSubmitButtonState()
    }
    
    private func saveQuestionObject() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(questionData)
            UserDefaults.standard.set(data, forKey: "questionData")
            print("question data is saved")
        } catch {
            print("Failed to encode question data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - load questions
    func loadQuestionData() {
        if let data = UserDefaults.standard.data(forKey: "questionData") {
            let decoder = JSONDecoder()
            do {
                // Decode the data back into your array of GetQuestionData
                questionData = try decoder.decode([GetQuestionData].self, from: data)
                //                var temp = [GetQuestionData]()
                
                displayQuestion(at: currentQuestionIndex)
                print("Data loaded successfully: \(questionData)")
            } catch {
                print("Failed to decode question data: \(error.localizedDescription)")
            }
        } else {
            print("No data found for key 'questionData'")
        }
    }
    
    private func displayQuestion(at index: Int) {
        guard index >= 0 && index < questionData.count else { return }
        let question = questionData[index]
        let totalQuestions = questionData.count
        
        // Set question label and progress
        questionCountLabel.text = "\(index + 1) / \(totalQuestions)"
        // questionLabel.text = question.text
        questionCount.text = "Q \(index + 1)"
        // Sort the options by value before displaying them
        //OptionData = question.scaleDetails.options.sorted { $0.value < $1.value }
        loadSelectedOptions()
        progressBar()
        // isZeroBased = OptionData.first?.value == 0
        // Now reload the table with the sorted options
        collectionView.reloadData()
        // Update the progress bar
    }
    
    // MARK: button actions
    
    @IBAction func backBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#SurveyQuiz back btn tapped")
        sendLogData()
        isUpdated = true
        popViewController()
    }
    
    @IBAction func saveSubmitBtnPressed(_ sender: UIButton) {
        // requestHealthKitAuthorization()
        LogManager.shared.addLog(data: "#SurveyQuiz save submit btn tapped")
        sendLogData()
        isUpdated = true
        sendSurveyData()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Set background color to blue and title color to white for saveandsbumitBtn
            self.saveAndSubmitBtn.backgroundColor = UIColor(hex: "#1682FF")
            self.saveAndSubmitBtn.setTitleColor(UIColor.white, for: .normal)
            
            // Set background color to white and title color to black for saveforlaterBtn
            self.saveForLaterBtn.backgroundColor = UIColor.white
            self.saveForLaterBtn.setTitleColor(UIColor.black, for: .normal)
            self.saveForLaterBtn.layer.borderColor = UIColor(hex: "#EEF0F2").cgColor
            self.saveForLaterBtn.layer.borderWidth = 1.2
        }
    }
    
    // MARK: - submit health data
    private func sendHealthData() {
        dispatchGroup.enter()
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            APIManager.shareInstance.postHealthData(token: userToken, url: API.submitHealthData, healthData: healthData) { [weak self] result in
                guard let self else { return }
                switch result {
                    case .success(let success):
                        isHealthDataUploaded = true
                        dispatchGroup.leave()
                        if success {
                            print("health Data sent successfully")
                        }
                        sendSurveyData()
                    case .failure(let error):
                        isHealthDataUploaded = true
                        dispatchGroup.leave()
                        print("Failed to send health data: \(error.localizedDescription)")
                        sendSurveyData()
                }
            }
            //Api.postHealthData(token: userToken, url: API.submitHealthData)
        }
    }
    
    private func sendSurveyData() {
        LogManager.shared.addLog(data: "#SurveyQuiz calling Submit All Ans Api")
        sendLogData()
        // Prepare the request payload as an array of dictionaries
        var questions = [[String: Any]]() // Prepare an array of dictionaries for JSON
        
        for (questionId, selectedValue) in self.selectedOptions {
            // Create a question dictionary for each entry
            let question: [String: Any] = [
                "id": questionId,                 // Ensure questionId is a String
                "value": selectedValue as Any     // Use Any to handle nil
            ]
            questions.append(question)
        }
        // Call the API with the entire array of questions
        ProgressHUD.animate()
        dispatchGroup.enter()
        APIManager.shareInstance.callingSubmitAllAnsApi(questions: questions) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
            }
            switch result {
                case .success(let jsonResponse):
                    LogManager.shared.addLog(data: "#SurveyQuiz \(jsonResponse)")
                    sendLogData()
                    print("Success for all questions: \(jsonResponse)")
                    self.delegate?.updateIsSurveyDone(isSurveyDone: true)
                    isSurveyDataUploaded = true
                    self.dispatchGroup.leave()
                    UserDefaults.standard.removeObject(forKey: "questionCount")
                case .failure(let error):
                    LogManager.shared.addLog(data: "#SurveyQuiz \(error)")
                    sendLogData()
                    isSurveyDataUploaded = false
                    print("Failed to submit responses: \(error.localizedDescription)")
                    self.dispatchGroup.leave()
            }
        }
        // Force layout updates
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.saveAndSubmitBtn.layoutIfNeeded()
            self.saveForLaterBtn.layoutIfNeeded()
        }
        dispatchGroup.notify(queue: DispatchQueue.main, execute: { [weak self] in
            guard let self else {
                return
            }
            print("all task finished")
            
            DispatchQueue.main.async {
//                if self.isHealthDataUploaded == true {
//                    self.healthData.removeAll()
//                    self.isHealthDataUploaded = false
//                }
                if self.isSurveyDataUploaded == true {
                    let defaults = UserDefaults.standard
                    defaults.removeObject(forKey: "questionData")
                    defaults.removeObject(forKey: "selectedOptions")
                    print("removed user question data")
                    self.isSurveyDataUploaded = false
                    self.popViewController()
                    // create the alert
                    let alert = UIAlertController(title: "Message", message: "Survey submitted Successfully.", preferredStyle: UIAlertController.Style.alert)
                    
                    // add an action (button)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
                    }))
                    // show the alert
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.showAlert("Error", "Survey answers are not submitted.")
                }
            }
        })
    }
    
    @IBAction func saveForLaterBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#SurveyQuiz save for later tapped")
        sendLogData()
        isUpdated = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Set background color to blue and title color to white for saveforlaterBtn
            self.saveForLaterBtn.backgroundColor = UIColor(hex: "#1682FF")
            self.saveForLaterBtn.setTitleColor(UIColor.white, for: .normal)
            // Set background color to white and title color to black for saveandsbumitBtn
            self.saveAndSubmitBtn.backgroundColor = UIColor.white
            self.saveAndSubmitBtn.setTitleColor(UIColor.black, for: .normal)
            self.saveAndSubmitBtn.layer.borderColor = UIColor(hex: "#EEF0F2").cgColor
            self.saveAndSubmitBtn.layer.borderWidth = 1.2
            // Save options for later
            self.saveSelectedOptions()
            // Force layout updates
            self.saveAndSubmitBtn.layoutIfNeeded()
            self.saveForLaterBtn.layoutIfNeeded()
            popViewController()
        }
    }
    
    @IBAction func nextBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#SurveyQuiz next btn tapped")
        sendLogData()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.nextBtn.backgroundColor = UIColor(hex: "#1682FF")
            self.nextBtn.tintColor = UIColor.white
            self.backBtn.backgroundColor = UIColor.white
            self.backBtn.tintColor = UIColor.gray
            self.backBtn.layer.borderColor = UIColor(hex: "#EEF0F2").cgColor
            self.backBtn.layer.borderWidth = 1.2
            
            self.backBtn.layoutIfNeeded()
            self.nextBtn.layoutIfNeeded()
            //self.collectionView.scrollToNextItem()
        }
        if currentQuestionIndex < questionData.count - 1 {
            currentQuestionIndex += 1 // Move to the next question
            displayQuestion(at: currentQuestionIndex)
            collectionView.scrollToItem(at: IndexPath(item: currentQuestionIndex, section: 0), at: .right, animated: true)
        } else {
            // Optional: Show alert if on the last question
            showAlert("End of Questions", "No more questions available.")
        }
        updateBackAndNextButtonsState()
    }
    
    @IBAction func backQuestionBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#SurveyQuiz back question btn tapped")
        sendLogData()
        isUpdated = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.backBtn.backgroundColor = UIColor(hex: "#1682FF")
            self.backBtn.tintColor = UIColor.white
            
            self.nextBtn.backgroundColor = UIColor.white
            self.nextBtn.tintColor = UIColor.gray
            self.nextBtn.layer.borderColor = UIColor(hex: "#EEF0F2").cgColor
            self.nextBtn.layer.borderWidth = 1.2
            
            self.backBtn.layoutIfNeeded()
            self.nextBtn.layoutIfNeeded()
        }
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1 // Move to the previous question
            displayQuestion(at: currentQuestionIndex)
            collectionView.scrollToItem(at:IndexPath(item: currentQuestionIndex, section: 0), at: .right, animated: true)
            // self.collectionView.scrollToPreviousItem()
        } else {
            // Optional: Show alert if on the first question
            showAlert("First Question", "You are on the first question.")
        }
        updateBackAndNextButtonsState()
    }
}

// MARK: - UICollectionViewDataSource

extension SurveyQuizVC : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return questionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuestionCell.identifier, for: indexPath) as? QuestionCell else {
            return UICollectionViewCell()
        }
        
        let questionObject = questionData[currentQuestionIndex]
        cell.questionNumberLabel.text = " Q\(indexPath.row + 1)."
        cell.questionLabel.text = questionObject.text
        cell.setUpCollectionView(questionIndex: currentQuestionIndex, questionData: questionObject)
        cell.action = { [weak self] optionIndexPath in
            if let questionId = questionObject._id{
                let selectedOption = questionObject.scaleDetails.options[optionIndexPath.row].value
                let savedValue = questionObject.scaleDetails.options[optionIndexPath.row].text
                
                self?.updateSelectedValue(questionId: questionId, selectedValue: savedValue, answerValue: selectedOption)
            } else {
                debugPrint("Unable to save Question data")
            }
        }
        //print("current question index \(currentQuestionIndex)")
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SurveyQuizVC : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}

// MARK: - Send log data to server

extension SurveyQuizVC {
    private func sendLogData() {
        LogManager.shared.sendLogsToServer() { result in
            switch result {
                case .success(let value):
                    print("Successfully sent log data from survey screen: \(value)")
                case .failure(let error):
                    print("Error sending log data from survey screen: \(error)")
            }
        }
    }
}

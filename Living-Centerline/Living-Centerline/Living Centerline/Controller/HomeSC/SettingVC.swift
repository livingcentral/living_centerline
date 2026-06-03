import UIKit
import ProgressHUD

class SettingVC: UIViewController {
    // MARK: - Outlets
    @IBOutlet var deleteAccountLbl: UILabel!
    @IBOutlet var logoutLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var settingLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var shortTextLabel: UILabel!
    // UI textfield
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var firstNameTextField: UITextField!
    // UI View
    @IBOutlet var nameInitialView: UIView!
    // MARK: - Properties
    private var profileData = [GetProfileModel]()
    let healthSyncManager = HealthSyncManager()
    private var originalFirstName: String = ""
    private var originalLastName: String = ""
    var isProfileDataAvailable = false
    var firstName = ""
    var lastName = ""
    var email = ""
    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        ConfigureUI()
        // Add tap gesture recognizers
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkUserData()
    }
    // MARK: methods
    private func checkUserData() {
        if isProfileDataAvailable {
            firstNameTextField.text = firstName
            lastNameTextField.text = lastName
            emailTextField.text = email
            let firstInitial = firstName.prefix(1)
            let lastInitial = lastName.prefix(1)
            self.shortTextLabel.text = "\(firstInitial)\(lastInitial)"
        } else {
            fetchProfileData()
        }
    }
    
    private func ConfigureUI() {
        let screenHeight = self.view.frame.height
        settingLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 16 / 812)
        
        shortTextLabel.font = UIFont(name: "SFProDisplay-Bold", size: screenHeight * 31 / 812)
        firstNameLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 11 / 812)
        lastNameLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 11 / 812)
        emailLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 11 / 812)
        logoutLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 12 / 812)
        deleteAccountLbl.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 12 / 812)
        
        nameInitialView.layer.cornerRadius = (screenHeight * 95 / 812) / 2
        LogManager.shared.addLog(data: "#setting screen loaded")
        sendLogData()
    }
    
    // MARK: - fetch profile data
    private func fetchProfileData() {
        // Show loader before API call
        ProgressHUD.animate()
        self.view.isUserInteractionEnabled = false
        
        APIManager.shareInstance.callingGetProfileApi { [weak self] result in
            guard let self else { return }
            // Hide loader after API call
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
                ProgressHUD.dismiss()
            }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let profileResponse):
                    // Update UI with profile data
                    let profileData = profileResponse.data
                    self.firstNameTextField.text = profileData.firstName
                    self.lastNameTextField.text = profileData.lastName
                    self.emailTextField.text = profileData.email
                    
                    let firstInitial = profileData.firstName.prefix(1)
                    let lastInitial = profileData.lastName.prefix(1)
                    self.shortTextLabel.text = "\(firstInitial)\(lastInitial)"
                    
                case .failure(let error):
                    print("Error fetching profile: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert("Error", "Failed to load profile data.")
                    }
                }
            }
        }
    }
    // MARK: - button actions
    @IBAction func backBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#setting back btn tapped")
        sendLogData()
        popViewController()
    }
    
    @IBAction func logoutBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#setting calling Logout Api")
        sendLogData()
        let alertController = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            // Show loader before API call
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = false
                ProgressHUD.animate()
            }
            // Call the logout API
            APIManager.shareInstance.callingLogoutApi { [weak self] result in
                guard let self else { return }
                // Hide loader after API call
                DispatchQueue.main.async {
                    ProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                }
                switch result {
                case .success(_):
                    LogManager.shared.addLog(data: "#setting logout successful")
                    sendLogData()
                    print("Logout successful!")
                    let defaults = UserDefaults.standard
                    defaults.removeObject(forKey: "userToken")
                    defaults.removeObject(forKey: "questionData")
                    defaults.removeObject(forKey: "selectedOptions")
                    
                    DispatchQueue.main.async {
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            let context = appDelegate.persistentContainer.viewContext
                            self.healthSyncManager.clearCoreData(context: context)
                        }
                        //let storyboard = UIStoryboard(name: "HomeSC", bundle: Bundle.main)
                        if let loginPageVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginPageVC") as? LoginPageVC {
                            UIApplication.shared.setRootVC(loginPageVC)
                        }
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                case .failure(let error):
                    LogManager.shared.addLog(data: "#setting error logging out")
                    sendLogData()
                    print("Logout failed with error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert("Error", "Failed to log out. Please try again.")
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#setting calling delete account Api")
        sendLogData()
        let alertController = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete this account?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            // Show loader before API call
            DispatchQueue.main.async {
                ProgressHUD.animate()
                self.view.isUserInteractionEnabled = false
            }
            APIManager.shareInstance.callingDeleteAccountApi { [weak self] result in
                guard let self else { return }
                // Hide loader after API call
                DispatchQueue.main.async {
                    ProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                }
                switch result {
                case .success(_):
                    LogManager.shared.addLog(data: "#setting delete account successful")
                    sendLogData()
                    print("Delete account successful!")
                    UserDefaults.standard.removeObject(forKey: "userToken")
                    DispatchQueue.main.async {
//                        guard let VC = self.navigationController?.viewControllers.filter({$0.isKind(of: LoginPageVC.self)}).first else {return}
//                        self.navigationController?.popToViewController(VC, animated: true)
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                case .failure(let error):
                    LogManager.shared.addLog(data: "#setting delete account unsuccessful")
                    sendLogData()
                    print("Delete account failed with error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert("Error", "Failed to delete account. Please try again.")
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(yesAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func saveBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#setting save btn tapped")
        sendLogData()
        guard let firstname = firstNameTextField.text,
              let lastname = lastNameTextField.text else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.showAlert("Input Error", "Please enter both first and last names.")
            }
            return
        }
        if firstname == self.firstName && lastname == self.lastName {
            return
        }
        var errorMessage = ""
        // Validate first name
        if firstname.isEmpty {
            errorMessage = "The first name field is required."
        } else if !Validator.validateFirstName(firstname) {
            if firstname.rangeOfCharacter(from: CharacterSet.letters.inverted) != nil {
                LogManager.shared.addLog(data: "#setting The first name must contain only alphabetic characters.")
                errorMessage = "The first name must contain only alphabetic characters."
            } else if firstname.count < 2 {
                LogManager.shared.addLog(data: "#setting The first name must be at least 2 alphabetic characters.")
                errorMessage = "The first name must be at least 2 alphabetic characters."
            }
        }
        // If first name validation failed, show error
        if !errorMessage.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.showAlert("Validation Error", errorMessage)
                }
            }
            return
        }
        // Validate last name
        if lastname.isEmpty {
            errorMessage = "The last name field is required."
        } else if !Validator.validateLastName(lastname) {
            if lastname.rangeOfCharacter(from: CharacterSet.letters.inverted) != nil {
                LogManager.shared.addLog(data: "#setting The last name must contain only alphabetic characters.")
                errorMessage = "The last name must contain only alphabetic characters."
            } else if lastname.count < 2 {
                LogManager.shared.addLog(data: "#setting The last name must be at least 2 alphabetic characters.")
                errorMessage = "The last name must be at least 2 alphabetic characters."
            }
        }
        // If last name validation failed, show error
        if !errorMessage.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.showAlert("Validation Error", errorMessage)
                }
            }
            return
        }
        // Show loader before API call
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.view.isUserInteractionEnabled = false
            ProgressHUD.animate()
        }
        // Call API
        LogManager.shared.addLog(data: "#setting edit profile API called")
        sendLogData()
        APIManager.shareInstance.callingEditProfileApi(first_name: firstname, last_name: lastname) { [weak self] result in
            guard let self else { return }
            // Hide loader after API call
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
            }
            switch result {
            case .success(let response):
                // Extract first initials and display them
                LogManager.shared.addLog(data: "#setting \(response)")
                sendLogData()
                let firstInitial = firstname.prefix(1)
                let lastInitial = lastname.prefix(1)
                print("Success Response: \(response)")
                DispatchQueue.main.async {
                    self.shortTextLabel.text = "\(firstInitial)\(lastInitial)"
                    self.presentAlert(title: "Success", message: "Profile updated successfully.")
                }
                // Update original values after a successful API call
                self.originalFirstName = firstname
                self.originalLastName = lastname
                
            case .failure(let error):
                LogManager.shared.addLog(data: "#setting \(error)")
                sendLogData()
                print("Error Response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Unauthorize User.")
                }
            }
        }
    }
}

extension SettingVC {
    
    private func sendLogData() {
        LogManager.shared.sendLogsToServer() { result in
            switch result {
                case .success(let value):
                print("Successfully sent log data from setting screen: \(value)")
            case .failure(let error):
                print("Error sending log data from setting screen: \(error)")
            }
        }
    }
}

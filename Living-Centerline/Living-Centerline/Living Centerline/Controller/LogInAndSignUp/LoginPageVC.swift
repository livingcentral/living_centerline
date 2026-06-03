import UIKit
import ProgressHUD

class LoginPageVC: UIViewController {
    // MARK: - Outlets
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var forgotPasswordButton: UIButton!
    @IBOutlet var signUpButton: UIButton!
    // UI label
    @IBOutlet var dontHaveAccountLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var passwordLabel: UILabel!
    @IBOutlet var welcomeBackLabel: UILabel!
    @IBOutlet var signInLabel: UILabel!
    // UI TextField
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    // UI View
    @IBOutlet var contentView: UIView!
    // UI imageview
    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var backgroundImageView2: UIImageView!
    @IBOutlet var eyeIconImageView: UIImageView!
    // MARK: - Properties
    private var isPasswordVisible = false
    //private var model = [LogInModel]()
    private var userData = [UserProfileData]()
    private var myUserToken = ""
    
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    let notifications = ["Simple Local Notification",
                         "Local Notification with Action",
                         "Local Notification with Content"]
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        LogManager.shared.addLog(data: "#Login page loaded")
        sendLogData()
        configureUI()
        setupImageTapGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.applyCornerRadius(corners: [.topLeft, .topRight], radius: 20.0)
    }
    // MARK: - UI Configuration
    private func configureUI() {
        if API.isTestingOn {
            developmentData()
//              productionData()
        }
        // Setup Button and View corner radii
        setupViewCorners()
        configureDynamicFonts()
        configureTextFields()

    }
    
    private func setupViewCorners() {
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
        // password secure entry
        passwordTextField.isSecureTextEntry = true
    }
    
    private func configureDynamicFonts() {
        let screenHeight = view.frame.height
        let fontScaleFactor = screenHeight / 812
        signInLabel.font = UIFont(name: "SFProDisplay-Bold", size: 26 * fontScaleFactor)
        welcomeBackLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        emailLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        passwordLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        forgotPasswordButton.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 12 * fontScaleFactor)
        loginButton.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 15 * fontScaleFactor)
        dontHaveAccountLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        signUpButton.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 12 * fontScaleFactor)
    }
    
    private func configureTextFields() {
        let screenHeight = view.frame.height
        emailTextField.setPlaceholder("Enter your email", fontName: "SFProDisplay-Medium", size: screenHeight * 14 / 812)
        passwordTextField.setPlaceholder("Enter your password", fontName: "SFProDisplay-Medium", size: screenHeight * 14 / 812)
    }
    // MARK: - Button Actions
    @IBAction func forgotPasswordBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#Login forogt password tapped from login")
        sendLogData()
        navigateToViewController(withIdentifier: "FergotPasswordVC")
    }
    
    @IBAction func SignUpBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#Login signup tapped from login")
        sendLogData()
        navigateToViewController(withIdentifier: "RegisterPageVC")
    }
    
    @IBAction func loginBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#Login login tapped from login")
        sendLogData()
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespaces),
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespaces) else {
            showAlert("Error", "Please make sure all fields are filled.")
            return
        }
        //        // Show loader before starting the API call
        self.view.isUserInteractionEnabled = false
        if let validationError = validateCredentials(email: email, password: password) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                LogManager.shared.addLog(data: "#Login Validation Error \(validationError)")
                showAlert("Validation Error", validationError)
            }
            return
        }
        ProgressHUD.animate()
        // MARK: - Log in Api
        LogManager.shared.addLog(data: "#Login calling Log In Api")
        APIManager.shareInstance.callingLogInApi(email: email, password: password) { [weak self] result in
            guard let self else {
                return
            }
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true  // Re-enable interactions
                ProgressHUD.dismiss()
                if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
                    self.myUserToken = userToken
                }
            }
            switch result {
            case .success(let profileResponse):
                let profileData = profileResponse.data
                LogManager.shared.addLog(data: "\(profileData)")
                guard let token = profileData.token else { return }
                sendLogData()
                // Store the token in UserDefaults
                UserDefaults.standard.set(token, forKey: "userToken")
                print("Token stored successfully: \(token)")
                
                self.userData.append(UserProfileData(firstName: profileData.firstName, lastName: profileData.lastName, email: profileData.email, submissionDate: profileData.submissionDate, token: profileData.token))
                DispatchQueue.main.async {
                    self.checkSubmissionDate()
                }
            case .failure(let error):
                LogManager.shared.addLog(data: "\(error)")
                sendLogData()
                print("Error fetching profile: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlert("Error", "\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkSubmissionDate() {
        LogManager.shared.addLog(data: "#Login checking submission date")

        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            if myUserToken == userToken {
                LogManager.shared.addLog(data: "#Login intact survey data")
                print("intact survey data")
            } else {
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "questionData")
                defaults.removeObject(forKey: "selectedOptions")
                print("removed user data")
                LogManager.shared.addLog(data: "#Login removed user data")
            }
        }
        LogManager.shared.addLog(data: "#Login navigating to home screen")
        sendLogData()
        navigateToViewController(withIdentifier: "HomeScreenVC", storyboardName: "HomeSC")
    }
    // MARK: - Methods
    private func setupImageTapGestures() {
        eyeIconImageView.isUserInteractionEnabled = true
        let tapGesture1 = UITapGestureRecognizer(target : self, action : #selector(toggleNewPasswordVisibility))
        eyeIconImageView.addGestureRecognizer(tapGesture1)
        // Initialize the image based on current password visibility
        updateEyeIcon()
    }
    
    private func getProfileData() {
        ProgressHUD.animate("Fetching User Data...")
        LogManager.shared.addLog(data: "#Login Fetching User Data...")
        APIManager.shareInstance.callingGetProfileApi { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let profileResponse):
                    let profileData = profileResponse.data
                    LogManager.shared.addLog(data: "\(profileData)")
                    sendLogData()

                    self.userData.append(UserProfileData(firstName: profileData.firstName, lastName: profileData.lastName, email: profileData.email, submissionDate: profileData.submissionDate, token: profileData.token))
                    print("user data are \(UserProfileData.self)")
                case .failure(let error):
                    LogManager.shared.addLog(data: "\(error)")
                    sendLogData()
                    print("Error fetching profile: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert("Error", "Failed to load profile data.")
                    }
                }
            }
        }
    }
    
    @objc private func toggleNewPasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        updateEyeIcon()
    }
    
    private func updateEyeIcon() {
        let imageName = isPasswordVisible ? "eye" : "eye.slash"
        eyeIconImageView.image = UIImage(systemName : imageName)
        eyeIconImageView.tintColor = UIColor(red: 100/255, green: 106/255, blue: 114/255, alpha: 1.0)
    }
}
// MARK: - Loginpage extension
extension LoginPageVC {
    
    private func validateCredentials(email: String, password: String) -> String? {
        if email.isEmpty {
            LogManager.shared.addLog(data: "#Login The email field is required.")
            return "The email field is required."
        } else if !Validator.validateEmail(email) {
            LogManager.shared.addLog(data: "#Login Please enter a valid email.")
            return "Please enter a valid email."
        } else if password.isEmpty {
            LogManager.shared.addLog(data: "#Login The password field is required.")
            return "The password field is required."
        } else if password.count < 8 {
            LogManager.shared.addLog(data: "#Login Password must be at least 8 characters long.")
            return "Password must be at least 8 characters long."
        }
        return nil
    }
}
// MARK: - Test Methods
extension LoginPageVC {
    
    private func developmentData() {
        //emailTextField.text = "hemant.mobileappdev@gmail.com"
        emailTextField.text = "test13@test.com"
        passwordTextField.text = "test1234"
        //loginButton.sendActions(for: .touchUpInside)
    }
    
    private func productionData() {
        
        //emailTextField.text = "020625@123.com"

        emailTextField.text = "rajal@gmail.com"
        passwordTextField.text = "Test@123"
    }
}

extension LoginPageVC {
    
    private func sendLogData() {
        LogManager.shared.sendLogsToServer() { result in
            switch result {
                case .success(let value):
                print("Successfully sent log data from login screen: \(value)")
            case .failure(let error):
                print("Error sending log data from login screen: \(error)")
            }
        }
    }
}

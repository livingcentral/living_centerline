import UIKit
import ProgressHUD

class RegisterPageVC: UIViewController {
    // MARK: - Outlets
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var signInButton: UIButton!
    // UI label
    @IBOutlet var dontHaveAccountLabel: UILabel!
    @IBOutlet var confirmPasswordLabel: UILabel!
    @IBOutlet var passwordLabel: UILabel!
    @IBOutlet var emailIdLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var welcomeBackLabel: UILabel!
    @IBOutlet var signUpAccountLabel: UILabel!
    // UI textfield
    @IBOutlet var confirmPasswordTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var emailIdTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var firstNameTextField: UITextField!
    // UI imageview
    @IBOutlet var backgroundimage1: UIImageView!
    @IBOutlet var backgroundImage2: UIImageView!
    @IBOutlet var confirmPasswordEyeIconImageView: UIImageView!
    @IBOutlet var passwordEyeIconImageView: UIImageView!
    // UI View
    @IBOutlet var contentView: UIView!
    // MARK: - Properties
    private var isPasswordVisible = false
    private var isConfirmPasswordVisible = false
    //private var model = [RegisterModel]()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // developmentData()
        LogManager.shared.addLog(data: "#Register register screen is open")
        sendLogData()
        configureUI()
        setupImageTapGestures()
        setupKeyboardDismissGesture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.applyCornerRadius(corners: [.topLeft, .topRight], radius: 20.0)
    }
    //MARK: - UI Configuration
    private func configureUI() {
        if API.isTestingOn {
            developmentData()
            //productionData()
        }
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        let screenHeight = self.view.frame.height
        let fontScaleFactor = screenHeight / 812
        
        signUpAccountLabel.font = UIFont(name: "SFProDisplay-Bold", size: 26 * fontScaleFactor)
        welcomeBackLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        firstNameLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        lastNameLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        emailIdLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        passwordLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        confirmPasswordLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        signInButton.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 12 * fontScaleFactor)
        signUpButton.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 15 * fontScaleFactor)
        // Initialize password visibility images
        updatePasswordVisibilityImages()
    }
    // MARK: - UI methods
    private func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Allows other touch events to still be recognized
        contentView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupImageTapGestures() {
        passwordEyeIconImageView.isUserInteractionEnabled = true
        confirmPasswordEyeIconImageView.isUserInteractionEnabled = true
        
        let tapGesture1 = UITapGestureRecognizer(target : self, action : #selector(togglePasswordVisibility))
        passwordEyeIconImageView.addGestureRecognizer(tapGesture1)
        
        let tapGesture2 = UITapGestureRecognizer(target : self, action : #selector(toggleConfirmPasswordVisibility))
        confirmPasswordEyeIconImageView.addGestureRecognizer(tapGesture2)
    }
    
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        updatePasswordVisibilityImages()
    }
    
    @objc private func toggleConfirmPasswordVisibility() {
        isConfirmPasswordVisible.toggle()
        confirmPasswordTextField.isSecureTextEntry = !isConfirmPasswordVisible
        updatePasswordVisibilityImages()
    }
    
    private func updatePasswordVisibilityImages() {
        updateEyeIcon(passwordVisibility : isPasswordVisible, imageViewName: passwordEyeIconImageView)
        updateEyeIcon(passwordVisibility : isConfirmPasswordVisible, imageViewName: confirmPasswordEyeIconImageView)
    }
    
    private func updateEyeIcon(passwordVisibility: Bool, imageViewName: UIImageView) {
        let confirmPasswordImageName = passwordVisibility ? "eye" : "eye.slash"
        imageViewName.image = UIImage(systemName: confirmPasswordImageName)
        imageViewName.tintColor = UIColor(red: 100/255, green: 106/255, blue: 114/255, alpha: 1.0)
    }
    // MARK: - Button actions
    @IBAction func signInBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#Register back btn pressed from signup")
        sendLogData()
        popViewController()
    }
    
    @IBAction func signUpBtnPressed(_ sender: UIButton) {
        LogManager.shared.addLog(data: "#Register register btn pressed from signup")
        sendLogData()

        guard let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespaces),
              let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespaces),
              let email = emailIdTextField.text?.trimmingCharacters(in: .whitespaces),
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespaces),
              let confirmPassword = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespaces) else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                LogManager.shared.addLog(data: "#Register Please make sure all fields are filled.")
                showAlert("Error", "Please make sure all fields are filled.")
            }
            return
        }
        if let errorMessage = validateSignUp(firstName: firstName, lastName: lastName, email: email, password: password, confirmPassword: confirmPassword) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                LogManager.shared.addLog(data: errorMessage)
                showAlert("Validation Error", errorMessage)
            }
            return
        }
        // Proceed with registration if validation passed
        registerUser(firstName: firstName, lastName: lastName, email: email, password: password)
    }
    //MARK: - Validation Methods
    private func validateSignUp(firstName: String, lastName: String, email: String, password: String, confirmPassword: String) -> String? {
        if let errorMessage = validateFirstName(firstName) { return errorMessage }
        if let errorMessage = validateLastName(lastName) { return errorMessage }
        if let errorMessage = validateEmail(email) { return errorMessage }
        if let errorMessage = validatePassword(password, confirmPassword: confirmPassword) { return errorMessage }
        return nil
    }
    
    private func validateFirstName(_ firstName: String) -> String? {
        if firstName.isEmpty { return "The first name field is required." }
        if !Validator.validateFirstName(firstName) {
            if firstName.rangeOfCharacter(from: CharacterSet.letters.inverted) != nil {
                LogManager.shared.addLog(data: "#Register The first name must contain only alphabetic characters.")
                return "The first name must contain only alphabetic characters."
            } else if firstName.count < 2 {
                return "The first name must be at least 2 alphabetic characters."
            }
        }
        return nil
    }
    
    private func validateLastName(_ lastName: String) -> String? {
        if lastName.isEmpty { return "The last name field is required." }
        if !Validator.validateLastName(lastName) {
            if lastName.rangeOfCharacter(from: CharacterSet.letters.inverted) != nil {
                LogManager.shared.addLog(data: "#Register The last name must contain only alphabetic characters.")
                return "The last name must contain only alphabetic characters."
            } else if lastName.count < 2 {
                LogManager.shared.addLog(data: "#Register The last name must be at least 2 alphabetic characters.")
                return "The last name must be at least 2 alphabetic characters."
            }
        }
        return nil
    }
    
    private func validateEmail(_ email: String) -> String? {
        if email.isEmpty {
            LogManager.shared.addLog(data: "#Register The email address field is required.")
            return "The email address field is required." }
        if !Validator.validateEmail(email) {
            LogManager.shared.addLog(data: "#Register Please enter a valid email address.")
            return "Please enter a valid email address." }
        return nil
    }
    
    private func validatePassword(_ password: String, confirmPassword: String) -> String? {
        if password.isEmpty {
            LogManager.shared.addLog(data: "#Register The password field is required.")
            return "The password field is required." }
        if password.count < 8 {
            LogManager.shared.addLog(data: "#Register Password must be at least 8 characters long.")
            return "Password must be at least 8 characters long." }
        if confirmPassword.isEmpty {
            LogManager.shared.addLog(data: "#Register The confirm password field is required.")
            return "The confirm password field is required." }
        if password != confirmPassword {
            LogManager.shared.addLog(data: "#Register Passwords do not match.")
            return "Passwords do not match." }
        return nil
    }
    //MARK: - API Call
    private func registerUser(firstName: String, lastName: String, email: String, password: String) {
        LogManager.shared.addLog(data: "#Register calling Register Api ")
        DispatchQueue.main.async {
            ProgressHUD.animate()
            self.view.isUserInteractionEnabled = false
        }
        APIManager.shareInstance.callingRegisterApi(fName: firstName, lName: lastName, email: email, password: password) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
            }
            switch result {
            case .success(let response):
                LogManager.shared.addLog(data: "\(response)")
                sendLogData()
                self.handleRegistrationSuccess(response)
            case .failure(let error):
                LogManager.shared.addLog(data: "\(error)")
                sendLogData()
                self.handleRegistrationFailure(error)
            }
        }
    }
    
    private func handleRegistrationSuccess(_ response: Any) {
        if let responseDict = response as? [String: Any],
           let data = responseDict["data"] as? [String: Any],
           let token = data["token"] as? String {
            UserDefaults.standard.set(token, forKey: "userToken")
            DispatchQueue.main.async {
                LogManager.shared.addLog(data: "#Register registration success")
                self.navigateToViewController(withIdentifier: "HomeScreenVC", storyboardName: "HomeSC")
            }
        } else {
            LogManager.shared.addLog(data: "#Register Error: Unable to extract token from response")
            print("Error: Unable to extract token from response")
        }
    }
    
    private func handleRegistrationFailure(_ error: Error) {
        let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred."
        DispatchQueue.main.async {
            self.showAlert("Signup Failed", errorMessage)
        }
    }
}
// MARK: - Test Methods
extension RegisterPageVC {
    
    private func developmentData() {
#if SCREENSHOT_FIXTURES
        firstNameTextField.text = "James"
        lastNameTextField.text = "Kirk"
        emailIdTextField.text = MockData.profile.data.email
        passwordTextField.text = "mock-password"
        confirmPasswordTextField.text = "mock-password"
#endif
    }
    
    private func productionData() {
        print("no production data available to set in textfield")
    }
}

extension RegisterPageVC {
    
    private func sendLogData() {
        LogManager.shared.sendLogsToServer() { result in
            switch result {
                case .success(let value):
                print("Successfully sent log data from register screen: \(value)")
            case .failure(let error):
                print("Error sending log data from register screen: \(error)")
            }
        }
    }
}

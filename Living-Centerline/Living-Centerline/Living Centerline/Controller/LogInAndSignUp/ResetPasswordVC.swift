import UIKit
import ProgressHUD

class ResetPasswordVC: UIViewController {
    // MARK: - View Lifecycle
    @IBOutlet var allView: UIView!
    // UI textfield
    @IBOutlet var reEnterPasswordTextField: UITextField!
    @IBOutlet var newPasswordTextField: UITextField!
    // UI imageview
    @IBOutlet var imgNewPassword: UIImageView!
    @IBOutlet var imgReEnterPassword: UIImageView!
    // ui button
    @IBOutlet var updatePasswordBtn: UIButton!
    // ui label
    @IBOutlet var reEnterPasswordLabel: UILabel!
    @IBOutlet var newPasswordLabel: UILabel!
    @IBOutlet var enterYourPasswordLabel: UILabel!
    @IBOutlet var resetPasswordLabel: UILabel!
    // MARK: - Properties
    private var isNewPasswordVisible = false
    private var isReEnterPasswordVisible = false
    var email: String? // Email and OTP passed to this view controller
    var otp: String?
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // developmentData()
        navigationController?.navigationBar.isHidden = true
        configureUI()
        setupImageTapGestures()
        setupTapToDismissKeyboard()
    }
    // MARK: - Configure UI
    private func configureUI() {
        if API.isTestingOn {
            developmentData()
            //productionData()
        }
        let screenHeight = self.view.frame.height
        resetPasswordLabel.font = UIFont(name: "SFProDisplay-Bold", size: screenHeight * 28 / 812)
        enterYourPasswordLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 12 / 812)
        newPasswordLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 12 / 812)
        reEnterPasswordLabel.font = UIFont(name: "SFProDisplay-Medium", size: screenHeight * 12 / 812)
        updatePasswordBtn.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: screenHeight * 15 / 812)
        newPasswordTextField.isSecureTextEntry = true
        reEnterPasswordTextField.isSecureTextEntry = true
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        guard let VC = self.navigationController?.viewControllers.filter({$0.isKind(of: ForgotPasswordVC.self)}).first else {return}
        self.navigationController?.popToViewController(VC, animated: true)
    }
    // MARK: - Toggle Password Visibility
    private func setupImageTapGestures() {
        imgNewPassword.isUserInteractionEnabled = true
        imgReEnterPassword.isUserInteractionEnabled = true
        
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(toggleNewPasswordVisibility))
        imgNewPassword.addGestureRecognizer(tapGesture1)
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(toggleReEnterPasswordVisibility))
        imgReEnterPassword.addGestureRecognizer(tapGesture2)
    }
    
    @objc private func toggleNewPasswordVisibility() {
        isNewPasswordVisible.toggle()
        newPasswordTextField.isSecureTextEntry = !isNewPasswordVisible
        imgNewPassword.image = UIImage(systemName: isNewPasswordVisible ? "eye" : "eye.slash")
        imgNewPassword.tintColor = UIColor(red: 100/255, green: 106/255, blue: 114/255, alpha: 1.0)
    }
    
    @objc private func toggleReEnterPasswordVisibility() {
        isReEnterPasswordVisible.toggle()
        reEnterPasswordTextField.isSecureTextEntry = !isReEnterPasswordVisible
        imgReEnterPassword.image = UIImage(systemName: isReEnterPasswordVisible ? "eye" : "eye.slash")
        imgReEnterPassword.tintColor = UIColor(red: 100/255, green: 106/255, blue: 114/255, alpha: 1.0)
    }
    // MARK: - Dismiss Keyboard
    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        allView.isUserInteractionEnabled = true
        allView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    // MARK: - Update Password Button Action
    @IBAction func updatePasswordButtonPressed(_ sender: UIButton) {
        guard let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
              let email = self.email, // Correctly using the email and otp passed from the previous screen
              let otp = self.otp,
              let reEnterPassword = reEnterPasswordTextField.text, !reEnterPassword.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                presentAlert(title: "Error", message: "Please fill in both password fields.")
            }
            return
        }
        // Check if both passwords match
        if newPassword != reEnterPassword {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                presentAlert(title: "Error", message: "Passwords do not match.")
            }
            return
        }
        // Validate password (optional: based on your requirements)
        if !Validator.validatePassword(newPassword) {
            presentAlert(title: "Error", message: "Password must be at least 8 characters and contain only numeric characters (0-9).")
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            ProgressHUD.animate()
            self.view.isUserInteractionEnabled = false
        }
        // Call API to update the password
        APIManager.shareInstance.callingSetNewPasswordApi(email: email, otp: otp, password: newPassword) { result in
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
            }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Print the response to the console
                    print("Success Response: \(response)")
                    // Show success alert
                    self.presentAlert(title: "Success", message: "Password updated successfully.") {
                        // Navigate to LoginPageVC after password update
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let loginPage = storyboard.instantiateViewController(withIdentifier: "LoginPageVC") as? LoginPageVC {
                            self.navigationController?.pushViewController(loginPage, animated: true)
                        }
                    }
                case .failure(let error):
                    // Print the error response to the console
                    print("Final \(error)") // This prints the full error for debugging
                    // Extract the error message from the localized description
                    let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred."
                    // Show the alert with the extracted error message
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.showAlert("Error", errorMessage)
                    }
                }
            }
        }
    }
}
// MARK: - Test Methods
extension ResetPasswordVC {
    
    private func developmentData() {
        newPasswordTextField.text = "test1234"
        reEnterPasswordTextField.text = "test1234"
    }
    
    private func productionData() {
        print("no production data available to set in textfield")
    }
}

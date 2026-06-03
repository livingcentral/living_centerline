import UIKit
import ProgressHUD

class ForgotPasswordVC: UIViewController {
    // MARK: - Outlets
    @IBOutlet var continueBtn: UIButton!
    // UI Textfield
    @IBOutlet var emailTextField: UITextField!
    // UI label
    @IBOutlet var emailAddressLabel: UILabel!
    @IBOutlet var resetPasswordLabel: UILabel!
    @IBOutlet var forgotPasswordLabel: UILabel!
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        configureUI()
    }
    // MARK: - UI Configuration
    private func configureUI() {
        if API.isTestingOn {
            developmentData()
            //productionData()
        }
        // Set fonts dynamically based on screen size
        let screenHeight = view.frame.height
        let fontScaleFactor = screenHeight / 812
        forgotPasswordLabel.font = UIFont(name: "SFProDisplay-Bold", size: 26 * fontScaleFactor)
        resetPasswordLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        emailAddressLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * fontScaleFactor)
        continueBtn.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 16 * fontScaleFactor)
        // Set placeholder font
        emailTextField.setPlaceholder("Enter your email", fontName: "SFProDisplay-Medium", size: 14 * fontScaleFactor)
    }
    
    func fontHeight(screenHeight: CGFloat, initial: Int, devider: Int) -> CGFloat {
        let sizeValue =  CGFloat(Int(screenHeight) * initial / devider)
        return sizeValue
    }
    // Remove observers when the view controller is deinitialized
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    // MARK: - Button actions
    @IBAction func backBtnPressed(_ sender: UIButton) {
        popViewController()
    }
    // Action for the continue button
    @IBAction func continueBtnPressed(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                showAlert("Error", "Please make sure the email field is filled.")
            }
            return
        }
        // Validate email format
        guard Validator.validateEmail(email) else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                showAlert("Validation Error", "Please enter a valid email address.")
            }
            return
        }
        // Show loading animation
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            ProgressHUD.animate()
            view.isUserInteractionEnabled = false
        }
        // Call the Send OTP API
        APIManager.shareInstance.callingSendOTPApi(email: email) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
                ProgressHUD.dismiss()
                
                switch result {
                case .success(let response):
                    self.handleOTPSuccess(email: email, response: response)
                case .failure(let error):
                    self.handleOTPFailure(error: error)
                }
            }
        }
    }
    // MARK: - Handle OTP Result
    private func handleOTPSuccess(email: String, response: Any) {
        print("OTP successfully sent, navigating to the next screen.")
        print(response)
        // Navigate to OTP verification screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let otpVC = storyboard.instantiateViewController(withIdentifier: "OTPVerificationVC") as? OTPVerificationVC {
            otpVC.email = email
            navigationController?.pushViewController(otpVC, animated: true)
        }
    }
    
    private func handleOTPFailure(error: Error) {
        print("Final \(error)")
        // Show error message
        let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred."
        showAlert("OTP Send Failed", errorMessage)
    }
}
// MARK: - Test Methods
extension ForgotPasswordVC {
    
    private func developmentData() {
        emailTextField.text = "hemant.mobileappdev@gmail.com"
    }
    
    private func productionData() {
        print("no production data available to set in textfield")
    }
}

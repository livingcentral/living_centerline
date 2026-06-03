import UIKit
import ProgressHUD

class OTPVerificationVC: UIViewController, UITextFieldDelegate {
    // MARK: - Outlets
    @IBOutlet var OTP1TextField: UITextField!
    @IBOutlet var OTP2TextField: UITextField!
    @IBOutlet var OTP3TextField: UITextField!
    @IBOutlet var OTP4TextField: UITextField!
    // UI Button
    @IBOutlet var verifyCodeButton: UIButton!
    @IBOutlet var resendCodeButton: UIButton!
    // UI Label
    @IBOutlet var OTPVerificationLabel: UILabel!
    @IBOutlet var checkYourEmailLabel: UILabel!
    // MARK: - Properties
    var email: String?
    private var model = [VarifyOTPModel]()
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        configureUI()
        setupTextFields()
        updateTextFieldAppearance(for: OTP1TextField)
    }
    // MARK: - UI Configuration
    private func configureUI() {
        let screenHeight = view.frame.height
        let scaleFactor: CGFloat = screenHeight / 812
        OTPVerificationLabel.font = UIFont(name: "SFProDisplay-Bold", size: 26 * scaleFactor)
        checkYourEmailLabel.font = UIFont(name: "SFProDisplay-Medium", size: 12 * scaleFactor)
        resendCodeButton.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 12 * scaleFactor)
        verifyCodeButton.titleLabel?.font = UIFont(name: "SFProDisplay-Bold", size: 12 * scaleFactor)
    }
    // MARK: - TextField Setup
    private func setupTextFields() {
        let textFields = [OTP1TextField, OTP2TextField, OTP3TextField, OTP4TextField]
        
        textFields.forEach { textField in
            textField?.delegate = self
            textField?.keyboardType = .numberPad
            textField?.textAlignment = .center
            textField?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            textField?.layer.borderWidth = 1
            textField?.layer.borderColor = UIColor.gray.cgColor
            textField?.layer.cornerRadius = 8
        }
    }
    // Handle the text field editing and ensure only numeric input is allowed
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Allow only numeric characters (0-9)
        let allowedCharacters = CharacterSet(charactersIn: "0123456789")
        let characterSet = CharacterSet(charactersIn: string)
        if !allowedCharacters.isSuperset(of: characterSet) {
            return false // Block non-numeric input
        }
        guard let currentText = textField.text else { return false }
        let newString = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if newString.count == 1 {  // When a character is entered
            textField.text = newString
            switch textField {
            case OTP1TextField:
                OTP2TextField.becomeFirstResponder()
                updateTextFieldAppearance(for: OTP2TextField)
            case OTP2TextField:
                OTP3TextField.becomeFirstResponder()
                updateTextFieldAppearance(for: OTP3TextField)
            case OTP3TextField:
                OTP4TextField.becomeFirstResponder()
                updateTextFieldAppearance(for: OTP4TextField)
            case OTP4TextField:
                OTP4TextField.resignFirstResponder() // Last field, dismiss keyboard
                clearTextFieldBorders() // Clear the blue border when OTP is fully entered
            default:
                break
            }
            return false  // Block further changes
        } else if newString.isEmpty {  // Handle backspace
            switch textField {
            case OTP4TextField:
                OTP3TextField.becomeFirstResponder()
                updateTextFieldAppearance(for: OTP3TextField)
            case OTP3TextField:
                OTP2TextField.becomeFirstResponder()
                updateTextFieldAppearance(for: OTP2TextField)
            case OTP2TextField:
                OTP1TextField.becomeFirstResponder()
                updateTextFieldAppearance(for: OTP1TextField)
            case OTP1TextField:
                OTP1TextField.becomeFirstResponder()
                updateTextFieldAppearance(for: OTP1TextField)
            default:
                break
            }
            textField.text = ""
            return false
        }
        return false
    }
    // Update the appearance of the text field that is currently active
    private func updateTextFieldAppearance(for textField: UITextField) {
        
        [OTP1TextField, OTP2TextField, OTP3TextField, OTP4TextField].forEach {
            $0?.layer.borderColor = UIColor.gray.cgColor
            $0?.layer.borderWidth = 1
        }
        
        // Highlight the current text field
        textField.layer.borderColor = UIColor.blue.cgColor
        textField.layer.borderWidth = 2
    }
    // Clear all text field borders once the OTP is fully entered
    private func clearTextFieldBorders() {
        [OTP1TextField, OTP2TextField, OTP3TextField, OTP4TextField].forEach {
            $0?.layer.borderColor = UIColor.gray.cgColor
            $0?.layer.borderWidth = 1
        }
    }
    // Combine the OTP digits from all text fields
    private func getOTP() -> String {
        let otp1 = OTP1TextField.text ?? ""
        let otp2 = OTP2TextField.text ?? ""
        let otp3 = OTP3TextField.text ?? ""
        let otp4 = OTP4TextField.text ?? ""
        
        return otp1 + otp2 + otp3 + otp4
    }
    // MARK: button actions
    @IBAction func verifyCodePressed(_ sender: UIButton) {
        guard let email = self.email else {
            showAlert("Error", "Email is missing.")
            return
        }
        let otp = getOTP()  // Get the entered OTP
        // Ensure OTP has 4 digits
        if otp.count != 4 {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                showAlert("Invalid OTP", "Please enter a valid 4-digit OTP.")
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            ProgressHUD.animate()
            self.view.isUserInteractionEnabled = false
        }
        // Call the API to verify OTP
        APIManager.shareInstance.callingVerifyOTPApi(email: email, otp: otp) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
            }
            switch result {
            case .success(let jsonResponse):
                DispatchQueue.main.async {
                    print("OTP verified successfully: \(jsonResponse)")
                    // Navigate to ResetPasswordVC upon successful OTP verification
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let resetPasswordVC = storyboard.instantiateViewController(withIdentifier: "ResetPasswordVC") as? ResetPasswordVC {
                        resetPasswordVC.email = email
                        resetPasswordVC.otp = otp
                        self.navigationController?.pushViewController(resetPasswordVC, animated: true)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Show alert in case of failure
                    // Show alert in case of failure
                    print("Final \(error)") // This prints the full error for debugging
                    // Extract the error message from the localized description
                    let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred."
                    // Show the alert with the extracted error message
                    self.showAlert("Error!", errorMessage)
                }
            }
        }
    }
    
    @IBAction func reSendCodeButtonpressed(_ sender: UIButton) {
        guard let email = self.email else {
            showAlert("Error", "Email is missing.")
            return
        }
        DispatchQueue.main.async {
            ProgressHUD.animate()
            self.view.isUserInteractionEnabled = false
        }
        // Call the API to resend the OTP
        APIManager.shareInstance.callingSendOTPApi(email: email) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                ProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
            }
            switch result {
            case .success(let jsonResponse):
                DispatchQueue.main.async {
                    guard let self else { return }
                    print("OTP resent successfully: \(jsonResponse)")
                    self.showAlert("Success", "A new OTP has been sent to your email.")
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    guard let self else { return }
                    // Show alert in case of failure
                    print("Final \(error)") // This prints the full error for debugging
                    // Extract the error message from the localized description
                    let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred."
                    // Show the alert with the extracted error message
                    self.showAlert("Error!", errorMessage)
                }
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        popViewController()
    }
}


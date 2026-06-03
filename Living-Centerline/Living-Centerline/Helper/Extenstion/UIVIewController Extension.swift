//
//  UIVIewController Extension.swift
//  Living-Centerline
//
//  Created by Developer on 03/10/24.
//

import UIKit
extension UIViewController {
    
    func navigateToViewController(withIdentifier identifier: String, storyboardName: String = "Main") {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        // Instantiate the view controller
        let viewController = storyboard.instantiateViewController(withIdentifier: identifier)
        // Check if navigationController is available
        if let navigationController = navigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else {
            print("Navigation controller is not available")
        }
    }
    
    func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func presentAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

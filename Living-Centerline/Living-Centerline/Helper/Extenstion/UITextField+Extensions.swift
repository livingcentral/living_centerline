//
//  GradiantView.swift
//  Living-Centerline
//
//  Created by MACMonterio on 16/09/2024.
//

// UITextField+Extensions.swift
import UIKit

extension UITextField {
    func setPlaceholder(_ placeholderText: String, fontName: String, size: CGFloat, color: UIColor = .lightGray) {
        self.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [
                .font: UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size),
                .foregroundColor: color
            ]
        )
    }
}


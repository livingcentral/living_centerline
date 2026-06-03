//
//  RoundedView.swift
//  Living-Centerline
//
//  Created by MACMonterio on 16/09/2024.
//

import UIKit

class RoundedView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update the corner radius based on the current height of the view
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

class RoundedImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update the corner radius based on the current height of the image view
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update the corner radius based on the current height of the button
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}





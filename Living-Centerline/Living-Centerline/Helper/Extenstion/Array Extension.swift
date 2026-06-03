//
//  Array Extension.swift
//  Living-Centerline
//
//  Created by APPLE on 28/01/25.
//

import Foundation

extension Array where Element: Equatable {
    mutating func appendIfNotExists(_ element: Element) {
        if !self.contains(element) {
            self.append(element)
        }
    }
}

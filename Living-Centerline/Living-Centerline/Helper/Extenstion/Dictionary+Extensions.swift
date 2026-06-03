//
//  Dictionary+Extensions.swift
//  Living-Centerline
//
//  Created by Oleksandr on 12.05.2025.
//

extension Dictionary where Key == String, Value == Int {
    func value(forKey key: String, defaultValue: Int = 0) -> Int {
        return self[key] ?? defaultValue
    }
}

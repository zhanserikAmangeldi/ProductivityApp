//
//  UserDefaultsManager.swift
//  ProductivityApp
//
//  Created by Kassiman Alikhan on 12.05.2025.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    func setValue(_ value: Any?, forKey key: String) {
        let userSpecificKey = CurrentUserService.shared.getUserSpecificKey(for: key)
        UserDefaults.standard.set(value, forKey: userSpecificKey)
    }
    
    func bool(forKey key: String) -> Bool {
        let userSpecificKey = CurrentUserService.shared.getUserSpecificKey(for: key)
        return UserDefaults.standard.bool(forKey: userSpecificKey)
    }
    
    func integer(forKey key: String) -> Int {
        let userSpecificKey = CurrentUserService.shared.getUserSpecificKey(for: key)
        return UserDefaults.standard.integer(forKey: userSpecificKey)
    }
    
    func string(forKey key: String) -> String? {
        let userSpecificKey = CurrentUserService.shared.getUserSpecificKey(for: key)
        return UserDefaults.standard.string(forKey: userSpecificKey)
    }
    
    func data(forKey key: String) -> Data? {
        let userSpecificKey = CurrentUserService.shared.getUserSpecificKey(for: key)
        return UserDefaults.standard.data(forKey: userSpecificKey)
    }
    
    func removeObject(forKey key: String) {
        let userSpecificKey = CurrentUserService.shared.getUserSpecificKey(for: key)
        UserDefaults.standard.removeObject(forKey: userSpecificKey)
    }
}


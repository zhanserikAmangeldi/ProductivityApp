//
//  ThemeManager.swift
//  ProductivityApp
//
//  Created by Alikhan Kassiman on 12.05.2025.
//

import Foundation
import SwiftUI
import Combine

enum AppTheme: String {
    case light
    case dark
    case system
    
    var uiInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return .unspecified
        }
    }
}

class ThemeManager {
    static let shared = ThemeManager()
    
    // Theme change notification name
    static let themeChangedNotification = Notification.Name("ThemeChangedNotification")
    
    @Published var currentTheme: AppTheme = .system
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load saved theme preference
        let themeName = UserDefaultsManager.shared.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        if let theme = AppTheme(rawValue: themeName) {
            self.currentTheme = theme
        }
        
        applyTheme(currentTheme)
        
        $currentTheme
            .sink { [weak self] theme in
                self?.applyTheme(theme)
                UserDefaultsManager.shared.setValue(theme.rawValue, forKey: "appTheme")
            }
            .store(in: &cancellables)
    }
    
    func applyTheme(_ theme: AppTheme) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.applyTheme(theme)
            }
            return
        }
        
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.compactMap { $0 as? UIWindowScene }
        
        for windowScene in windowScenes {
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = theme.uiInterfaceStyle
            }
        }
        
        NotificationCenter.default.post(name: ThemeManager.themeChangedNotification, object: theme)
    }
    
    func setTheme(_ isDarkMode: Bool) {
        currentTheme = isDarkMode ? .dark : .light
    }
    
    var isDarkModeEnabled: Bool {
        return currentTheme == .dark
    }
}

//
//  QuoteSettingsViewModel.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 11.05.2025.
//

import SwiftUI

class QuoteSettingsViewModel: ObservableObject {
    @Published var isQuoteNotificationsEnabled: Bool
    @Published var notificationFrequency: Int
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var areGeneralNotificationsEnabled: Bool
    
    private let notificationService = NotificationService.shared
    
    init() {
        self.areGeneralNotificationsEnabled = UserDefaultsManager.shared.bool(forKey: "isNotificationsEnabled")
        self.isQuoteNotificationsEnabled = UserDefaultsManager.shared.bool(forKey: "isQuoteNotificationsEnabled")
        self.notificationFrequency = UserDefaultsManager.shared.integer(forKey: "quoteNotificationFrequency")
        if self.notificationFrequency == 0 { self.notificationFrequency = 2 } // Default to 2 hours
    }
    
    func saveSettings() {
        let effectiveQuoteNotificationsEnabled = areGeneralNotificationsEnabled && isQuoteNotificationsEnabled
        
        UserDefaultsManager.shared.setValue(effectiveQuoteNotificationsEnabled, forKey: "isQuoteNotificationsEnabled")
        UserDefaultsManager.shared.setValue(notificationFrequency, forKey: "quoteNotificationFrequency")
        
        Task {
            await updateNotifications()
        }
    }
    
    func updateNotifications() async {
        if isQuoteNotificationsEnabled {
            await notificationService.scheduleQuoteNotifications()
        } else {
            notificationService.cancelQuoteNotifications()
        }
    }
    
    func testNotification() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                await notificationService.scheduleTestQuoteNotification()
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to send test notification: \(error.localizedDescription)"
                }
            }
        }
    }
}

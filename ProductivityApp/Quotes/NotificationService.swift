//
//  NotificationService.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 11.05.2025.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func scheduleQuoteNotifications() async {
        // Check if notifications are enabled
        guard UserDefaults.standard.bool(forKey: "isQuoteNotificationsEnabled") && UserDefaults.standard.bool(forKey: "isQuoteNotificationsEnabled") else {
            cancelQuoteNotifications()
            return
        }
        
        // Cancel any existing quote notifications
        cancelQuoteNotifications()
        
        // Now schedule new ones
        let center = UNUserNotificationCenter.current()
        let quotesService = QuotesService.shared
        
        // Schedule for the next 24 hours (12 notifications at 2-hour intervals)
        for i in 1...12 {
            do {
                let quote = try await quotesService.getRandomQuote()
                
                let content = UNMutableNotificationContent()
                content.title = "Motivation Boost"
                content.body = "\"\(quote.content)\" - \(quote.author)"
                content.sound = .default
                
                // Trigger every 2 hours
                let triggerTime = TimeInterval(i * 2 * 60 * 60)
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: triggerTime,
                    repeats: false
                )
                
                let identifier = "quoteNotification-\(i)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                
                try await center.add(request)
                print("Scheduled quote notification \(i) for \(triggerTime/3600) hours from now")
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    // Cancel
    func cancelQuoteNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers:
            (1...12).map { "quoteNotification-\($0)" }
        )
    }
    
    // scheduleTest
    func scheduleTestQuoteNotification() async {
        do {
            let quote = try await QuotesService.shared.getRandomQuote()
            
            let content = UNMutableNotificationContent()
            content.title = "Test Motivation"
            content.body = "\"\(quote.content)\" - \(quote.author)"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 5,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "testQuoteNotification",
                content: content,
                trigger: trigger
            )
            
            try await UNUserNotificationCenter.current().add(request)
            print("Test notification scheduled")
        } catch {
            print("Failed to schedule test notification: \(error)")
        }
    }
    
    func recheckNotificationSettings() {
        // If general notifications are disabled, cancel all quote notifications
        if !UserDefaults.standard.bool(forKey: "isNotificationsEnabled") {
            cancelQuoteNotifications()
        }
        // If general notifications are enabled but quote notifications are disabled
        else if !UserDefaults.standard.bool(forKey: "isQuoteNotificationsEnabled") {
            cancelQuoteNotifications()
        }
        // If both are enabled, ensure notifications are scheduled
        else {
            Task {
                await scheduleQuoteNotifications()
            }
        }
    }
}

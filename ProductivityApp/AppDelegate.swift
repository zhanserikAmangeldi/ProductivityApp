//
//  AppDelegate.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import UIKit
import FirebaseCore
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        requestNotificationPermissions()

        _ = CoreDataService.shared.persistentContainer
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(userLoggedIn),
                                             name: NSNotification.Name("UserDidLogin"),
                                             object: nil)

        print("Application did finish launching")
        
        return true
    }
    
    @objc func userLoggedIn() {
         // Migrate data when a user logs in
         migrateExistingData()
     }
     
     func migrateExistingData() {
         guard let userId = CurrentUserService.shared.currentUserId else { return }
         
         // Check if we've already migrated
         let isMigrated = UserDefaults.standard.bool(forKey: "dataMigratedForUser_\(userId)")
         if isMigrated { return }
         
         // Migrate Core Data entities
         migrateTasksToUser(userId)
         migrateHobbiesToUser(userId)
         migrateHobbyEntriesToUser(userId)
         
         // Mark as migrated
         UserDefaults.standard.set(true, forKey: "dataMigratedForUser_\(userId)")
     }
     
     func migrateTasksToUser(_ userId: String) {
         let context = CoreDataService.shared.viewContext
         let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
         fetchRequest.predicate = NSPredicate(format: "userId == nil")
         
         if let tasks = try? context.fetch(fetchRequest) {
             for task in tasks {
                 task.userId = userId
             }
             try? context.save()
         }
     }
     
     func migrateHobbiesToUser(_ userId: String) {
         let context = CoreDataService.shared.viewContext
         let fetchRequest: NSFetchRequest<Hobby> = Hobby.fetchRequest()
         fetchRequest.predicate = NSPredicate(format: "userId == nil")
         
         if let hobbies = try? context.fetch(fetchRequest) {
             for hobby in hobbies {
                 hobby.userId = userId
             }
             try? context.save()
         }
     }
     
    func migrateHobbyEntriesToUser(_ userId: String) {
        let context = CoreDataService.shared.viewContext
        let fetchRequest: NSFetchRequest<HobbyEntry> = HobbyEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == nil")
        
        if let entries = try? context.fetch(fetchRequest) {
            for entry in entries {
                entry.userId = userId
            }
            try? context.save()
        }
    }
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted")
                
                // Schedule quote notifications if enabled
                if UserDefaults.standard.bool(forKey: "isQuoteNotificationsEnabled") {
                    Task {
                        await NotificationService.shared.scheduleQuoteNotifications()
                    }
                }
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // You could navigate to a specific screen when a notification is tapped
        completionHandler()
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


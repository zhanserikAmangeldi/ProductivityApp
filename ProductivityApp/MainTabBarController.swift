//
//  MainTabBarController.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        
        let pomodoroVC = UIHostingController(rootView: Text("Pomdoro timer coming soon"))
        let todoVC = UIHostingController(rootView: Text("Todo list coming soon"))
        let hobbyVC = UIHostingController(rootView: HobbyListView())
        let settingsVC = UIHostingController(rootView: SettingsView())
        
        pomodoroVC.tabBarItem = UITabBarItem(
            title: "Pomodoro",
            image: UIImage(systemName: "timer"),
            selectedImage: UIImage(systemName: "timer.fill")
        )
        
        todoVC.tabBarItem = UITabBarItem(
            title: "To-Do",
            image: UIImage(systemName: "checklist"),
            selectedImage: UIImage(systemName: "checklist.checked")
         )
         
        hobbyVC.tabBarItem = UITabBarItem(
            title: "Hobbies",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
         
        settingsVC.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear.fill")
        )
        
        self.viewControllers = [pomodoroVC, todoVC, hobbyVC, settingsVC]
    }
    
    private func createHostingController<Content: View>(for rootView: Content) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: rootView)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        hostingController.view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        hostingController.view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        hostingController.view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        return hostingController
    }
}

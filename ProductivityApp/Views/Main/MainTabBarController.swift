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
        applyCurrentTheme()
        
        NotificationCenter.default.addObserver(
            forName: ThemeManager.themeChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let theme = notification.object as? AppTheme else { return }
            
            self.applyTheme(theme)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func applyCurrentTheme() {
        applyTheme(ThemeManager.shared.currentTheme)
    }
    
    private func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.uiInterfaceStyle
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func prepareForRemoval() {
        print("MainTabBarController - prepareForRemoval called")
        
        if let pomodoroVC = viewControllers?[0] as? UIHostingController<PomodoroTimerView> {
            let pomodoroView = pomodoroVC.rootView
            
            if let mirror = Mirror(reflecting: pomodoroView).children.first(where: { $0.label == "viewModel" }),
               let viewModel = mirror.value as? PomodoroViewModel {
                viewModel.prepareForDismissal()
            } else {
                print("Could not access PomodoroViewModel for cleanup")
            }
        }
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupTabs() {
        
        let pomodoroVC = UIHostingController(rootView: PomodoroTimerView())
        let todoVC = UIHostingController(rootView: TodoListView())
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

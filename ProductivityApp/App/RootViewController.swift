//
//  RootViewController.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import SwiftUI
import UIKit
import Combine

class RootViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Add theme observer
        NotificationCenter.default.addObserver(
            forName: ThemeManager.themeChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let theme = notification.object as? AppTheme else { return }
            
            self.view.window?.overrideUserInterfaceStyle = theme.uiInterfaceStyle
        }
        
        AuthenticationManager.shared.$authState.sink { [weak self] state in
            switch state {
            case .loggedIn:
                self?.showMainFlow()
            case .loggedOut:
                self?.clearUserCaches()
                self?.showAuthenticationFlow()
            }
        }
        .store(in: &cancellables)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func clearUserCaches() {
        // Perform on main thread to be safe
        DispatchQueue.main.async {
            QuotesService.shared.clearCache()
        }
    }
    
    private func showAuthenticationFlow() {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showAuthenticationFlow()
            }
            return
        }
        
        print("RootViewController - showAuthenticationFlow called")
        
        // First properly clean up any MainTabBarController
        for child in children {
            if let mainTabBar = child as? MainTabBarController {
                print("Found MainTabBarController, preparing for removal")
                mainTabBar.prepareForRemoval()
            }
            
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        // Apply current theme to this view controller's window
        self.view.window?.overrideUserInterfaceStyle = ThemeManager.shared.currentTheme.uiInterfaceStyle
        
        // Create the SwiftUI authentication view
        let authenticationView = SignInEmailView()
        
        // Embed it in a UIHostingController
        let hostingController = UIHostingController(rootView: NavigationStack {
            authenticationView
        })
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Configure constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        print("AuthenticationFlow setup completed")
    }
    
    private func showMainFlow() {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showMainFlow()
            }
            return
        }
        
        print("RootViewController - showMainFlow called")
        
        // Remove any existing child view controllers
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        let mainTabBarController = MainTabBarController()
        
        // Add as child view controller
        addChild(mainTabBarController)
        mainTabBarController.view.frame = view.bounds
        view.addSubview(mainTabBarController.view)
        
        // Configure constraints
        mainTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mainTabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainTabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        mainTabBarController.didMove(toParent: self)
        
        print("MainFlow setup completed")
    }
}

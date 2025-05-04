//
//  AppCordinator.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import UIKit
import SwiftUI
import Combine

class AppCordinator {
    private let window: UIWindow
    private let navigationController: UINavigationController
    private let cancellables = Set<AnyCancellable>()
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        startAuthenticationFlow()
    }
    
    private func startAuthenticationFlow() {
        // Create the SwiftUI authentication view
        let authenticationView = AuthenticationView()
        
        // Embed it in a UIHostingController
        let hostingController = UIHostingController(rootView: NavigationStack {
            authenticationView
        })
        
        navigationController.setViewControllers([hostingController], animated: false)
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserDidAuthenticate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showMainApp()
        }
    }
    
    func showMainApp() {
        
        let mainViewController = ViewController()
        navigationController.setViewControllers( [mainViewController], animated: false)
    }
}

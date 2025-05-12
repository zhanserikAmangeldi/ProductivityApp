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
    
    private func clearUserCaches() {
        QuotesService.shared.clearCache()
    }
    
    private func showAuthenticationFlow() {
        // Remove any existing child view controllers
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
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
    }
    
    private func showMainFlow() {
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
    }
}

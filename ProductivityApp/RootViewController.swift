//
//  RootViewController.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import SwiftUI
import UIKit

class RootViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupAuthenticationFlow()
    }
    
    private func setupAuthenticationFlow() {
        // Create the SwiftUI authentication view
        let authenticationView = AuthenticationView()
        
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
}

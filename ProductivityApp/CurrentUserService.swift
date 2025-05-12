//
//  CurrentUserService.swift
//  ProductivityApp
//
//  Created by Kassiman Alikhan on 12.05.2025.
//

import Foundation
import FirebaseAuth
import Combine

class CurrentUserService {
    static let shared = CurrentUserService()
    
    @Published var currentUserId: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        AuthenticationManager.shared.$authState
            .sink { [weak self] state in
                switch state {
                case .loggedIn:
                    do {
                        let user = try AuthenticationManager.shared.getUser()
                        self?.currentUserId = user.uid
                    } catch {
                        self?.currentUserId = nil
                        print("Error getting current user: \(error)")
                    }
                case .loggedOut:
                    self?.currentUserId = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func getUserSpecificKey(for key: String) -> String {
        guard let userId = currentUserId else {
            return key // Fallback to regular key if not logged in
        }
        return "user_\(userId)_\(key)"
    }
}


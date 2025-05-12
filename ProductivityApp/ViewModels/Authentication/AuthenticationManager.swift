//
//  AuthenticationManager.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import Foundation
import FirebaseAuth
import Combine

struct AuthDateResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
    }
}

enum AuthenticationState {
    case loggedIn
    case loggedOut
}

final class AuthenticationManager {
    
    
    static let shared = AuthenticationManager()
    
    private init() {
        setupAuthStateListener()
    }
    
    @Published var authState: AuthenticationState = .loggedOut
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.authState = user != nil ? .loggedIn : .loggedOut
        }
    }
    
    func getUser() throws -> AuthDateResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return AuthDateResultModel(user: user)
    }
    
    func createUser(email: String, password: String) async throws -> AuthDateResultModel {
        let authDateResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDateResultModel(user: authDateResult.user)
    }
    
    func signIn(email: String, password: String) async throws -> AuthDateResultModel {
        let authDateResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDateResultModel(user: authDateResult.user)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
}

//
//  AuthenticationManager.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import Foundation
import FirebaseAuth

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

final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    private init() {}
    
    func createUser(email: String, password: String) async throws -> AuthDateResultModel {
        let authDateResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDateResultModel(user: authDateResult.user)
    }
    
    
}

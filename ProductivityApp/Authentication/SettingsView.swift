//
//  SettingsView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 05.05.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var email: String = ""
    @State private var errorMessage: String?
    
    init() {
        // Will try to get the current user's email
        do {
            let user = try AuthenticationManager.shared.getUser()
            _email = State(initialValue: user.email ?? "No Email")
        } catch {
            _email = State(initialValue: "Error retrieving user")
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome!")
                    .font(.largeTitle)
                
                Text("You are signed in as: \(email)")
                    .font(.headline)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    // Sign out
                    do {
                        try AuthenticationManager.shared.signOut()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(20)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

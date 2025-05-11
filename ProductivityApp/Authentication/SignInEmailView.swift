//
//  SignInEmailView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import SwiftUI

@MainActor
final class SignInEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email or Password is not valid!"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let returnedUserData = try await AuthenticationManager.shared.signIn(email: email, password: password)
                print("Successfully signed in user: \(returnedUserData.uid)")
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func createAccount() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email or Password is not valid!"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let returnedUserData = try await AuthenticationManager.shared.createUser(email: email, password: password)
                print("Successfully created user: \(returnedUserData.uid)")
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}

struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 15) {
            TextField("Email...", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(25)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password...", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(25)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }
            
            if viewModel.isLoading {
                LoadingDotsView()
                    .padding(.vertical, 10)
            }
            
            Button {
                viewModel.signIn()
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .disabled(viewModel.isLoading)
            }
            
            Button {
                viewModel.createAccount()
            } label: {
                Text("Create Account")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(20)
                    .disabled(viewModel.isLoading)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign in with Email")
    }
}

#Preview {
    NavigationStack{
        SignInEmailView()
    }
}

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
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    func SignIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email or Password is not valid!"
            return
        }
        
        Task {
            do {
                let returnedUserData = try await AuthenticationManager.shared.createUser(email: email, password: password)
                isAuthenticated = true
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
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
            
            Button {
                viewModel.SignIn()
            } label : {
                Text("Sign In")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign in with Email")
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                NotificationCenter.default.post(name: NSNotification.Name("UserDidAuthenticate"), object: nil)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack{
        SignInEmailView()
    }
}

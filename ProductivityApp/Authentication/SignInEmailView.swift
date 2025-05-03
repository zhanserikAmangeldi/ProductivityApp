//
//  SignInEmailView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import SwiftUI

final class SignInEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
}

struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
    
    var body: some View {
        VStack {
            TextField("Email...", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(25)
            SecureField("Password...", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(25)
            
            Button {
                
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
    }
}

#Preview {
    NavigationStack{
        SignInEmailView()
    }
}

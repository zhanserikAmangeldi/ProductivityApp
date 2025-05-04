//
//  AuthenticationView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 04.05.2025.
//

import SwiftUI

struct AuthenticationView: View {
    var body: some View {
        VStack{
            NavigationLink {
                SignInEmailView()
            } label: {
                Text("Sign In with Email")
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
        .navigationTitle(Text("Sign In"))
    }
}

#Preview {
    AuthenticationView()
}

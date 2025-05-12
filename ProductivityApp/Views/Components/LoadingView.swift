//
//  LoadingView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 11.05.2025.
//

import SwiftUI
import Lottie

struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 15) {
            LottieView(name: "lottie-animation")
                .frame(width: 100, height: 100)
            
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(message: "Loading...")
    }
}

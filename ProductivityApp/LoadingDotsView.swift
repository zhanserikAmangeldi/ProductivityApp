//
//  LoadingDotsView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 11.05.2025.
//


import SwiftUI

struct LoadingDotsView: View {
    @State private var isAnimating = false
    private let numberOfDots = 4
    private let dotSize: CGFloat = 10
    private let expandedDotSize: CGFloat = 16
    private let spacing: CGFloat = 8
    private let animationDuration: Double = 0.4
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfDots, id: \.self) { index in
                Circle()
                    .fill(Color.blue)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(x: getScaleForDot(at: index), y: 1)
                    .animation(
                        Animation
                            .easeInOut(duration: animationDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * (animationDuration / Double(numberOfDots))),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func getScaleForDot(at index: Int) -> CGFloat {
        if isAnimating {
            return expandedDotSize / dotSize
        }
        return 1.0
    }
}

#Preview {
    LoadingDotsView()
        .padding()
        .previewLayout(.sizeThatFits)
}

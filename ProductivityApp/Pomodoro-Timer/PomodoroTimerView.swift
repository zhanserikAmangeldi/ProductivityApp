//
//  PomodoroTimerView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI

struct PomodoroTimerView: View {
    @StateObject private var viewModel = PomodoroViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Session info
                timerInfoView
                
                // Timer circle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(timerTypeColor.opacity(0.5))
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0.0, to: CGFloat(viewModel.progress))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(timerTypeColor)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: viewModel.progress)
                    
                    // Time text
                    VStack(spacing: 10) {
                        Text(viewModel.formattedTimeString())
                            .font(.system(size: 70, weight: .bold, design: .rounded))
                            .foregroundColor(timerTypeColor)
                        
                        Text(timerTypeText)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 300, height: 300)
                .padding(.vertical, 20)
                
                // Control buttons
                timerControlButtons
                
                Spacer()
            }
            .padding()
            .navigationTitle("Pomodoro Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                PomodoroSettingsView()
            }
            .onAppear {
                // Request notification permissions
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, error in
                    if let error = error {
                        print("Error requesting notification permissions: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var timerInfoView: some View {
        HStack(spacing: 30) {
            VStack {
                Text("Round")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.currentRound)")
                    .font(.title2.bold())
            }
            
            Divider().frame(height: 30)
            
            VStack {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(timerStatusText)
                    .font(.title2.bold())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var timerControlButtons: some View {
        HStack(spacing: 30) {
            // Reset button
            Button(action: {
                viewModel.resetTimer()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title)
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            
            // Main action button (start/pause)
            Button(action: {
                if viewModel.timerMode == .running {
                    viewModel.pauseTimer()
                } else {
                    viewModel.startTimer()
                }
            }) {
                Image(systemName: viewModel.timerMode == .running ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(timerTypeColor)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            
            // Skip button
            Button(action: {
                viewModel.skipToNext()
            }) {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Helper Computed Properties
    
    private var timerTypeColor: Color {
        switch viewModel.timerType {
        case .focus:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
    
    private var timerTypeText: String {
        switch viewModel.timerType {
        case .focus:
            return "Focus Time"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
    
    private var timerStatusText: String {
        switch viewModel.timerMode {
        case .initial:
            return "Ready"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .finished:
            return "Finished"
        }
    }
}

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
    }
}

//
//  PomodoroStatsView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI

struct PomodoroStatsView: View {
    @State private var session: PomodoroSession
    @State private var showResetConfirmation = false
    
    init() {
        _session = State(initialValue: PomodoroSettingsManager.shared.session)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Session Statistics")) {
                StatRow(
                    title: "Focus Sessions",
                    value: "\(session.completedFocusSessions)",
                    icon: "timer",
                    color: .red
                )
                
                StatRow(
                    title: "Short Breaks",
                    value: "\(session.completedShortBreaks)",
                    icon: "cup.and.saucer",
                    color: .green
                )
                
                StatRow(
                    title: "Long Breaks",
                    value: "\(session.completedLongBreaks)",
                    icon: "figure.walk",
                    color: .blue
                )
                
                StatRow(
                    title: "Total Focus Time",
                    value: formatTimeString(session.totalFocusTime),
                    icon: "clock",
                    color: .purple
                )
            }
            
            if let lastDate = session.lastCompletedDate {
                Section(header: Text("Last Activity")) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        Text("Last completed session")
                        Spacer()
                        Text(formatDate(lastDate))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button("Reset Statistics") {
                    showResetConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Pomodoro Stats")
        .alert("Reset Statistics", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetStats()
            }
        } message: {
            Text("Are you sure you want to reset all statistics? This action cannot be undone.")
        }
    }
    
    private func formatTimeString(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func resetStats() {
        PomodoroSettingsManager.shared.resetSession()
        session = PomodoroSettingsManager.shared.session
    }
}

// MARK: - Stats Row View

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
        }
    }
}

struct PomodoroStatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PomodoroStatsView()
        }
    }
}

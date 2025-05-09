//
//  PomodoroSettingsView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI
import Combine

struct PomodoroSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings: PomodoroSettings
    @State private var showingResetAlert = false
    
    private let settingsManager = PomodoroSettingsManager.shared
    
    // Time range values (in minutes)
    private let focusTimeRange = 5...120
    private let shortBreakTimeRange = 1...30
    private let longBreakTimeRange = 5...60
    private let roundsRange = 1...10
    
    init() {
        _settings = State(initialValue: PomodoroSettingsManager.shared.settings)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Timer Durations")) {
                    // Focus duration
                    HStack {
                        Text("Focus Time")
                        Spacer()
                        Text("\(Int(settings.focusDuration / 60)) min")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { settings.focusDuration / 60 },
                            set: { settings.focusDuration = $0 * 60 }
                        ),
                        in: Double(focusTimeRange.lowerBound)...Double(focusTimeRange.upperBound),
                        step: 1
                    )
                    .accentColor(.red)
                    
                    // Short break duration
                    HStack {
                        Text("Short Break")
                        Spacer()
                        Text("\(Int(settings.shortBreakDuration / 60)) min")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { settings.shortBreakDuration / 60 },
                            set: { settings.shortBreakDuration = $0 * 60 }
                        ),
                        in: Double(shortBreakTimeRange.lowerBound)...Double(shortBreakTimeRange.upperBound),
                        step: 1
                    )
                    .accentColor(.green)
                    
                    // Long break duration
                    HStack {
                        Text("Long Break")
                        Spacer()
                        Text("\(Int(settings.longBreakDuration / 60)) min")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { settings.longBreakDuration / 60 },
                            set: { settings.longBreakDuration = $0 * 60 }
                        ),
                        in: Double(longBreakTimeRange.lowerBound)...Double(longBreakTimeRange.upperBound),
                        step: 1
                    )
                    .accentColor(.blue)
                    
                    // Rounds before long break
                    Stepper(value: $settings.roundsBeforeLongBreak, in: roundsRange) {
                        HStack {
                            Text("Rounds Before Long Break")
                            Spacer()
                            Text("\(settings.roundsBeforeLongBreak)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Automation")) {
                    Toggle("Auto-start Breaks", isOn: $settings.autoStartBreaks)
                    Toggle("Auto-start Focus", isOn: $settings.autoStartFocus)
                }
                
                Section(header: Text("Sound")) {
                    Toggle("Enable Metronome", isOn: $settings.enableMetronome)
                        .tint(.purple)
                }
                
                Section {
                    Button("Reset to Default Settings") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Statistics")) {
                    NavigationLink(destination: PomodoroStatsView()) {
                        Text("View Statistics")
                    }
                }
            }
            .navigationTitle("Pomodoro Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings = PomodoroSettings.defaultSettings
                }
            } message: {
                Text("Are you sure you want to reset all settings to their default values?")
            }
        }
    }
    
    private func saveSettings() {
        settingsManager.settings = settings
        settingsManager.saveSettings()
    }
}

struct PomodoroSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroSettingsView()
    }
}

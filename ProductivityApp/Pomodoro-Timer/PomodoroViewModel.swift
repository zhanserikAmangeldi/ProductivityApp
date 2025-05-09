//
//  PomodroViewModel.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import Combine
import UserNotifications
import AVFoundation

@MainActor
class PomodoroViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var timerMode: TimerMode = .initial
    @Published var timerType: TimerType = .focus
    @Published var remainingSeconds: TimeInterval
    @Published var progress: Double = 1.0
    @Published var currentRound: Int = 1
    @Published var errorMessage: String?
    
    // Private properties
    private var settingsManager = PomodoroSettingsManager.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var totalSeconds: TimeInterval
    private var metronomePlayer: AVAudioPlayer?
    private var metronomeSoundURL: URL? {
        Bundle.main.url(forResource: "metronome", withExtension: "mp3")
    }
    
    init() {
        // Initialize with settings
        self.totalSeconds = settingsManager.settings.focusDuration
        self.remainingSeconds = totalSeconds
        
        // Listen for settings changes
        settingsManager.$settings
            .sink { [weak self] newSettings in
                guard let self = self else { return }
                if self.timerMode == .initial {
                    if self.timerType == .focus {
                        self.totalSeconds = newSettings.focusDuration
                    } else if self.timerType == .shortBreak {
                        self.totalSeconds = newSettings.shortBreakDuration
                    } else {
                        self.totalSeconds = newSettings.longBreakDuration
                    }
                    self.remainingSeconds = self.totalSeconds
                    self.updateProgress()
                }
                
                // Toggle metronome if needed
                if newSettings.enableMetronome && self.timerMode == .running {
                    self.startMetronome()
                } else {
                    self.stopMetronome()
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        print("PomodoroViewModel deinit called")
        if let timer = timer {
            timer.invalidate()
        }
        self.timer = nil
        self.metronomePlayer?.stop()
        self.metronomePlayer = nil
        
        cancellables.removeAll()
        
        print("PomodoroViewModel deinit completed")
    }
    
    // MARK: - Timer Control Functions
    
    func startTimer() {
        if timerMode == .initial || timerMode == .paused {
            timerMode = .running
            
            // Start metronome if enabled
            if settingsManager.settings.enableMetronome {
                startMetronome()
            }
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.updateProgress()
                } else {
                    self.timerMode = .finished
                    self.stopTimer()
                    self.stopMetronome()
                    self.handleTimerCompletion()
                }
            }
        }
    }
    
    func pauseTimer() {
        timerMode = .paused
        stopTimer()
        stopMetronome()
    }
    
    func resetTimer() {
        stopTimer()
        stopMetronome()
        timerMode = .initial
        remainingSeconds = totalSeconds
        updateProgress()
    }
    
    func skipToNext() {
        stopTimer()
        stopMetronome()
        
        // Handle completion based on current type
        if timerType == .focus {
            handleFocusCompletion()
        } else if timerType == .shortBreak || timerType == .longBreak {
            handleBreakCompletion()
        }
    }
    
    // MARK: - Helper Functions
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        progress = remainingSeconds / totalSeconds
    }
    
    private func handleTimerCompletion() {
        if timerType == .focus {
            handleFocusCompletion()
        } else {
            handleBreakCompletion()
        }
    }
    
    private func handleFocusCompletion() {
        // Update session data
        settingsManager.updateCompletedFocusSession(duration: settingsManager.settings.focusDuration)
        
        // Show notification
        showNotification(title: "Focus session completed!", body: "Time for a break.")
        
        // Determine next timer type
        if currentRound % settingsManager.settings.roundsBeforeLongBreak == 0 {
            switchToTimerType(.longBreak)
        } else {
            switchToTimerType(.shortBreak)
        }
        
        // Auto start break if enabled
        if settingsManager.settings.autoStartBreaks {
            startTimer()
        }
    }
    
    private func handleBreakCompletion() {
        // Update session data
        settingsManager.updateCompletedBreak(isLongBreak: timerType == .longBreak)
        
        // Show notification
        showNotification(title: "Break completed!", body: "Ready for next focus session?")
        
        // If it was a long break, increment the round
        if timerType == .longBreak {
            currentRound += 1
        }
        
        // Switch to focus mode
        switchToTimerType(.focus)
        
        // Auto start focus if enabled
        if settingsManager.settings.autoStartFocus {
            startTimer()
        }
    }
    
    private func switchToTimerType(_ type: TimerType) {
        timerType = type
        timerMode = .initial
        
        // Set duration based on timer type
        switch type {
        case .focus:
            totalSeconds = settingsManager.settings.focusDuration
        case .shortBreak:
            totalSeconds = settingsManager.settings.shortBreakDuration
        case .longBreak:
            totalSeconds = settingsManager.settings.longBreakDuration
        }
        
        remainingSeconds = totalSeconds
        updateProgress()
    }
    
    // MARK: - Notification Functions
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Metronome Functions
    
    private func startMetronome() {
        guard settingsManager.settings.enableMetronome else { return }
        
        // Create and start the metronome sound if URL exists
        guard let soundURL = metronomeSoundURL else {
            print("Metronome sound file not found")
            return
        }
        
        do {
            metronomePlayer = try AVAudioPlayer(contentsOf: soundURL)
            metronomePlayer?.numberOfLoops = -1 // Loop indefinitely
            metronomePlayer?.volume = 0.5
            metronomePlayer?.play()
        } catch {
            print("Failed to play metronome sound: \(error.localizedDescription)")
        }
    }
    
    private func stopMetronome() {
        metronomePlayer?.stop()
        metronomePlayer = nil
    }
    
    // MARK: - Formatted Time String
    
    func formattedTimeString() -> String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

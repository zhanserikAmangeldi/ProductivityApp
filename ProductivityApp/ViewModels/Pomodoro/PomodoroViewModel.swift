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
    
    // Background mode properties
    private var timerEndDate: Date?
    private let timerNotificationIdentifier = "pomodoro_timer_notification"
    
    // Task management
    private var taskList = Set<Task<Void, Never>>()
    
    init() {
        print("PomodoroViewModel init called")
        // Initialize with settings
        self.totalSeconds = settingsManager.settings.focusDuration
        self.remainingSeconds = totalSeconds
        
        // Initialize the round counter based on completed sessions
        let completedFocusSessions = settingsManager.session.completedFocusSessions
        self.currentRound = (completedFocusSessions / settingsManager.settings.roundsBeforeLongBreak) + 1
        
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
                
                // Update round calculation when settings change
                let completedFocusSessions = self.settingsManager.session.completedFocusSessions
                self.currentRound = (completedFocusSessions / newSettings.roundsBeforeLongBreak) + 1
            }
            .store(in: &cancellables)
    }
    
    deinit {
        print("PomodoroViewModel deinit called")
        
        // Cancel all tasks first
        for task in taskList {
            task.cancel()
        }
        taskList.removeAll()
        
        // Then stop timer
        if let timer = timer {
            timer.invalidate()
        }
        self.timer = nil
        self.metronomePlayer?.stop()
        self.metronomePlayer = nil
        
        cancellables.removeAll()
        
        // Cancel any pending notifications directly
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [timerNotificationIdentifier]
        )
        
        print("PomodoroViewModel deinit completed")
    }
    
    // Public cleanup method for view controller transitions
    func prepareForDismissal() {
        print("prepareForDismissal called")
        // Stop everything and cancel all tasks
        stopTimer()
        stopMetronome()
        
        // Explicitly cancel all tasks
        for task in taskList {
            task.cancel()
        }
        taskList.removeAll()
        
        // Cancel notification directly
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [timerNotificationIdentifier]
        )
        
        // Remove all cancellables
        cancellables.removeAll()
    }
    
    // MARK: - Timer Control Functions
    
    func startTimer() {
        if timerMode == .initial || timerMode == .paused {
            timerMode = .running
            
            // Calculate end date and store it for background tracking
            timerEndDate = Date().addingTimeInterval(remainingSeconds)
            
            // Schedule a notification for when the timer ends
            if let endDate = timerEndDate {
                scheduleTimerEndNotificationSafely(endDate: endDate, type: timerType)
            }
            
            // Start metronome if enabled
            if settingsManager.settings.enableMetronome {
                startMetronome()
            }
            
            // Create and start the timer on the main thread
            self.timer?.invalidate() // Safety: invalidate any existing timer
            
            self.timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                // Dispatch to main thread to ensure UI updates
                DispatchQueue.main.async { [weak self] in
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
            
            // Make sure we use the common run loop mode for better UI responsiveness
            RunLoop.main.add(self.timer!, forMode: .common)
        }
    }
    
    // Safe wrapper for scheduleTimerEndNotification
    private func scheduleTimerEndNotificationSafely(endDate: Date, type: TimerType) {
        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.scheduleTimerEndNotification(endDate: endDate, type: type)
        }
        taskList.insert(task)
    }
    
    func pauseTimer() {
        // First invalidate the timer to ensure countdown stops immediately
        stopTimer()
        
        // Then update the UI state
        timerMode = .paused
        
        // Stop metronome
        stopMetronome()
        
        // Cancel notification but don't wait for it to complete
        cancelTimerEndNotificationSafely()
    }
    
    func resetTimer() {
        stopTimer()
        stopMetronome()
        timerMode = .initial
        remainingSeconds = totalSeconds
        updateProgress()
        
        cancelTimerEndNotificationSafely()
        
        timerEndDate = nil
    }
    
    func skipToNext() {
        stopTimer()
        stopMetronome()
        
        cancelTimerEndNotificationSafely()
        
        timerEndDate = nil
        
        // Handle completion based on current type
        if timerType == .focus {
            handleFocusCompletion()
        } else if timerType == .shortBreak || timerType == .longBreak {
            handleBreakCompletion()
        }
    }
    
    // MARK: - Background Mode Functions
    
    private func scheduleTimerEndNotification(endDate: Date, type: TimerType) async {
        // Cancel any existing timer notifications first
        await cancelTimerEndNotification()
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        // Set title and message based on timer type
        if type == .focus {
            content.title = "Focus session completed!"
            content.body = "Time for a break."
        } else if type == .shortBreak {
            content.title = "Short break completed!"
            content.body = "Ready for next focus session?"
        } else {
            content.title = "Long break completed!"
            content.body = "Ready for next focus session?"
        }
        
        content.sound = .default
        
        // Create trigger based on timer end date
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: timerNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Error scheduling timer notification: \(error.localizedDescription)")
        }
    }
    
    // Safe wrapper for cancelTimerEndNotification
    private func cancelTimerEndNotificationSafely() {
        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.cancelTimerEndNotification()
        }
        taskList.insert(task)
    }
    
    private func cancelTimerEndNotification() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerNotificationIdentifier])
    }
    
    func checkTimerStatus() {
        guard timerMode == .running, let endDate = timerEndDate else { return }
        
        if Date() >= endDate {
            // Timer should have completed
            timerMode = .finished
            remainingSeconds = 0
            updateProgress()
            handleTimerCompletion()
        } else {
            // Timer is still running, update remaining time
            remainingSeconds = max(0, endDate.timeIntervalSinceNow)
            updateProgress()
        }
    }
    
    // MARK: - Helper Functions
    
    private func stopTimer() {
        if let timer = self.timer, timer.isValid {
            timer.invalidate()
        }
        self.timer = nil
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
        showNotificationSafely(
            title: "Focus session completed!",
            body: "Time for a break."
        )
        
        // Increment the completed focus sessions count for round tracking
        let completedFocusSessions = settingsManager.session.completedFocusSessions
        
        // Determine next timer type based on completed sessions
        // We need to use the total completed sessions, not just the current round
        if completedFocusSessions > 0 && completedFocusSessions % settingsManager.settings.roundsBeforeLongBreak == 0 {
            switchToTimerType(.longBreak)
        } else {
            switchToTimerType(.shortBreak)
        }
        
        // Update the current round display - add 1 because we're counting from 1, not 0
        currentRound = (completedFocusSessions / settingsManager.settings.roundsBeforeLongBreak) + 1
        
        // Auto start break if enabled
        if settingsManager.settings.autoStartBreaks {
            startTimer()
        }
    }
    
    private func handleBreakCompletion() {
        // Update session data
        settingsManager.updateCompletedBreak(isLongBreak: timerType == .longBreak)
        
        // Show notification
        showNotificationSafely(
            title: "Break completed!",
            body: "Ready for next focus session?"
        )
        
        // We don't need to increment rounds here anymore as it's now handled based on total completed sessions
        
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
    
    // Safe wrapper for showNotification
    private func showNotificationSafely(title: String, body: String) {
        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.showNotification(title: title, body: body)
        }
        taskList.insert(task)
    }
    
    private func showNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error showing notification: \(error.localizedDescription)")
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

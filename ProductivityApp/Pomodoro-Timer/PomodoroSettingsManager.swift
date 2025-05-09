//
//  PomodoroSettingsManager.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import Combine

class PomodoroSettingsManager {
    static let shared = PomodoroSettingsManager()
    
    private let settingsKey = "pomodoro_settings"
    private let sessionKey = "pomodoro_session"
    
    @Published var settings: PomodoroSettings
    @Published var session: PomodoroSession
    
    private init() {
        // Load settings from UserDefaults or use default
        if let savedSettingsData = UserDefaults.standard.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(PomodoroSettings.self, from: savedSettingsData) {
            self.settings = decodedSettings
        } else {
            self.settings = PomodoroSettings.defaultSettings
        }
        
        // Load session from UserDefaults or use default
        if let savedSessionData = UserDefaults.standard.data(forKey: sessionKey),
           let decodedSession = try? JSONDecoder().decode(PomodoroSession.self, from: savedSessionData) {
            self.session = decodedSession
        } else {
            self.session = PomodoroSession.newSession
        }
    }
    
    func saveSettings() {
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encodedSettings, forKey: settingsKey)
        }
    }
    
    func saveSession() {
        if let encodedSession = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encodedSession, forKey: sessionKey)
        }
    }
    
    func updateCompletedFocusSession(duration: TimeInterval) {
        session.completedFocusSessions += 1
        session.totalFocusTime += duration
        session.lastCompletedDate = Date()
        saveSession()
    }
    
    func updateCompletedBreak(isLongBreak: Bool) {
        if isLongBreak {
            session.completedLongBreaks += 1
        } else {
            session.completedShortBreaks += 1
        }
        saveSession()
    }
    
    func resetSession() {
        session = PomodoroSession.newSession
        saveSession()
    }
}

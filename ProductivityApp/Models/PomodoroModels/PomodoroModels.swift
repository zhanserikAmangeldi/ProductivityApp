//
//  PomodoroModels.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation

enum TimerMode {
    case initial
    case running
    case paused
    case finished
}

enum TimerType {
    case focus
    case shortBreak
    case longBreak
}

struct PomodoroSettings: Codable {
    var focusDuration: TimeInterval // in minutes
    var shortBreakDuration: TimeInterval // in minutes
    var longBreakDuration: TimeInterval // in minutes
    var autoStartBreaks: Bool
    var autoStartFocus: Bool
    var enableMetronome: Bool
    var roundsBeforeLongBreak: Int
    
    static var defaultSettings: PomodoroSettings {
        PomodoroSettings(
            focusDuration: 25 * 60, // 25 minutes in seconds
            shortBreakDuration: 5 * 60, // 5 minutes in seconds
            longBreakDuration: 15 * 60, // 15 minutes in seconds
            autoStartBreaks: true,
            autoStartFocus: false,
            enableMetronome: false,
            roundsBeforeLongBreak: 4
        )
    }
}

struct PomodoroSession: Codable {
    var completedFocusSessions: Int
    var completedShortBreaks: Int
    var completedLongBreaks: Int
    var totalFocusTime: TimeInterval // in seconds
    var lastCompletedDate: Date?
    
    static var newSession: PomodoroSession {
        PomodoroSession(
            completedFocusSessions: 0,
            completedShortBreaks: 0,
            completedLongBreaks: 0,
            totalFocusTime: 0,
            lastCompletedDate: nil
        )
    }
}

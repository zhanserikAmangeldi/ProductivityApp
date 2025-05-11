//
//  SettingsView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 05.05.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var isDarkModeEnabled: Bool = false
    @State private var isNotificationsEnabled: Bool = false
    @State private var showingHowItWorks = false
    @State private var showingAbout = false
    
    init() {
        // Will try to get the current user's email
        do {
            let user = try AuthenticationManager.shared.getUser()
            _email = State(initialValue: user.email ?? "No Email")
        } catch {
            _email = State(initialValue: "Error retrieving user")
        }
        
        // Load settings from UserDefaults
        _isDarkModeEnabled = State(initialValue: UserDefaults.standard.bool(forKey: "isDarkModeEnabled"))
        _isNotificationsEnabled = State(initialValue: UserDefaults.standard.bool(forKey: "isNotificationsEnabled"))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    Text("Signed in as: \(email)")
                        .font(.subheadline)
                    
                    Button(action: {
                        signOut()
                    }) {
                        HStack {
                            Text("Sign Out")
                            Spacer()
                            Image(systemName: "arrow.right.square")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("App Settings")) {
                    Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                        .onChange(of: isDarkModeEnabled) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "isDarkModeEnabled")
                            // TODO: Apply the mode change
                        }
                    
                    Toggle("Enable Notifications", isOn: $isNotificationsEnabled)
                        .onChange(of: isNotificationsEnabled) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "isNotificationsEnabled")
                            
                            NotificationService.shared.recheckNotificationSettings()

                            if newValue {
                                requestNotificationPermissions()
                            }
                        }
                }
                
                Section(header: Text("Pomodoro Settings")) {
                    NavigationLink(destination: PomodoroSettingsView()) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.red)
                                .frame(width: 30)
                            Text("Pomodoro Timer Settings")
                        }
                    }
                }
                
                Section(header: Text("Motivational Quotes")) {
                    NavigationLink(destination: QuoteSettingsView()) {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("Motivational Quotes Settings")
                        }
                    }
                }
                
                Section(header: Text("Information")) {
                    Button(action: {
                        showingHowItWorks = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("How it Works")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("About")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingHowItWorks) {
                HowItWorksView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - How It Works View

struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("How to Use the Productivity App")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Pomodoro Timer Section
                        Text("Pomodoro Timer")
                            .font(.headline)
                        
                        Text("The Pomodoro Technique is a time management method that uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks.")
                        
                        Text("1. Start a focus session (default: 25 minutes)")
                        Text("2. Take a short break (default: 5 minutes)")
                        Text("3. After 4 sessions, take a longer break (default: 15 minutes)")
                        Text("4. Customize the durations in settings")
                        
                        // To-Do List Section
                        Text("To-Do List")
                            .font(.headline)
                        
                        Text("Keep track of your tasks with our simple to-do list:")
                        Text("1. Add tasks with priorities and due dates")
                        Text("2. Mark tasks as completed")
                        Text("3. Filter by status or priority")
                        Text("4. Get reminders for upcoming tasks")
                    }
                    
                    Group {
                        // Hobby Tracker Section
                        Text("Hobby Tracker")
                            .font(.headline)
                        
                        Text("Track time spent on your favorite hobbies:")
                        Text("1. Create custom hobby categories")
                        Text("2. Log time manually or use a timer")
                        Text("3. View statistics and trends")
                        Text("4. Set goals for consistent practice")
                        
                        // Settings Section
                        Text("Settings")
                            .font(.headline)
                        
                        Text("Customize the app to suit your workflow:")
                        Text("1. Change timer durations and behavior")
                        Text("2. Enable or disable notifications")
                        Text("3. Toggle dark mode")
                        Text("4. View your statistics")
                    }
                }
                .padding()
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - About Our Application View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "app.badge.checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Productivity App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text("This app was created as a final project for the iOS Advanced course.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("© 2025 Zhanserik Amangeldi")
                    .font(.caption)
                    .padding(.top, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

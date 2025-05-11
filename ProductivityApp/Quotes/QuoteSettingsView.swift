//
//  QuoteSettingsView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 11.05.2025.
//

import SwiftUI

class QuoteSettingsViewModel: ObservableObject {
    @Published var isQuoteNotificationsEnabled: Bool
    @Published var notificationFrequency: Int
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var areGeneralNotificationsEnabled: Bool
    
    private let notificationService = NotificationService.shared
    
    init() {
        self.areGeneralNotificationsEnabled = UserDefaults.standard.bool(forKey: "isNotificationsEnabled")
        self.isQuoteNotificationsEnabled = UserDefaults.standard.bool(forKey: "isQuoteNotificationsEnabled")
        self.notificationFrequency = UserDefaults.standard.integer(forKey: "quoteNotificationFrequency")
        if self.notificationFrequency == 0 { self.notificationFrequency = 2 } // Default to 2 hours
    }
    
    func saveSettings() {
        let effectiveQuoteNotificationsEnabled = areGeneralNotificationsEnabled && isQuoteNotificationsEnabled
        
        UserDefaults.standard.set(effectiveQuoteNotificationsEnabled, forKey: "isQuoteNotificationsEnabled")
        UserDefaults.standard.set(notificationFrequency, forKey: "quoteNotificationFrequency")
        
        Task {
            await updateNotifications()
        }
    }
    
    func updateNotifications() async {
        if isQuoteNotificationsEnabled {
            await notificationService.scheduleQuoteNotifications()
        } else {
            notificationService.cancelQuoteNotifications()
        }
    }
    
    func testNotification() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                await notificationService.scheduleTestQuoteNotification()
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to send test notification: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct QuoteSettingsView: View {
    @StateObject private var viewModel = QuoteSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Motivational Quotes")) {
                    
                    if !viewModel.areGeneralNotificationsEnabled {
                        Text("You must enable General Notifications in Settings to receive Motivational Quotes.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Toggle("Enable Quote Notifications", isOn: $viewModel.isQuoteNotificationsEnabled)
                        .disabled(!viewModel.areGeneralNotificationsEnabled)
                    
                    if viewModel.areGeneralNotificationsEnabled && viewModel.isQuoteNotificationsEnabled {
                        HStack {
                            Text("Send Every")
                            Spacer()
                            Text("\(viewModel.notificationFrequency) hours")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(viewModel.notificationFrequency) },
                            set: { viewModel.notificationFrequency = Int($0) }
                        ), in: 1...6, step: 1)
                        
                        Button("Send Test Notification") {
                            viewModel.testNotification()
                        }
                        .disabled(viewModel.isLoading)
                        
                        if viewModel.isLoading {
                            ProgressView()
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    Text("Motivational quotes will be delivered as notifications every few hours to keep you inspired throughout your day.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Quote Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
}

//
//  HobbyDetailViewModel.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//


import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class HobbyDetailViewModel: ObservableObject {
    private let hobbyManager = HobbyManager.shared
    private var hobby: Hobby?
    private var cancellables = Set<AnyCancellable>()
    
    // Form fields
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var selectedIconName: String = "star.fill"
    @Published var selectedColorHex: String = "#4CAF50"
    
    // UI state
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isValid: Bool = false
    
    // Display data
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    
    // Icon and color selection
    @Published var iconOptions: [(name: String, systemName: String)] = []
    @Published var colorOptions: [(name: String, hex: String, color: Color)] = []
    
    private var isNewHobby: Bool
    
    init(hobby: Hobby? = nil) {
        self.hobby = hobby
        self.isNewHobby = hobby == nil
        
        // Load options
        self.iconOptions = HobbyManager.getIconOptions()
        self.colorOptions = HobbyManager.getColorOptions()
        
        // Initialize with hobby data if editing
        if let existingHobby = hobby {
            self.title = existingHobby.unwrappedTitle
            self.description = existingHobby.unwrappedDescription
            self.selectedIconName = existingHobby.unwrappedIconName
            self.selectedColorHex = existingHobby.colorHex ?? "#4CAF50"
            
            loadHobbyData()
        }
        
        // Observe form validation
        $title
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .assign(to: &$isValid)
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func loadHobbyData() {
        guard let hobby = hobby else { return }
        
        isLoading = true
        Task {
            // Get stats
            self.currentStreak = hobbyManager.getCurrentStreak(for: hobby)
            self.longestStreak = hobbyManager.getLongestStreak(for: hobby)
            
            self.isLoading = false
        }
    }
    
    func saveHobby() -> Bool {
        guard isValid else { return false }
        
        isSaving = true
        errorMessage = nil
        
        do {
            if let existingHobby = hobby {
                // Update existing hobby
                existingHobby.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                existingHobby.hobbyDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
                existingHobby.iconName = selectedIconName
                existingHobby.colorHex = selectedColorHex
                
                hobbyManager.updateHobby(existingHobby)
            } else {
                // Create new hobby
                _ = hobbyManager.createHobby(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    iconName: selectedIconName,
                    colorHex: selectedColorHex,
                )
            }
            
            isSaving = false
            return true
        } catch {
            errorMessage = "Failed to save hobby: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    func toggleCompletion(for date: Date) {
        guard let hobby = hobby else { return }
        
        // Only allow toggling if this date is valid for the frequency type
        if isDateValidForToggle(date) {
            hobbyManager.toggleEntryCompletion(for: hobby, on: date)
            loadHobbyData() // Refresh data
        }
    }
    
    func isDateCompleted(_ date: Date) -> Bool {
        guard let hobby = hobby else { return false }
        return hobby.hasEntry(for: date)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    func isDateInPast(_ date: Date) -> Bool {
        return date < Date()
    }
    
    func isDateValidForToggle(_ date: Date) -> Bool {
        // We'll allow toggling for today and dates in the past
        return date <= Date()
    }
    
    // Helper to create a temporary hobby for preview purposes
    func createTemporaryHobby() -> Hobby {
        let context = hobbyManager.coreDataManager.persistentContainer.viewContext
        let tempHobby = Hobby(context: context)
        tempHobby.title = title
        tempHobby.hobbyDescription = description
        tempHobby.iconName = selectedIconName
        tempHobby.colorHex = selectedColorHex
        return tempHobby
    }
    
    var pageTitle: String {
        isNewHobby ? "New Hobby" : "Edit Hobby"
    }
    
    var buttonColor: Color {
        return Color(hex: selectedColorHex)
    }
    
    var hobbyId: UUID? {
        return hobby?.id
    }
}

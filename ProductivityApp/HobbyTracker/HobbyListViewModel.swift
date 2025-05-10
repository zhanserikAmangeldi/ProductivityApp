//
//  HO.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HobbyListViewModel: ObservableObject {
    private let hobbyManager = HobbyManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var hobbies: [Hobby] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init() {
        print("HobbyListViewModel initialized")
        
        // Set up subscriptions to reload data when search changes
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadHobbies()
            }
            .store(in: &cancellables)
        
        // Initial load
        loadHobbies()
    }
    
    deinit {
        print("HobbyListViewModel deinit")
        cancellables.removeAll()
    }
    
    func loadHobbies() {
        isLoading = true
        errorMessage = nil
        
        // Run in background task
        Task {
            do {
                let fetchedHobbies = hobbyManager.fetchHobbies()
                
                // Apply search filter if needed
                if !searchText.isEmpty {
                    self.hobbies = fetchedHobbies.filter { hobby in
                        return hobby.unwrappedTitle.localizedCaseInsensitiveContains(searchText) ||
                               hobby.unwrappedDescription.localizedCaseInsensitiveContains(searchText)
                    }
                } else {
                    self.hobbies = fetchedHobbies
                }
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load hobbies: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func deleteHobby(_ hobby: Hobby) {
        hobbyManager.deleteHobby(hobby)
        loadHobbies()
    }
    
    func toggleToday(for hobby: Hobby) {
        hobbyManager.toggleEntryCompletion(for: hobby, on: Date())
        loadHobbies() // Refresh to update the UI
    }
    
    func getCurrentStreak(for hobby: Hobby) -> Int {
        return hobbyManager.getCurrentStreak(for: hobby)
    }
    
    func getLongestStreak(for hobby: Hobby) -> Int {
        return hobbyManager.getLongestStreak(for: hobby)
    }
}

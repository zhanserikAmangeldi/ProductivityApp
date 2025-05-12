//
//  HobbyListViewModel.swift
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
    
    // Track loading state per hobby
    @Published var loadingHobbyIds: Set<UUID> = []
    
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
        guard !isLoading else { return } // Prevent multiple concurrent loads
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedHobbies = await hobbyManager.fetchHobbiesAsync(searchText: searchText.isEmpty ? nil : searchText)
                
                await MainActor.run {
                    self.hobbies = fetchedHobbies
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load hobbies: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteHobby(_ hobby: Hobby) {
        hobbyManager.deleteHobby(hobby)
        loadHobbies()
    }
    
    func toggleToday(for hobby: Hobby) {
        guard let hobbyId = hobby.id else { return }
        
        // Track loading state for this specific hobby
        loadingHobbyIds.insert(hobbyId)
        
        Task {
            // Toggle the entry
            hobbyManager.toggleEntryCompletion(for: hobby, on: Date())
            
            // Update only this specific hobby
            if let index = hobbies.firstIndex(where: { $0.id == hobbyId }) {
                // Instead of fetching the entire hobby, just update what's needed
                hobbies[index].invalidateEntriesCache() // New method we added
                
                // Remove loading state
                loadingHobbyIds.remove(hobbyId)
                // Trigger UI update only for this item
                self.objectWillChange.send()
            } else {
                loadingHobbyIds.remove(hobbyId)
            }
        }
    }
    
    func getCurrentStreak(for hobby: Hobby) -> Int {
        return hobbyManager.getCurrentStreak(for: hobby)
    }
    
    func getLongestStreak(for hobby: Hobby) -> Int {
        return hobbyManager.getLongestStreak(for: hobby)
    }
    
    // Helper to check if a particular hobby is loading
    func isLoadingHobby(_ hobbyId: UUID?) -> Bool {
        guard let id = hobbyId else { return false }
        return loadingHobbyIds.contains(id)
    }
}

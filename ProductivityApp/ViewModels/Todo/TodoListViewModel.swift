//
//  TodoListViewModel.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import Combine
import SwiftUI
import CoreData

enum TodoFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case completed
    case today
    case upcoming
    case overdue
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All Tasks"
        case .active: return "Active"
        case .completed: return "Completed"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .overdue: return "Overdue"
        }
    }
    
    var systemImage: String {
        switch self {
        case .all: return "list.bullet"
        case .active: return "clock"
        case .completed: return "checkmark.circle"
        case .today: return "sun.max"
        case .upcoming: return "calendar"
        case .overdue: return "exclamationmark.circle"
        }
    }
}

@MainActor
class TodoListViewModel: ObservableObject {
    private let coreDataManager = TodoTaskManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var tasks: [TodoTask] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: TodoFilter = .all
    @Published var selectedPriority: TaskPriority? = nil
    @Published var selectedTag: String? = nil
    @Published var availableTags: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init() {
        print("TodoListViewModel initialized")
        
        // Set up subscriptions to reload data when filters change
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadTasks()
            }
            .store(in: &cancellables)
        
        $selectedFilter
            .sink { [weak self] _ in
                self?.loadTasks()
            }
            .store(in: &cancellables)
        
        $selectedPriority
            .sink { [weak self] _ in
                self?.loadTasks()
            }
            .store(in: &cancellables)
        
        $selectedTag
            .sink { [weak self] _ in
                self?.loadTasks()
            }
            .store(in: &cancellables)
        
        // Initial load
        loadTasks()
        loadTags()
    }
    
    deinit {
        print("TodoListViewModel deinit")
        cancellables.removeAll()
    }
    
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
        // Run in background task
        Task {
            do {
                let fetchedTasks = try await fetchFilteredTasks()
                self.tasks = fetchedTasks
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func fetchFilteredTasks() async throws -> [TodoTask] {
        // Get tasks based on the selected filter
        switch selectedFilter {
        case .all:
            return coreDataManager.fetchTasks(
                searchText: searchText.isEmpty ? nil : searchText,
                priorityFilter: selectedPriority,
                tagFilter: selectedTag
            )
            
        case .active:
            return coreDataManager.fetchTasks(
                isCompleted: false,
                searchText: searchText.isEmpty ? nil : searchText,
                priorityFilter: selectedPriority,
                tagFilter: selectedTag
            )
            
        case .completed:
            return coreDataManager.fetchTasks(
                isCompleted: true,
                searchText: searchText.isEmpty ? nil : searchText,
                priorityFilter: selectedPriority,
                tagFilter: selectedTag
            )
            
        case .today:
            // For specialized cases, we'll filter the results after fetching
            let todayTasks = coreDataManager.getTodaysTasks()
            
            // Apply additional filters
            return todayTasks.filter { task in
                var matches = true
                
                if let priority = selectedPriority {
                    matches = matches && (task.priority == priority.rawValue)
                }
                
                if !searchText.isEmpty {
                    matches = matches && ((task.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                                          (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                                          (task.tags?.localizedCaseInsensitiveContains(searchText) ?? false))
                }
                
                if let selectedTag = selectedTag {
                    matches = matches && task.tags?.contains(selectedTag) ?? false
                }
                
                return matches
            }
            
        case .upcoming:
            let upcomingTasks = coreDataManager.getUpcomingTasks()
            
            // Apply additional filters
            return upcomingTasks.filter { task in
                var matches = true
                
                if let priority = selectedPriority {
                    matches = matches && (task.priority == priority.rawValue)
                }
                
                if !searchText.isEmpty {
                    matches = matches && ((task.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                                          (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                                          (task.tags?.localizedCaseInsensitiveContains(searchText) ?? false))
                }
                
                if let selectedTag = selectedTag {
                    matches = matches && task.tags?.contains(selectedTag) ?? false
                }
                
                return matches
            }
            
        case .overdue:
            let overdueTasks = coreDataManager.getOverdueTasks()
            
            return overdueTasks.filter { task in
                var matches = true
                
                if let priority = selectedPriority {
                    matches = matches && (task.priority == priority.rawValue)
                }
                
                if !searchText.isEmpty {
                    matches = matches && ((task.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                                          (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                                          (task.tags?.localizedCaseInsensitiveContains(searchText) ?? false))
                }
                
                if let selectedTag = selectedTag {
                    matches = matches && task.tags?.contains(selectedTag) ?? false
                }
                
                return matches
            }
        }
    }
    
    func loadTags() {
        availableTags = coreDataManager.fetchAllTags()
    }
    
    func toggleTaskCompletion(_ task: TodoTask) {
        coreDataManager.toggleTaskCompletion(task)
        loadTasks()
    }
    
    func deleteTask(_ task: TodoTask) {
        coreDataManager.deleteTask(task)
        loadTasks()
        loadTags() // Tags might have changed
    }
    
    func clearFilters() {
        searchText = ""
        selectedPriority = nil
        selectedTag = nil
    }
    
    func getTasksCountSummary() -> (total: Int, active: Int, completed: Int) {
        let total = coreDataManager.fetchTaskCount()
        let active = coreDataManager.fetchTaskCount(isCompleted: false)
        let completed = coreDataManager.fetchTaskCount(isCompleted: true)
        
        return (total, active, completed)
    }
    
    // Helper method to get prioritized color based on task priority
    func priorityColor(for task: TodoTask) -> Color {
        let priority = TaskPriority(rawValue: task.priority) ?? .medium
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    
    // Helper method to get the status of a task
    func taskStatus(for task: TodoTask) -> String {
        if task.isCompleted {
            return "Completed"
        }
        
        if let dueDate = task.dueDate {
            if dueDate < Date() {
                return "Overdue"
            } else if Calendar.current.isDateInToday(dueDate) {
                return "Due Today"
            } else {
                return "Upcoming"
            }
        }
        
        return "Active"
    }
}

//
//  TaskDetailViewModel.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class TaskDetailViewModel: ObservableObject {
    private let coreDataManager = TodoTaskManager.shared
    private var managedObjectContext: NSManagedObjectContext
    private var task: TodoTask
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties for form fields
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var dueDate: Date = Date()
    @Published var hasDueDate: Bool = false
    @Published var isCompleted: Bool = false
    @Published var priority: TaskPriority = .medium
    @Published var tags: [String] = []
    @Published var newTagText: String = ""
    @Published var suggestedTags: [String] = []
    
    // State properties
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isValid: Bool = false
    @Published var isNewTask: Bool
    
    init(task: TodoTask? = nil, context: NSManagedObjectContext = CoreDataService.shared.persistentContainer.viewContext) {
        self.managedObjectContext = context
        
        if let existingTask = task {
            self.task = existingTask
            self.isNewTask = false
        } else {
            self.task = TodoTask.emptyTask(context: context)
            self.isNewTask = true
        }
        
        // Load data from the task
        self.title = task?.title ?? ""
        self.description = task?.taskDescription ?? ""
        if let dueDate = task?.dueDate {
            self.dueDate = dueDate
            self.hasDueDate = true
        } else {
            self.hasDueDate = false
            // Set default due date to tomorrow at noon
            self.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self.dueDate) ?? self.dueDate
            self.dueDate = noon
        }
        self.isCompleted = task?.isCompleted ?? false
        if let priorityValue = task?.priority {
            self.priority = TaskPriority(rawValue: priorityValue)!
        }
        self.tags = task?.tagArray ?? []
        
        // Observe form validation
        Publishers.CombineLatest($title, $description)
            .map { title, _ in
                return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .assign(to: &$isValid)
        
        // Load suggested tags
        self.loadSuggestedTags()
        
        // Set up new tag text subscription
        $newTagText
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.updateSuggestedTags(with: text)
            }
            .store(in: &cancellables)
    }
    
    func saveTask() -> Bool {
        guard isValid else { return false }
        
        isSaving = true
        errorMessage = nil
        
        // Update task properties
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.taskDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        task.dueDate = hasDueDate ? dueDate : nil
        task.isCompleted = isCompleted
        task.priority = Int16(priority.rawValue)
        task.tagArray = tags
        task.lastModified = Date()
        
        if task.dateCreated == nil {
            task.dateCreated = Date()
        }
        
        // Save to Core Data
        do {
            try managedObjectContext.save()
            isSaving = false
            return true
        } catch {
            errorMessage = "Could not save task: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    func addTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else {
            return
        }
        
        tags.append(trimmedTag)
        newTagText = ""
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func loadSuggestedTags() {
        suggestedTags = coreDataManager.fetchAllTags()
    }
    
    private func updateSuggestedTags(with text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            // Show all available tags
            suggestedTags = coreDataManager.fetchAllTags().filter { !tags.contains($0) }
        } else {
            // Filter tags based on input
            suggestedTags = coreDataManager.fetchAllTags().filter { tag in
                return tag.localizedCaseInsensitiveContains(trimmedText) && !tags.contains(tag)
            }
        }
    }
    
    func toggleCompletion() {
        isCompleted.toggle()
    }
    
    // Additional helpers
    var formattedDueDate: String {
        if !hasDueDate {
            return "No Due Date"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    var taskStatusColor: Color {
        if isCompleted {
            return .green
        }
        
        if hasDueDate && dueDate < Date() {
            return .red
        }
        
        return .primary
    }
    
    var pageTitle: String {
        isNewTask ? "New Task" : "Edit Task"
    }
    
    var taskId: UUID? {
        return task.id
    }
}

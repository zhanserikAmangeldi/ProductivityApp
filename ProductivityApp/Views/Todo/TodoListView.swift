//
//  Untitled.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI

struct TodoListView: View {
    @StateObject private var viewModel = TodoListViewModel()
    @State private var showingNewTaskSheet = false
    @State private var editingTask: TodoTask? = nil
    @State private var showingFilterSheet = false
    @State private var confirmingDelete: TodoTask? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter categories
                filterCategoryView
                
                // Task list
                taskListView
            }
            .edgesIgnoringSafeArea([.bottom])
            .navigationTitle("To-Do List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewTaskSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search tasks")
            .refreshable {
                viewModel.loadTasks()
            }
            .sheet(isPresented: $showingNewTaskSheet) {
                TaskDetailView(onSave: {
                    viewModel.loadTasks()
                })
            }
            .sheet(item: $editingTask) { task in
                NavigationStack {
                    TaskDetailView(task: task, onSave: {
                        viewModel.loadTasks()
                    })
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    selectedPriority: $viewModel.selectedPriority,
                    selectedTag: $viewModel.selectedTag,
                    availableTags: viewModel.availableTags,
                    onClearFilters: {
                        viewModel.clearFilters()
                    }
                )
                .presentationDetents([.medium])
            }
            .alert("Delete Task", isPresented: Binding(
                get: { confirmingDelete != nil },
                set: { if !$0 { confirmingDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    confirmingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let task = confirmingDelete {
                        viewModel.deleteTask(task)
                    }
                    confirmingDelete = nil
                }
            } message: {
                if let task = confirmingDelete {
                    Text("Are you sure you want to delete '\(task.title ?? "this task")'?")
                }
            }
        }
    }
    
    private var filterCategoryView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TodoFilter.allCases) { filter in
                    FilterButton(
                        title: filter.displayName,
                        systemImage: filter.systemImage,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
                .padding(.top, 46),
            alignment: .bottom
        )
    }
    
    private var taskListView: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.tasks.isEmpty {
                emptyStateView
            } else {
                taskList
            }
        }
    }
    
    private var taskList: some View {
        List {
            Section {
                ForEach(viewModel.tasks) { task in
                    TaskRowView(
                        task: task,
                        priorityColor: viewModel.priorityColor(for: task),
                        status: viewModel.taskStatus(for: task),
                        onToggleCompletion: {
                            viewModel.toggleTaskCompletion(task)
                        },
                        onRowTap: {
                            editingTask = task
                        }
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            confirmingDelete = task
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingTask = task
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            } header: {
                if hasActiveFilters {
                    HStack {
                        Text("Filtered Results")
                        Spacer()
                        Button("Clear Filters") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            } footer: {
                let counts = viewModel.getTasksCountSummary()
                Text("\(viewModel.tasks.count) tasks shown • \(counts.total) total (\(counts.active) active, \(counts.completed) completed)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(emptyStateMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            if hasActiveFilters {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
                .padding(.top)
            } else {
                Button("Create a Task") {
                    showingNewTaskSheet = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateMessage: String {
        if hasActiveFilters {
            return "No tasks match your current filters"
        }
        
        switch viewModel.selectedFilter {
        case .all:
            return "You don't have any tasks yet"
        case .active:
            return "You don't have any active tasks"
        case .completed:
            return "You haven't completed any tasks yet"
        case .today:
            return "You don't have any tasks due today"
        case .upcoming:
            return "You don't have any upcoming tasks"
        case .overdue:
            return "Great! You don't have any overdue tasks"
        }
    }
    
    private var hasActiveFilters: Bool {
        return !viewModel.searchText.isEmpty || viewModel.selectedPriority != nil || viewModel.selectedTag != nil
    }
}

struct TaskRowView: View {
    let task: TodoTask
    let priorityColor: Color
    let status: String
    let onToggleCompletion: () -> Void
    let onRowTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Completion checkbox - make sure this doesn't get intercepted
            Button(action: {
                // This is important - we need to stop event propagation
                onToggleCompletion()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            // We need to make sure the button handles its own tap events without propagation
            .buttonStyle(BorderlessButtonStyle())
            
            // Task details wrapped in a container that handles row taps
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "")
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    // Priority indicator
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundColor(priorityColor)
                    
                    // Due date if available
                    if let dueDate = task.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(formatDate(dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(isDueDateOverdue(dueDate) && !task.isCompleted ? .red : .secondary)
                    }
                    
                    // Status
                    Text(status)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                }
                
                // Tags if available
                if let tags = task.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(task.tagArray, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onRowTap()
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func isDueDateOverdue(_ date: Date) -> Bool {
        return date < Date()
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return .green
        } else if let dueDate = task.dueDate, dueDate < Date() {
            return .red
        } else if let dueDate = task.dueDate, Calendar.current.isDateInToday(dueDate) {
            return .orange
        } else {
            return .blue
        }
    }
}

struct FilterButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPriority: TaskPriority?
    @Binding var selectedTag: String?
    let availableTags: [String]
    let onClearFilters: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Priority")) {
                    Button {
                        selectedPriority = nil
                    } label: {
                        HStack {
                            Text("Any")
                            Spacer()
                            if selectedPriority == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(TaskPriority.allCases) { priority in
                        Button {
                            selectedPriority = priority
                        } label: {
                            HStack {
                                Image(systemName: priority.icon)
                                    .foregroundColor(Color(priority.color))
                                Text(priority.name)
                                Spacer()
                                if selectedPriority == priority {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                if !availableTags.isEmpty {
                    Section(header: Text("Tags")) {
                        Button {
                            selectedTag = nil
                        } label: {
                            HStack {
                                Text("Any")
                                Spacer()
                                if selectedTag == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                        
                        ForEach(availableTags, id: \.self) { tag in
                            Button {
                                selectedTag = tag
                            } label: {
                                HStack {
                                    Text(tag)
                                    Spacer()
                                    if selectedTag == tag {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                Section {
                    Button("Clear All Filters") {
                        onClearFilters()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filter Tasks")
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

struct TodoListView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
    }
}

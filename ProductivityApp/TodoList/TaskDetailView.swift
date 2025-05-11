//
//  TaskDetailView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI

struct TaskDetailView: View {
    @StateObject private var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    var onSave: (() -> Void)?
    
    enum Field: Hashable {
        case title
        case description
        case newTag
    }
    
    init(task: TodoTask? = nil, onSave: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                taskDetailsSection
                dueDateSection
                prioritySection
                tagsSection
                
                if !viewModel.isNewTask {
                    Section {
                        Toggle(isOn: $viewModel.isCompleted) {
                            Label {
                                Text("Mark as Completed")
                            } icon: {
                                Image(systemName: viewModel.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.isCompleted ? .green : .gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .overlay {
                if viewModel.isSaving {
                    LoadingDotsView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                focusedField = .title
            }
        }
    }
    
    private var taskDetailsSection: some View {
        Section(header: Text("Task Details")) {
            TextField("Task Title", text: $viewModel.title)
                .focused($focusedField, equals: .title)
            
            ZStack(alignment: .topLeading) {
                if viewModel.description.isEmpty {
                    Text("Description (optional)")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $viewModel.description)
                    .focused($focusedField, equals: .description)
                    .frame(minHeight: 100)
                    .padding(.leading, -5)
            }
        }
    }
    
    private var dueDateSection: some View {
        Section(header: Text("Due Date")) {
            Toggle("Set Due Date", isOn: $viewModel.hasDueDate)
            
            if viewModel.hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: $viewModel.dueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }
    
    private var prioritySection: some View {
        Section(header: Text("Priority")) {
            Picker("Priority", selection: $viewModel.priority) {
                ForEach(TaskPriority.allCases) { priority in
                    HStack {
                        Image(systemName: priority.icon)
                            .foregroundColor(Color(priority.color))
                        Text(priority.name)
                    }
                    .tag(priority)
                }
            }
            .pickerStyle(.inline)
        }
    }
    
    private var tagsSection: some View {
        Section(header: Text("Tags")) {
            if !viewModel.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.subheadline)
                                
                                Button {
                                    viewModel.removeTag(tag)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            HStack {
                TextField("Add a tag", text: $viewModel.newTagText)
                    .focused($focusedField, equals: .newTag)
                
                Button {
                    viewModel.addTag()
                    focusedField = .newTag
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if !viewModel.suggestedTags.isEmpty && !viewModel.newTagText.isEmpty {
                Text("Suggestions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.suggestedTags, id: \.self) { tag in
                            Button {
                                viewModel.newTagText = tag
                            } label: {
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveTask() {
        // Attempt to save the task
        if viewModel.saveTask() {
            // Call the onSave callback
            onSave?()
            // Dismiss the view
            dismiss()
        }
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TaskDetailView()
    }
}

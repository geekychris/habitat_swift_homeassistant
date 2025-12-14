//
//  TabManagementView.swift
//  SimpleHomeAssistant
//
//  Custom tab management
//

import SwiftUI

struct TabManagementView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.activeConfiguration != nil {
                    if viewModel.customTabs.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No Custom Tabs")
                                .font(.headline)
                            Text("Create tabs to organize entities by room or category.\nTap a tab to select which entities appear on your Dashboard.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button(action: { showingAddSheet = true }) {
                                Label("Add Tab", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.customTabs) { tab in
                                NavigationLink(destination: TabDetailView(tab: tab)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tab.name)
                                            .font(.headline)
                                        Text("\(tab.entityIds.count) entities")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    viewModel.deleteTab(viewModel.customTabs[index])
                                }
                            }
                        }
                    }
                } else {
                    NoConfigView()
                }
            }
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.activeConfiguration != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTabView()
            }
        }
    }
}

struct AddTabView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tab Name") {
                    TextField("e.g., Living Room", text: $name)
                }
                Section {
                    Text("After creating, tap the tab to assign entities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Tab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard let config = viewModel.activeConfiguration else { return }
                        let tab = CustomTab(
                            name: name,
                            entityIds: [],
                            displayOrder: viewModel.customTabs.count,
                            configurationId: config.id
                        )
                        viewModel.saveTab(tab)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct TabDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let tab: CustomTab
    @State private var searchText = ""
    @State private var assignedEntityIds: Set<String> = []
    @State private var hideUnavailable = false
    
    var filteredEntities: [HAEntity] {
        var entities = viewModel.entities
        
        // Filter out unavailable if checkbox is checked
        if hideUnavailable {
            entities = entities.filter { $0.state.lowercased() != "unavailable" }
        }
        
        // Filter by search text
        if searchText.isEmpty {
            return entities
        } else {
            return entities.filter { entity in
                matchesTokenizedSearch(text: searchText, in: entity.friendlyName) ||
                matchesTokenizedSearch(text: searchText, in: entity.entityId)
            }
        }
    }
    
    /// Tokenized prefix matching: "kitchen cab" matches "Kitchen under cabinet light"
    /// Each search token must match at least one word (prefix) in the target
    private func matchesTokenizedSearch(text searchText: String, in target: String) -> Bool {
        // Split search text into tokens (words)
        let searchTokens = searchText.lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Split target into words
        let targetWords = target.lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Each search token must match at least one target word (prefix match)
        return searchTokens.allSatisfy { searchToken in
            targetWords.contains { targetWord in
                targetWord.hasPrefix(searchToken)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar and filter options at top (fixed)
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search...", text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Hide unavailable checkbox
                HStack {
                    Button(action: { hideUnavailable.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: hideUnavailable ? "checkmark.square.fill" : "square")
                                .foregroundColor(hideUnavailable ? .blue : .gray)
                            Text("Hide Unavailable")
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            
            // Scrollable list of entities
            List {
                ForEach(filteredEntities) { entity in
                    Button(action: {
                        toggleAssignment(entity.entityId)
                    }) {
                        HStack {
                            Image(systemName: assignedEntityIds.contains(entity.entityId) ? "checkmark.square.fill" : "square")
                                .foregroundColor(assignedEntityIds.contains(entity.entityId) ? .blue : .gray)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entity.friendlyName)
                                HStack {
                                    Text(entity.entityId)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    // Show unavailable status
                                    if entity.state.lowercased() == "unavailable" {
                                        Text("• Unavailable")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if assignedEntityIds.contains(entity.entityId) {
                            Button(role: .destructive) {
                                toggleAssignment(entity.entityId)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            
            // Info bar at bottom (fixed)
            HStack {
                Text("\(assignedEntityIds.count) assigned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .navigationTitle(tab.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            assignedEntityIds = Set(tab.entityIds)
        }
    }
    
    private func toggleAssignment(_ entityId: String) {
        var updatedTab = tab
        if assignedEntityIds.contains(entityId) {
            assignedEntityIds.remove(entityId)
            updatedTab.entityIds.removeAll { $0 == entityId }
        } else {
            assignedEntityIds.insert(entityId)
            updatedTab.entityIds.append(entityId)
        }
        viewModel.saveTab(updatedTab)
    }
}

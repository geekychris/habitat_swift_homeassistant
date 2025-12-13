//
//  EntitySelectionView.swift
//  SimpleHomeAssistant
//
//  Entity selection view
//

import SwiftUI

struct EntitySelectionView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    
    var filteredEntities: [HAEntity] {
        if searchText.isEmpty {
            return viewModel.entities
        } else {
            return viewModel.entities.filter {
                $0.friendlyName.localizedCaseInsensitiveContains(searchText) ||
                $0.entityId.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.activeConfiguration != nil {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search entities...", text: $searchText)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    
                    // Entity list
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        ErrorView(message: error) {
                            Task { await viewModel.loadEntities() }
                        }
                    } else {
                        List {
                            ForEach(filteredEntities) { entity in
                                Button(action: {
                                    viewModel.toggleEntitySelection(entity.entityId)
                                }) {
                                    HStack {
                                        Image(systemName: viewModel.selectedEntityIds.contains(entity.entityId) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(viewModel.selectedEntityIds.contains(entity.entityId) ? .blue : .gray)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entity.friendlyName)
                                            Text(entity.entityId)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(entity.domain.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .listStyle(.plain)
                    }
                    
                    // Footer
                    HStack {
                        Text("\(viewModel.selectedEntityIds.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(filteredEntities.count) entities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .systemGroupedBackground))
                } else {
                    NoConfigView()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if viewModel.activeConfiguration != nil && viewModel.entities.isEmpty {
                    Task { await viewModel.loadEntities() }
                }
            }
            .refreshable {
                await viewModel.loadEntities()
            }
        }
    }
}

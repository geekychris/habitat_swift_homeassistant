//
//  ConfigurationView.swift
//  SimpleHomeAssistant
//
//  Configuration management view
//

import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                List {
                if viewModel.configurations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "gearshape.2")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Configurations")
                            .font(.headline)
                        Text("Tap + to add your Home Assistant configuration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.configurations) { config in
                        ConfigurationRow(config: config)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteConfiguration(viewModel.configurations[index])
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            
            // Floating + button
            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.blue))
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(16)
            .sheet(isPresented: $showingAddSheet) {
                AddConfigurationView()
            }
        }
        }
    }
}

struct ConfigurationRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let config: HAConfiguration
    @State private var isExpanded = false
    @State private var testResult: String?
    @State private var isTesting = false
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(config.name)
                        .font(.headline)
                    Text(config.useInternalUrl ? "Internal" : "External")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if config.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Button("Activate") {
                        viewModel.setActiveConfiguration(config)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Internal", value: config.internalUrl)
                    DetailRow(label: "External", value: config.externalUrl)
                    DetailRow(label: "Token", value: String(config.apiToken.prefix(20)) + "...")
                    
                    HStack {
                        Button("Edit") {
                            showingEditSheet = true
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            Task {
                                isTesting = true
                                testResult = await viewModel.testConnection(config)
                                isTesting = false
                            }
                        }) {
                            if isTesting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Test Connection")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTesting)
                        .frame(maxWidth: .infinity)
                    }
                    
                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("✅") ? .green : .red)
                    }
                }
            }
            
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditSheet) {
            EditConfigurationView(config: config)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

struct AddConfigurationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var internalUrl = ""
    @State private var externalUrl = ""
    @State private var apiToken = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name (e.g., Home)", text: $name)
                    TextField("Internal URL", text: $internalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("External URL", text: $externalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Authentication") {
                    TextField("API Token", text: $apiToken, axis: .vertical)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .lineLimit(3...5)
                }
                
                Section {
                    Text("Get your token from Home Assistant:\nProfile → Security → Long-Lived Access Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let config = HAConfiguration(
                            name: name,
                            internalUrl: internalUrl,
                            externalUrl: externalUrl,
                            apiToken: apiToken,
                            isActive: viewModel.configurations.isEmpty
                        )
                        viewModel.saveConfiguration(config)
                        if config.isActive {
                            viewModel.setActiveConfiguration(config)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || internalUrl.isEmpty || apiToken.isEmpty)
                }
            }
        }
    }
}

struct EditConfigurationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    let config: HAConfiguration
    @State private var name = ""
    @State private var internalUrl = ""
    @State private var externalUrl = ""
    @State private var apiToken = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name (e.g., Home)", text: $name)
                    TextField("Internal URL", text: $internalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("External URL", text: $externalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Authentication") {
                    TextField("API Token", text: $apiToken, axis: .vertical)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .lineLimit(3...5)
                }
                
                Section {
                    Text("Get your token from Home Assistant:\nProfile → Security → Long-Lived Access Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = config
                        updated.name = name
                        updated.internalUrl = internalUrl
                        updated.externalUrl = externalUrl
                        updated.apiToken = apiToken
                        viewModel.saveConfiguration(updated)
                        if updated.isActive {
                            viewModel.setActiveConfiguration(updated)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || internalUrl.isEmpty || apiToken.isEmpty)
                }
            }
            .onAppear {
                name = config.name
                internalUrl = config.internalUrl
                externalUrl = config.externalUrl
                apiToken = config.apiToken
            }
        }
    }
}

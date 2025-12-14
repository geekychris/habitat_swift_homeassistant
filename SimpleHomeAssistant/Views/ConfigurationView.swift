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
                AddConfigurationView(isPresented: $showingAddSheet)
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
                    DetailRow(label: "Auth Type", value: config.authType == .token ? "API Token" : "OAuth (Web Login)")
                    
                    if let internalToken = config.internalToken {
                        DetailRow(label: "Internal Token", value: String(internalToken.prefix(20)) + "...")
                    }
                    
                    if let externalToken = config.externalToken, externalToken != config.internalToken {
                        DetailRow(label: "External Token", value: String(externalToken.prefix(20)) + "...")
                    }
                    
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
    @Binding var isPresented: Bool  // Control from parent instead of @Environment(\.dismiss)
    
    @State private var name = ""
    @State private var internalUrl = ""
    @State private var externalUrl = ""
    @State private var authType: AuthType = .token
    @State private var internalToken = ""
    @State private var externalToken = ""
    @State private var useSameToken = true
    @State private var showingWebAuth = false
    @State private var authStep: AuthStep = .none
    @State private var pendingInternalToken = ""
    
    enum AuthStep {
        case none
        case internalUrl
        case externalUrl
    }
    
    var isSaveDisabled: Bool {
        if name.isEmpty || internalUrl.isEmpty {
            return true
        }
        
        switch authType {
        case .token:
            return internalToken.isEmpty || (!useSameToken && externalUrl.isNotEmpty && externalToken.isEmpty)
        case .oauth:
            return false  // Will trigger web auth flow
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name (e.g., Home)", text: $name)
                    TextField("Internal URL", text: $internalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("External URL (optional)", text: $externalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Authentication Method") {
                    Picker("Type", selection: $authType) {
                        Text("API Token").tag(AuthType.token)
                        Text("Web Login (OAuth)").tag(AuthType.oauth)
                    }
                    .pickerStyle(.segmented)
                }
                
                if authType == .token {
                    Section("API Tokens") {
                        TextField("Internal Token", text: $internalToken, axis: .vertical)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .lineLimit(3...5)
                        
                        if externalUrl.isNotEmpty {
                            Toggle("Use same token for both URLs", isOn: $useSameToken)
                            
                            if !useSameToken {
                                TextField("External Token", text: $externalToken, axis: .vertical)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .lineLimit(3...5)
                            }
                        }
                    }
                    
                    Section {
                        Text("Get your token from Home Assistant:\nProfile → Security → Long-Lived Access Tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section {
                        Text("Tap Save to authenticate via web browser. You'll be prompted to log in through your Home Assistant instance.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if externalUrl.isNotEmpty && internalUrl != externalUrl {
                            Text("Note: You'll need to authenticate separately for internal and external URLs if they point to different systems.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Add Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        print("❌ Cancel tapped - closing form")
                        isPresented = false 
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSave()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .sheet(isPresented: $showingWebAuth) {
                Group {
                    switch authStep {
                    case .none:
                        // This shouldn't happen - if it does, show loading
                        VStack {
                            ProgressView()
                            Text("Preparing authentication...")
                                .padding()
                        }
                    case .internalUrl:
                        ASWebAuthView(baseUrl: internalUrl, onSuccess: { token in
                            print("✅ Internal auth complete, token: \(token.prefix(20))...")
                            pendingInternalToken = token
                            showingWebAuth = false // Close the sheet first
                            
                            // Check if we need external auth
                            if externalUrl.isNotEmpty && externalUrl != internalUrl {
                                print("🔐 URLs differ - will open external auth after delay")
                                print("🔐 Internal: \(internalUrl)")
                                print("🔐 External: \(externalUrl)")
                                // Wait for sheet to fully dismiss, then open external auth
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    authStep = .externalUrl
                                    showingWebAuth = true
                                }
                            } else {
                                print("💾 Same URL - saving with single token for both")
                                // Save with same token for both - this will dismiss the parent
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    authStep = .none
                                    saveConfiguration(internalToken: token, externalToken: token)
                                }
                            }
                        }, onCancel: {
                            print("❌ Internal auth cancelled")
                            showingWebAuth = false
                            authStep = .none
                        })
                        .id("internal-auth-\(internalUrl)")  // Force unique view identity
                    case .externalUrl:
                        ASWebAuthView(baseUrl: externalUrl, onSuccess: { token in
                            print("✅ External auth complete, token: \(token.prefix(20))...")
                            print("💾 Saving both tokens - Internal: \(pendingInternalToken.prefix(20))..., External: \(token.prefix(20))...")
                            print("💾 showingWebAuth before close: \(showingWebAuth)")
                            showingWebAuth = false // Close the sheet first
                            print("💾 showingWebAuth after close: \(showingWebAuth)")
                            // Save with both tokens after sheet dismisses
                            print("💾 Scheduling saveConfiguration in 0.5 seconds...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                print("💾 Now calling saveConfiguration...")
                                authStep = .none
                                saveConfiguration(internalToken: pendingInternalToken, externalToken: token)
                            }
                        }, onCancel: {
                            print("❌ External auth cancelled")
                            showingWebAuth = false
                            authStep = .none
                        })
                        .id("external-auth-\(externalUrl)")  // Force unique view identity
                    }
                }
            }
        }
    }
    
    private func handleSave() {
        if authType == .token {
            // Direct token auth
            let extToken = useSameToken ? internalToken : (externalToken.isEmpty ? internalToken : externalToken)
            saveConfiguration(internalToken: internalToken, externalToken: extToken)
        } else {
            // OAuth web auth - ensure state is set before showing sheet
            print("🔐 handleSave: Starting OAuth flow")
            authStep = .internalUrl
            print("🔐 handleSave: authStep set to .internalUrl")
            showingWebAuth = true
            print("🔐 handleSave: showingWebAuth set to true")
        }
    }
    
    private func saveConfiguration(internalToken: String, externalToken: String) {
        print("📝 saveConfiguration called")
        print("📝 showingWebAuth = \(showingWebAuth)")
        print("📝 authStep = \(authStep)")
        print("📝 Name: \(name)")
        print("📝 Internal Token: \(internalToken.prefix(20))...")
        print("📝 External Token: \(externalToken.prefix(20))...")
        
        // Ensure auth sheet is definitely closed
        showingWebAuth = false
        authStep = .none
        
        let config = HAConfiguration(
            name: name,
            internalUrl: internalUrl,
            externalUrl: externalUrl.isEmpty ? internalUrl : externalUrl,
            internalToken: internalToken,
            externalToken: externalToken,
            authType: authType,
            isActive: viewModel.configurations.isEmpty
        )
        
        print("📝 Calling viewModel.saveConfiguration...")
        viewModel.saveConfiguration(config)
        if config.isActive {
            print("📝 Setting as active configuration...")
            viewModel.setActiveConfiguration(config)
        }
        
        // Close the form by setting isPresented to false
        print("📝 Closing form by setting isPresented = false...")
        isPresented = false
        print("📝 isPresented set to false - form should close now")
    }
}

struct EditConfigurationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    let config: HAConfiguration
    @State private var name = ""
    @State private var internalUrl = ""
    @State private var externalUrl = ""
    @State private var authType: AuthType = .token
    @State private var internalToken = ""
    @State private var externalToken = ""
    @State private var useSameToken = true
    @State private var showingWebAuth = false
    @State private var authStep: AuthStep = .none
    @State private var pendingInternalToken = ""
    
    enum AuthStep {
        case none
        case internalUrl
        case externalUrl
    }
    
    var isSaveDisabled: Bool {
        if name.isEmpty || internalUrl.isEmpty {
            return true
        }
        
        switch authType {
        case .token:
            return internalToken.isEmpty || (!useSameToken && externalUrl.isNotEmpty && externalToken.isEmpty)
        case .oauth:
            return false  // Will trigger web auth flow
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Name (e.g., Home)", text: $name)
                    TextField("Internal URL", text: $internalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("External URL (optional)", text: $externalUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Authentication Method") {
                    Picker("Type", selection: $authType) {
                        Text("API Token").tag(AuthType.token)
                        Text("Web Login (OAuth)").tag(AuthType.oauth)
                    }
                    .pickerStyle(.segmented)
                }
                
                if authType == .token {
                    Section("API Tokens") {
                        TextField("Internal Token", text: $internalToken, axis: .vertical)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .lineLimit(3...5)
                        
                        if externalUrl.isNotEmpty {
                            Toggle("Use same token for both URLs", isOn: $useSameToken)
                            
                            if !useSameToken {
                                TextField("External Token", text: $externalToken, axis: .vertical)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .lineLimit(3...5)
                            }
                        }
                    }
                    
                    Section {
                        Text("Get your token from Home Assistant:\nProfile → Security → Long-Lived Access Tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section {
                        Text("Tap Save to re-authenticate via web browser. This will replace your current tokens.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if externalUrl.isNotEmpty && internalUrl != externalUrl {
                            Text("Note: You'll need to authenticate separately for internal and external URLs if they point to different systems.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
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
                        handleSave()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .sheet(isPresented: $showingWebAuth) {
                Group {
                    switch authStep {
                    case .none:
                        // This shouldn't happen - if it does, show loading
                        VStack {
                            ProgressView()
                            Text("Preparing authentication...")
                                .padding()
                        }
                    case .internalUrl:
                        ASWebAuthView(baseUrl: internalUrl, onSuccess: { token in
                            print("✅ [Edit] Internal auth complete, token: \(token.prefix(20))...")
                            pendingInternalToken = token
                            showingWebAuth = false // Close the sheet first
                            
                            // Check if we need external auth
                            if externalUrl.isNotEmpty && externalUrl != internalUrl {
                                print("🔐 [Edit] URLs differ - will open external auth after delay")
                                print("🔐 [Edit] Internal: \(internalUrl)")
                                print("🔐 [Edit] External: \(externalUrl)")
                                // Wait for sheet to fully dismiss, then open external auth
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    authStep = .externalUrl
                                    showingWebAuth = true
                                }
                            } else {
                                print("💾 [Edit] Same URL - saving with single token for both")
                                // Save with same token for both - this will dismiss the parent
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    authStep = .none
                                    saveConfiguration(internalToken: token, externalToken: token)
                                }
                            }
                        }, onCancel: {
                            print("❌ [Edit] Internal auth cancelled")
                            showingWebAuth = false
                            authStep = .none
                        })
                        .id("edit-internal-auth-\(internalUrl)")  // Force unique view identity
                    case .externalUrl:
                        ASWebAuthView(baseUrl: externalUrl, onSuccess: { token in
                            print("✅ [Edit] External auth complete, token: \(token.prefix(20))...")
                            print("💾 [Edit] Saving both tokens - Internal: \(pendingInternalToken.prefix(20))..., External: \(token.prefix(20))...")
                            showingWebAuth = false // Close the sheet first
                            // Save with both tokens after sheet dismisses
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                authStep = .none
                                saveConfiguration(internalToken: pendingInternalToken, externalToken: token)
                            }
                        }, onCancel: {
                            print("❌ [Edit] External auth cancelled")
                            showingWebAuth = false
                            authStep = .none
                        })
                        .id("edit-external-auth-\(externalUrl)")  // Force unique view identity
                    }
                }
            }
            .onAppear {
                name = config.name
                internalUrl = config.internalUrl
                externalUrl = config.externalUrl
                authType = config.authType
                internalToken = config.internalToken ?? ""
                externalToken = config.externalToken ?? ""
                useSameToken = (config.internalToken == config.externalToken)
            }
        }
    }
    
    private func handleSave() {
        if authType == .token {
            // Direct token auth
            let extToken = useSameToken ? internalToken : (externalToken.isEmpty ? internalToken : externalToken)
            saveConfiguration(internalToken: internalToken, externalToken: extToken)
        } else {
            // OAuth web auth - ensure state is set before showing sheet
            print("🔐 handleSave: Starting OAuth flow")
            authStep = .internalUrl
            print("🔐 handleSave: authStep set to .internalUrl")
            showingWebAuth = true
            print("🔐 handleSave: showingWebAuth set to true")
        }
    }
    
    private func saveConfiguration(internalToken: String, externalToken: String) {
        var updated = config
        updated.name = name
        updated.internalUrl = internalUrl
        updated.externalUrl = externalUrl.isEmpty ? internalUrl : externalUrl
        updated.authType = authType
        updated.internalToken = internalToken
        updated.externalToken = externalToken
        
        viewModel.saveConfiguration(updated)
        if updated.isActive {
            viewModel.setActiveConfiguration(updated)
        }
        dismiss()
    }
}

// MARK: - String Extension

extension String {
    var isNotEmpty: Bool {
        !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

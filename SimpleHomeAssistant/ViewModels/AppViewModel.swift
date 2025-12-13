//
//  AppViewModel.swift
//  SimpleHomeAssistant
//
//  Main ViewModel for the entire app
//

import Foundation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    // MARK: - Published State
    @Published var configurations: [HAConfiguration] = []
    @Published var entities: [HAEntity] = []
    @Published var selectedEntityIds: Set<String> = []
    @Published var customTabs: [CustomTab] = []
    @Published var selectedTab: String? = nil
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Services
    private let api = HomeAssistantAPI()
    private let persistence = PersistenceController.shared
    
    var activeConfiguration: HAConfiguration? {
        configurations.first(where: { $0.isActive })
    }
    
    var filteredEntities: [HAEntity] {
        var filtered = entities
        
        // Filter by selected entities
        if !selectedEntityIds.isEmpty {
            filtered = filtered.filter { selectedEntityIds.contains($0.entityId) }
        }
        
        // Filter by tab
        if let tabName = selectedTab,
           let tab = customTabs.first(where: { $0.name == tabName }) {
            let tabEntityIds = Set(tab.entityIds)
            filtered = filtered.filter { tabEntityIds.contains($0.entityId) }
        } else if selectedTab == nil {
            // Show only controllable entities on "All" tab
            filtered = filtered.filter { $0.isControllable }
        }
        
        return filtered.sorted { $0.friendlyName < $1.friendlyName }
    }
    
    init() {
        loadConfigurations()
        if let config = activeConfiguration {
            loadSelectedEntities(configId: config.id)
            loadTabs(configId: config.id)
        }
    }
    
    // MARK: - Configuration Management
    
    func loadConfigurations() {
        configurations = persistence.loadConfigurations()
    }
    
    func saveConfiguration(_ config: HAConfiguration) {
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index] = config
        } else {
            configurations.append(config)
        }
        persistence.saveConfigurations(configurations)
    }
    
    func deleteConfiguration(_ config: HAConfiguration) {
        configurations.removeAll { $0.id == config.id }
        persistence.saveConfigurations(configurations)
    }
    
    func setActiveConfiguration(_ config: HAConfiguration) {
        // Deactivate all
        for i in configurations.indices {
            configurations[i].isActive = false
        }
        // Activate selected
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index].isActive = true
        }
        persistence.saveConfigurations(configurations)
        
        // Load data for new config
        api.setConfiguration(config)
        loadSelectedEntities(configId: config.id)
        loadTabs(configId: config.id)
    }
    
    func toggleUrlType() {
        guard let config = activeConfiguration else { return }
        var updated = config
        updated.useInternalUrl.toggle()
        saveConfiguration(updated)
        loadConfigurations()
        api.setConfiguration(updated)
    }
    
    func testConnection(_ config: HAConfiguration) async -> String {
        api.setConfiguration(config)
        do {
            let success = try await api.testConnection()
            return success ? "✅ Connection successful!" : "❌ Connection failed"
        } catch {
            return "❌ Error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Entity Management
    
    func loadEntities() async {
        guard let config = activeConfiguration else {
            error = "No active configuration"
            return
        }
        
        isLoading = true
        error = nil
        api.setConfiguration(config)
        
        do {
            entities = try await api.fetchAllEntities()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func toggleEntity(_ entity: HAEntity) async {
        do {
            try await api.toggleEntity(entity.entityId)
            try await Task.sleep(nanoseconds: 500_000_000)
            await loadEntities()
        } catch {
            self.error = "Failed to toggle: \(error.localizedDescription)"
        }
    }
    
    func setBrightness(_ entity: HAEntity, brightness: Double) async {
        do {
            let value = Int(brightness * 255 / 100)
            if value > 0 {
                try await api.turnOn(entity.entityId, brightness: value)
            } else {
                try await api.turnOff(entity.entityId)
            }
            try await Task.sleep(nanoseconds: 500_000_000)
            await loadEntities()
        } catch {
            self.error = "Failed to set brightness: \(error.localizedDescription)"
        }
    }
    
    func setTemperature(_ entity: HAEntity, temperature: Double) async {
        do {
            try await api.setTemperature(entity.entityId, temperature: temperature)
            try await Task.sleep(nanoseconds: 500_000_000)
            await loadEntities()
        } catch {
            self.error = "Failed to set temperature: \(error.localizedDescription)"
        }
    }
    
    func setHvacMode(_ entity: HAEntity, mode: String) async {
        do {
            try await api.setHvacMode(entity.entityId, mode: mode)
            try await Task.sleep(nanoseconds: 500_000_000)
            await loadEntities()
        } catch {
            self.error = "Failed to set mode: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Selected Entities
    
    func loadSelectedEntities(configId: UUID) {
        selectedEntityIds = Set(persistence.loadSelectedEntities(configId: configId))
    }
    
    func toggleEntitySelection(_ entityId: String) {
        guard let config = activeConfiguration else { return }
        
        if selectedEntityIds.contains(entityId) {
            selectedEntityIds.remove(entityId)
        } else {
            selectedEntityIds.insert(entityId)
        }
        
        persistence.saveSelectedEntities(Array(selectedEntityIds), configId: config.id)
    }
    
    // MARK: - Custom Tabs
    
    func loadTabs(configId: UUID) {
        customTabs = persistence.loadTabs(configId: configId)
    }
    
    func saveTab(_ tab: CustomTab) {
        guard let config = activeConfiguration else { return }
        
        if let index = customTabs.firstIndex(where: { $0.id == tab.id }) {
            customTabs[index] = tab
        } else {
            customTabs.append(tab)
        }
        
        persistence.saveTabs(customTabs, configId: config.id)
    }
    
    func deleteTab(_ tab: CustomTab) {
        guard let config = activeConfiguration else { return }
        
        customTabs.removeAll { $0.id == tab.id }
        persistence.saveTabs(customTabs, configId: config.id)
    }
    
    func selectTabFilter(_ tabName: String?) {
        selectedTab = tabName
    }
}

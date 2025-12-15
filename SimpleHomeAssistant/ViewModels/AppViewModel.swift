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
        
        // Filter by tab selection
        if let tabName = selectedTab,
           let tab = customTabs.first(where: { $0.name == tabName }) {
            // When a specific tab is selected, show entities in that tab
            let tabEntityIds = Set(tab.entityIds)
            filtered = filtered.filter { tabEntityIds.contains($0.entityId) }
        } else {
            // "All" tab: show either selected entities or all controllable entities
            if !selectedEntityIds.isEmpty {
                filtered = filtered.filter { selectedEntityIds.contains($0.entityId) }
            } else {
                // If no entities selected, show all controllable entities
                filtered = filtered.filter { $0.isControllable }
            }
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
        
        // Automatically refresh entities from the new configuration
        Task {
            await loadEntities()
        }
    }
    
    func switchToURL(_ urlId: UUID) {
        guard var config = activeConfiguration else { return }
        config.activeUrlId = urlId
        saveConfiguration(config)
        loadConfigurations()
        
        // Update API with new configuration
        if let updated = configurations.first(where: { $0.id == config.id }) {
            api.setConfiguration(updated)
        }
    }
    
    func toggleUrlType() {
        guard let config = activeConfiguration else { return }
        
        // Find the other URL (toggle between first and second)
        if let currentUrlId = config.activeUrlId,
           let otherUrl = config.urls.first(where: { $0.id != currentUrlId }) {
            switchToURL(otherUrl.id)
        } else if let firstUrl = config.urls.first {
            // Fallback: switch to first URL if none selected
            switchToURL(firstUrl.id)
        }
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
    
    private func refreshSingleEntity(_ entityId: String) async {
        guard let config = activeConfiguration else { return }
        
        do {
            api.setConfiguration(config)
            let allEntities = try await api.fetchAllEntities()
            
            // Update only the specific entity
            if let updatedEntity = allEntities.first(where: { $0.entityId == entityId }),
               let index = entities.firstIndex(where: { $0.entityId == entityId }) {
                entities[index] = updatedEntity
            }
        } catch {
            // Silent fail - user already sees optimistic update
            print("⚠️ Failed to refresh entity \(entityId): \(error)")
        }
    }
    
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
            // Optimistically update local state
            if let index = entities.firstIndex(where: { $0.entityId == entity.entityId }) {
                var updatedEntity = entities[index]
                updatedEntity.state = updatedEntity.state == "on" ? "off" : "on"
                entities[index] = updatedEntity
            }
            
            // Send command to server
            try await api.toggleEntity(entity.entityId)
            
            // Refresh this specific entity in the background after a delay
            try await Task.sleep(nanoseconds: 500_000_000)
            await refreshSingleEntity(entity.entityId)
        } catch {
            self.error = "Failed to toggle: \(error.localizedDescription)"
            // On error, reload to get correct state
            await loadEntities()
        }
    }
    
    func setBrightness(_ entity: HAEntity, brightness: Double) async {
        do {
            // Optimistically update local state
            if let index = entities.firstIndex(where: { $0.entityId == entity.entityId }) {
                var updatedEntity = entities[index]
                updatedEntity.attributes.brightness = Int(brightness)
                updatedEntity.state = brightness > 0 ? "on" : "off"
                entities[index] = updatedEntity
            }
            
            let value = Int(brightness * 255 / 100)
            if value > 0 {
                try await api.turnOn(entity.entityId, brightness: value)
            } else {
                try await api.turnOff(entity.entityId)
            }
            
            // Refresh this specific entity in the background
            try await Task.sleep(nanoseconds: 500_000_000)
            await refreshSingleEntity(entity.entityId)
        } catch {
            self.error = "Failed to set brightness: \(error.localizedDescription)"
            await loadEntities()
        }
    }
    
    func setTemperature(_ entity: HAEntity, temperature: Double) async {
        do {
            // Optimistically update local state
            if let index = entities.firstIndex(where: { $0.entityId == entity.entityId }) {
                var updatedEntity = entities[index]
                updatedEntity.attributes.temperature = temperature
                entities[index] = updatedEntity
            }
            
            try await api.setTemperature(entity.entityId, temperature: temperature)
            
            // Refresh this specific entity in the background
            try await Task.sleep(nanoseconds: 500_000_000)
            await refreshSingleEntity(entity.entityId)
        } catch {
            self.error = "Failed to set temperature: \(error.localizedDescription)"
            await loadEntities()
        }
    }
    
    func setHvacMode(_ entity: HAEntity, mode: String) async {
        do {
            // Optimistically update local state
            if let index = entities.firstIndex(where: { $0.entityId == entity.entityId }) {
                var updatedEntity = entities[index]
                updatedEntity.attributes.hvacMode = mode
                entities[index] = updatedEntity
            }
            
            try await api.setHvacMode(entity.entityId, mode: mode)
            
            // Refresh this specific entity in the background
            try await Task.sleep(nanoseconds: 500_000_000)
            await refreshSingleEntity(entity.entityId)
        } catch {
            self.error = "Failed to set mode: \(error.localizedDescription)"
            await loadEntities()
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
    
    /// Remove entity from dashboard (handles both "All" tab and custom tabs)
    func removeFromDashboard(_ entityId: String) {
        guard let config = activeConfiguration else { return }
        
        if let tabName = selectedTab,
           let tabIndex = customTabs.firstIndex(where: { $0.name == tabName }) {
            // Viewing a custom tab - remove from that tab
            var updatedTab = customTabs[tabIndex]
            updatedTab.entityIds.removeAll { $0 == entityId }
            customTabs[tabIndex] = updatedTab
            persistence.saveTabs(customTabs, configId: config.id)
        } else {
            // Viewing "All" tab - remove from selectedEntityIds
            selectedEntityIds.remove(entityId)
            persistence.saveSelectedEntities(Array(selectedEntityIds), configId: config.id)
        }
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

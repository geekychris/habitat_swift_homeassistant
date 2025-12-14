//
//  Persistence.swift
//  SimpleHomeAssistant
//
//  Simple UserDefaults-based persistence
//  (Simpler than Core Data for this app)
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SimpleHomeAssistant")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - UserDefaults-based Storage
    
    private enum Keys {
        static let configurations = "ha_configurations"
        static let selectedEntities = "ha_selected_entities"
        static let customTabs = "ha_custom_tabs"
    }
    
    // MARK: - Configurations
    
    func saveConfigurations(_ configs: [HAConfiguration]) {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: Keys.configurations)
            UserDefaults.standard.synchronize() // Force immediate save
            print("💾 Saved \(configs.count) configurations")
        }
    }
    
    func loadConfigurations() -> [HAConfiguration] {
        print("🔍 loadConfigurations() called")
        
        if let data = UserDefaults.standard.data(forKey: Keys.configurations) {
            print("📱 Found saved configurations in UserDefaults")
            if let configs = try? JSONDecoder().decode([HAConfiguration].self, from: data) {
                print("✅ Loaded \(configs.count) configurations from UserDefaults")
                return configs
            } else {
                print("⚠️ Failed to decode saved configurations")
            }
        } else {
            print("📭 No saved configurations in UserDefaults")
        }
        
        // First run - try to load default config from assets
        print("🔄 Attempting to load default configuration...")
        return loadDefaultConfiguration()
    }
    
    private func loadDefaultConfiguration() -> [HAConfiguration] {
        // Try to find the config file in the app bundle (no subdirectory needed)
        guard let url = Bundle.main.url(forResource: "default_config", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("ℹ️ No default_config.json found - starting with empty configurations")
            return []
        }
        
        print("📂 Found default_config.json at: \(url.path)")
        
        do {
            // Parse the JSON
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let name = json?["name"] as? String,
               let internalUrl = json?["internalUrl"] as? String,
               let externalUrl = json?["externalUrl"] as? String,
               let apiToken = json?["apiToken"] as? String,
               let isActive = json?["isActive"] as? Bool {
                
                let config = HAConfiguration(
                    name: name,
                    internalUrl: internalUrl,
                    externalUrl: externalUrl,
                    token: apiToken,
                    isActive: isActive
                )
                
                print("✅ Loaded default configuration: \(name)")
                
                // Save it to UserDefaults so it persists
                saveConfigurations([config])
                
                return [config]
            }
        } catch {
            print("❌ Failed to parse default_config.json: \(error)")
        }
        
        return []
    }
    
    // MARK: - Selected Entities
    
    func saveSelectedEntities(_ entityIds: [String], configId: UUID) {
        var allSelected = loadAllSelectedEntities()
        allSelected[configId.uuidString] = entityIds
        if let data = try? JSONEncoder().encode(allSelected) {
            UserDefaults.standard.set(data, forKey: Keys.selectedEntities)
        }
    }
    
    func loadSelectedEntities(configId: UUID) -> [String] {
        let allSelected = loadAllSelectedEntities()
        return allSelected[configId.uuidString] ?? []
    }
    
    private func loadAllSelectedEntities() -> [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: Keys.selectedEntities),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return dict
    }
    
    // MARK: - Custom Tabs
    
    func saveTabs(_ tabs: [CustomTab], configId: UUID) {
        var allTabs = loadAllTabs()
        allTabs[configId.uuidString] = tabs
        if let data = try? JSONEncoder().encode(allTabs) {
            UserDefaults.standard.set(data, forKey: Keys.customTabs)
        }
    }
    
    func loadTabs(configId: UUID) -> [CustomTab] {
        let allTabs = loadAllTabs()
        return allTabs[configId.uuidString] ?? []
    }
    
    private func loadAllTabs() -> [String: [CustomTab]] {
        guard let data = UserDefaults.standard.data(forKey: Keys.customTabs),
              let dict = try? JSONDecoder().decode([String: [CustomTab]].self, from: data) else {
            return [:]
        }
        return dict
    }
}

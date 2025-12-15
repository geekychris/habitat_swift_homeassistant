//
//  ConfigurationImportExport.swift
//  SimpleHomeAssistant
//
//  Import/Export functionality for configurations
//

import Foundation
import UniformTypeIdentifiers

class ConfigurationImportExport {
    
    // MARK: - Export
    
    /// Export a single configuration to JSON
    static func exportConfiguration(_ config: HAConfiguration) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let exportData = ConfigurationExportData(
                version: "1.0",
                exportDate: Date(),
                configuration: config
            )
            return try encoder.encode(exportData)
        } catch {
            print("❌ Failed to export configuration: \(error)")
            return nil
        }
    }
    
    /// Export multiple configurations to JSON
    static func exportConfigurations(_ configs: [HAConfiguration]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let exportData = ConfigurationBatchExportData(
                version: "1.0",
                exportDate: Date(),
                configurations: configs
            )
            return try encoder.encode(exportData)
        } catch {
            print("❌ Failed to export configurations: \(error)")
            return nil
        }
    }
    
    /// Create a file URL for export
    static func createExportFileURL(for configName: String) -> URL {
        let fileName = "\(configName.replacingOccurrences(of: " ", with: "_"))_config.json"
        let tempDirectory = FileManager.default.temporaryDirectory
        return tempDirectory.appendingPathComponent(fileName)
    }
    
    /// Create a file URL for batch export
    static func createBatchExportFileURL() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "ha_configs_\(dateString).json"
        let tempDirectory = FileManager.default.temporaryDirectory
        return tempDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Import
    
    /// Import configuration from JSON data
    static func importConfiguration(from data: Data) -> Result<HAConfiguration, ImportError> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Try to decode as single configuration
            let exportData = try decoder.decode(ConfigurationExportData.self, from: data)
            
            // Validate version
            guard validateVersion(exportData.version) else {
                return .failure(.unsupportedVersion(exportData.version))
            }
            
            return .success(exportData.configuration)
        } catch {
            print("❌ Failed to import configuration: \(error)")
            return .failure(.invalidFormat(error.localizedDescription))
        }
    }
    
    /// Import multiple configurations from JSON data
    static func importConfigurations(from data: Data) -> Result<[HAConfiguration], ImportError> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Try to decode as batch
            let exportData = try decoder.decode(ConfigurationBatchExportData.self, from: data)
            
            // Validate version
            guard validateVersion(exportData.version) else {
                return .failure(.unsupportedVersion(exportData.version))
            }
            
            return .success(exportData.configurations)
        } catch {
            // Try single configuration as fallback
            let singleResult = importConfiguration(from: data)
            switch singleResult {
            case .success(let config):
                return .success([config])
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    /// Validate export format version
    private static func validateVersion(_ version: String) -> Bool {
        // Currently only support version 1.0
        return version == "1.0"
    }
    
    // MARK: - File Operations
    
    /// Write data to file and return URL
    static func writeToFile(data: Data, url: URL) -> Bool {
        do {
            try data.write(to: url)
            print("✅ Exported to: \(url.path)")
            return true
        } catch {
            print("❌ Failed to write file: \(error)")
            return false
        }
    }
    
    /// Read data from file URL
    static func readFromFile(url: URL) -> Data? {
        do {
            let data = try Data(contentsOf: url)
            print("✅ Imported from: \(url.path)")
            return data
        } catch {
            print("❌ Failed to read file: \(error)")
            return nil
        }
    }
}

// MARK: - Export Data Models

struct ConfigurationExportData: Codable {
    let version: String
    let exportDate: Date
    let configuration: HAConfiguration
}

struct ConfigurationBatchExportData: Codable {
    let version: String
    let exportDate: Date
    let configurations: [HAConfiguration]
}

// MARK: - Import Errors

enum ImportError: LocalizedError {
    case invalidFormat(String)
    case unsupportedVersion(String)
    case fileNotFound
    case readError
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let details):
            return "Invalid configuration file format: \(details)"
        case .unsupportedVersion(let version):
            return "Unsupported configuration version: \(version). Please update the app."
        case .fileNotFound:
            return "Configuration file not found"
        case .readError:
            return "Failed to read configuration file"
        }
    }
}

// MARK: - UTType Extension

extension UTType {
    static var haConfiguration: UTType {
        UTType(exportedAs: "com.homeassistant.configuration")
    }
}

//
//  Configuration.swift
//  SimpleHomeAssistant
//
//  Model for Home Assistant configuration
//

import Foundation

struct HAConfiguration: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var internalUrl: String
    var externalUrl: String
    private var _apiToken: String
    var isActive: Bool
    var useInternalUrl: Bool = true
    
    var apiToken: String {
        get { _apiToken.trimmingCharacters(in: .whitespacesAndNewlines) }
        set { _apiToken = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    var currentUrl: String {
        useInternalUrl ? internalUrl : externalUrl
    }
    
    init(id: UUID = UUID(), name: String, internalUrl: String, externalUrl: String, apiToken: String, isActive: Bool, useInternalUrl: Bool = true) {
        self.id = id
        self.name = name
        self.internalUrl = internalUrl
        self.externalUrl = externalUrl
        self._apiToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isActive = isActive
        self.useInternalUrl = useInternalUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, internalUrl, externalUrl, _apiToken = "apiToken", isActive, useInternalUrl
    }
    
    static let example = HAConfiguration(
        name: "Example Home",
        internalUrl: "http://192.168.1.100:8123",
        externalUrl: "https://example.duckdns.org:8123",
        apiToken: "your-token-here",
        isActive: true
    )
}

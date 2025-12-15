//
//  Configuration.swift
//  SimpleHomeAssistant
//
//  Model for Home Assistant configuration
//

import Foundation

// MARK: - Authentication

enum AuthMethod: String, Codable {
    case token
    case oauth
}

struct ServiceAuthentication: Codable, Hashable {
    var method: AuthMethod
    var token: String? // For token-based auth
    // OAuth tokens stored separately per URL after authentication
    
    init(method: AuthMethod, token: String? = nil) {
        self.method = method
        self.token = token?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Connection URL

struct ConnectionURL: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String // "Internal", "External", "VPN", etc.
    var url: String
    var oauthToken: String? // OAuth token specific to this URL
    
    init(id: UUID = UUID(), name: String, url: String, oauthToken: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.oauthToken = oauthToken?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Get the token for this URL (either OAuth token or fall back to service token)
    func effectiveToken(serviceAuth: ServiceAuthentication) -> String? {
        if serviceAuth.method == .oauth {
            return oauthToken
        } else {
            return serviceAuth.token
        }
    }
}

// MARK: - Home Assistant Service Configuration

struct HAConfiguration: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String // "Belmont", "Orlando", "Home", etc.
    var authentication: ServiceAuthentication
    var urls: [ConnectionURL] // Multiple URLs per service
    var activeUrlId: UUID? // Which URL is currently active
    var isActive: Bool // Is this the active service?
    
    // Computed property for current URL
    var currentURL: ConnectionURL? {
        if let activeId = activeUrlId {
            return urls.first(where: { $0.id == activeId })
        }
        return urls.first // Default to first URL if none selected
    }
    
    // Computed property for current connection string
    var currentConnectionUrl: String {
        currentURL?.url ?? ""
    }
    
    // Computed property for current token
    var currentToken: String? {
        guard let url = currentURL else { return nil }
        return url.effectiveToken(serviceAuth: authentication)
    }
    
    // Initialize with single URL (migration helper)
    init(id: UUID = UUID(), name: String, authentication: ServiceAuthentication, url: ConnectionURL, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.authentication = authentication
        self.urls = [url]
        self.activeUrlId = url.id
        self.isActive = isActive
    }
    
    // Initialize with multiple URLs
    init(id: UUID = UUID(), name: String, authentication: ServiceAuthentication, urls: [ConnectionURL], activeUrlId: UUID? = nil, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.authentication = authentication
        self.urls = urls
        self.activeUrlId = activeUrlId ?? urls.first?.id
        self.isActive = isActive
    }
    
    // Convenience initializer for token-based auth with internal/external URLs
    init(id: UUID = UUID(), name: String, token: String, internalUrl: String, externalUrl: String, isActive: Bool = false, useInternalUrl: Bool = true) {
        self.id = id
        self.name = name
        self.authentication = ServiceAuthentication(method: .token, token: token)
        
        let internalConnection = ConnectionURL(name: "Internal", url: internalUrl)
        let externalConnection = ConnectionURL(name: "External", url: externalUrl)
        
        self.urls = [internalConnection, externalConnection]
        self.activeUrlId = useInternalUrl ? internalConnection.id : externalConnection.id
        self.isActive = isActive
    }
    
    // Convenience initializer for OAuth with internal/external URLs
    init(id: UUID = UUID(), name: String, internalUrl: String, internalOAuthToken: String?, externalUrl: String, externalOAuthToken: String?, isActive: Bool = false, useInternalUrl: Bool = true) {
        self.id = id
        self.name = name
        self.authentication = ServiceAuthentication(method: .oauth)
        
        let internalConnection = ConnectionURL(name: "Internal", url: internalUrl, oauthToken: internalOAuthToken)
        let externalConnection = ConnectionURL(name: "External", url: externalUrl, oauthToken: externalOAuthToken)
        
        self.urls = [internalConnection, externalConnection]
        self.activeUrlId = useInternalUrl ? internalConnection.id : externalConnection.id
        self.isActive = isActive
    }
    
    static let example = HAConfiguration(
        name: "Example Home",
        token: "your-token-here",
        internalUrl: "http://192.168.1.100:8123",
        externalUrl: "https://example.duckdns.org:8123",
        isActive: true
    )
}

// MARK: - Migration Helper

extension HAConfiguration {
    // For backward compatibility with old model
    var authType: AuthMethod {
        authentication.method
    }
    
    var internalUrl: String {
        urls.first(where: { $0.name == "Internal" })?.url ?? ""
    }
    
    var externalUrl: String {
        urls.first(where: { $0.name == "External" })?.url ?? ""
    }
    
    var useInternalUrl: Bool {
        currentURL?.name == "Internal"
    }
    
    var internalToken: String? {
        if authentication.method == .oauth {
            return urls.first(where: { $0.name == "Internal" })?.oauthToken
        } else {
            return authentication.token
        }
    }
    
    var externalToken: String? {
        if authentication.method == .oauth {
            return urls.first(where: { $0.name == "External" })?.oauthToken
        } else {
            return authentication.token
        }
    }
}

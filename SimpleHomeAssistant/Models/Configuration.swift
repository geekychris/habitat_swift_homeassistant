//
//  Configuration.swift
//  SimpleHomeAssistant
//
//  Model for Home Assistant configuration
//

import Foundation

enum AuthType: String, Codable {
    case token
    case oauth
}

struct HAConfiguration: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var internalUrl: String
    var externalUrl: String
    var authType: AuthType = .token
    private var _internalToken: String?
    private var _externalToken: String?
    var isActive: Bool
    var useInternalUrl: Bool = true
    
    var internalToken: String? {
        get { _internalToken?.trimmingCharacters(in: .whitespacesAndNewlines) }
        set { _internalToken = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    var externalToken: String? {
        get { _externalToken?.trimmingCharacters(in: .whitespacesAndNewlines) }
        set { _externalToken = newValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    var currentUrl: String {
        useInternalUrl ? internalUrl : externalUrl
    }
    
    var currentToken: String? {
        useInternalUrl ? internalToken : externalToken
    }
    
    // Token-based auth initializer (single token for both)
    init(id: UUID = UUID(), name: String, internalUrl: String, externalUrl: String, token: String, isActive: Bool, useInternalUrl: Bool = true) {
        self.id = id
        self.name = name
        self.internalUrl = internalUrl
        self.externalUrl = externalUrl
        self.authType = .token
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        self._internalToken = cleanToken
        self._externalToken = cleanToken
        self.isActive = isActive
        self.useInternalUrl = useInternalUrl
    }
    
    // Separate tokens for internal and external
    init(id: UUID = UUID(), name: String, internalUrl: String, externalUrl: String, internalToken: String, externalToken: String, authType: AuthType = .token, isActive: Bool, useInternalUrl: Bool = true) {
        self.id = id
        self.name = name
        self.internalUrl = internalUrl
        self.externalUrl = externalUrl
        self.authType = authType
        self._internalToken = internalToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self._externalToken = externalToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isActive = isActive
        self.useInternalUrl = useInternalUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, internalUrl, externalUrl, authType
        case _internalToken = "internalToken"
        case _externalToken = "externalToken"
        case isActive, useInternalUrl
    }
    
    static let example = HAConfiguration(
        name: "Example Home",
        internalUrl: "http://192.168.1.100:8123",
        externalUrl: "https://example.duckdns.org:8123",
        token: "your-token-here",
        isActive: true
    )
}

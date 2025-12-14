//
//  ASWebAuthController.swift
//  SimpleHomeAssistant
//
//  OAuth2/PKCE authentication using ASWebAuthenticationSession
//  This is Apple's recommended approach for OAuth authentication
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CommonCrypto

/// OAuth2 authentication controller using ASWebAuthenticationSession
@MainActor
class ASWebAuthController: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseUrl: String
    private let clientId = "https://home-assistant.io/ios"
    private let redirectUri = "homeassistant://auth-callback"
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    
    private var completion: ((Result<String, Error>) -> Void)?
    private var authSession: ASWebAuthenticationSession?
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        super.init()
    }
    
    /// Start OAuth2 authentication flow
    func authenticate(completion: @escaping (Result<String, Error>) -> Void) {
        // Guard against starting authentication if already in progress
        guard authSession == nil else {
            print("⚠️ Authentication already in progress - ignoring duplicate call")
            return
        }
        
        self.completion = completion
        self.error = nil
        self.isLoading = true
        
        // Generate PKCE parameters
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        print("🔐 Starting OAuth2 flow for: \(baseUrl)")
        
        // Build authorization URL
        guard let authURL = buildAuthorizationURL() else {
            completeWithError(AuthError.invalidCallback)
            return
        }
        
        print("🔐 Auth URL: \(authURL.absoluteString)")
        
        // Create and start authentication session
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "homeassistant"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.completeWithError(AuthError.cancelled)
                    } else {
                        self.completeWithError(error)
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    self.completeWithError(AuthError.noAuthorizationCode)
                    return
                }
                
                self.handleCallback(url: callbackURL)
            }
        }
        
        // Present from key window
        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        
        if !authSession!.start() {
            completeWithError(AuthError.authorizationFailed("Failed to start authentication session"))
        }
    }
    
    /// Build the authorization URL
    private func buildAuthorizationURL() -> URL? {
        let state = generateRandomString(length: 32)
        
        var components = URLComponents(string: "\(baseUrl)/auth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        return components?.url
    }
    
    /// Handle the redirect callback
    private func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completeWithError(AuthError.invalidCallback)
            return
        }
        
        // Extract authorization code
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
                completeWithError(AuthError.authorizationFailed(error))
            } else {
                completeWithError(AuthError.noAuthorizationCode)
            }
            return
        }
        
        print("✅ Got authorization code")
        exchangeCodeForToken(code: code)
    }
    
    /// Exchange authorization code for access token
    private func exchangeCodeForToken(code: String) {
        let tokenUrl = URL(string: "\(baseUrl)/auth/token")!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "code_verifier": codeVerifier
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        print("🔄 Exchanging code for token...")
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await completeWithError(AuthError.invalidResponse)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    await completeWithError(AuthError.httpError(httpResponse.statusCode))
                    return
                }
                
                // Parse token response
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let accessToken = json?["access_token"] as? String else {
                    await completeWithError(AuthError.noAccessToken)
                    return
                }
                
                print("✅ Token exchange successful")
                await completeWithSuccess(accessToken)
            } catch {
                await completeWithError(error)
            }
        }
    }
    
    private func completeWithSuccess(_ token: String) {
        isLoading = false
        completion?(.success(token))
        completion = nil
        authSession = nil
    }
    
    private func completeWithError(_ error: Error) {
        isLoading = false
        self.error = error.localizedDescription
        completion?(.failure(error))
        completion = nil
        authSession = nil
    }
    
    // MARK: - PKCE Helper Functions
    
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateRandomString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(length)
            .description
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension ASWebAuthController: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window ?? ASPresentationAnchor()
    }
}

// MARK: - SwiftUI View

struct ASWebAuthView: View {
    let baseUrl: String
    let onSuccess: (String) -> Void
    let onCancel: () -> Void
    
    @StateObject private var authController: ASWebAuthController
    @Environment(\.dismiss) var dismiss
    @State private var hasStartedAuth = false  // Prevent duplicate starts
    
    init(baseUrl: String, onSuccess: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.baseUrl = baseUrl
        self.onSuccess = onSuccess
        self.onCancel = onCancel
        _authController = StateObject(wrappedValue: ASWebAuthController(baseUrl: baseUrl))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if authController.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Authenticating...")
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "lock.shield")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Preparing login...")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Guard against starting auth multiple times if view re-appears
            guard !hasStartedAuth else {
                print("⚠️ ASWebAuthView appeared again but auth already started - ignoring")
                return
            }
            
            print("🌐 ASWebAuthView appeared for URL: \(baseUrl)")
            hasStartedAuth = true
            
            // Start authentication immediately without delay
            print("🔐 Starting OAuth2 flow for: \(baseUrl)")
            authController.authenticate { result in
                switch result {
                case .success(let token):
                    print("✅ Authentication successful for: \(baseUrl)")
                    onSuccess(token)
                    // Don't call dismiss() - let parent handle sheet dismissal
                case .failure(let error):
                    print("❌ Authentication failed for \(baseUrl): \(error.localizedDescription)")
                    onCancel()
                    // Don't call dismiss() - let parent handle sheet dismissal
                }
            }
        }
    }
}

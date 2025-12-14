//
//  DirectOAuthController.swift
//  SimpleHomeAssistant
//
//  Direct OAuth2 controller without SwiftUI sheet complications
//

import Foundation
import AuthenticationServices
import CommonCrypto

/// Direct OAuth2 controller that presents ASWebAuthenticationSession without SwiftUI wrappers
class DirectOAuthController: NSObject {
    private let clientId = "https://home-assistant.io/ios"
    private let redirectUri = "homeassistant://auth-callback"
    private var codeVerifier: String = ""
    private var authSession: ASWebAuthenticationSession?
    
    /// Authenticate with a single URL and return token
    func authenticate(baseUrl: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            print("🔐 [Direct] Starting auth for: \(baseUrl)")
            
            // Generate PKCE
            codeVerifier = generateCodeVerifier()
            let codeChallenge = generateCodeChallenge(from: codeVerifier)
            
            // Build URL
            var components = URLComponents(string: "\(baseUrl)/auth/authorize")
            components?.queryItems = [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "redirect_uri", value: redirectUri),
                URLQueryItem(name: "state", value: generateRandomString(length: 32)),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: "S256")
            ]
            
            guard let authURL = components?.url else {
                continuation.resume(throwing: AuthError.invalidCallback)
                return
            }
            
            print("🔐 [Direct] Auth URL: \(authURL.absoluteString)")
            
            // Create session
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "homeassistant"
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [Direct] Auth error: \(error.localizedDescription)")
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: AuthError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    print("❌ [Direct] No code in callback")
                    continuation.resume(throwing: AuthError.noAuthorizationCode)
                    return
                }
                
                print("✅ [Direct] Got code, exchanging for token...")
                
                // Exchange code for token
                Task {
                    do {
                        let token = try await self.exchangeCodeForToken(code: code, baseUrl: baseUrl)
                        print("✅ [Direct] Token received")
                        continuation.resume(returning: token)
                    } catch {
                        print("❌ [Direct] Token exchange failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = false
            
            if !(authSession?.start() ?? false) {
                continuation.resume(throwing: AuthError.authorizationFailed("Failed to start session"))
            }
        }
    }
    
    private func exchangeCodeForToken(code: String, baseUrl: String) async throws -> String {
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String else {
            throw AuthError.noAccessToken
        }
        
        return accessToken
    }
    
    // MARK: - PKCE Helpers
    
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

extension DirectOAuthController: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window ?? ASPresentationAnchor()
    }
}

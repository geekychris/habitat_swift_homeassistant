//
//  WebViewAuthController.swift
//  SimpleHomeAssistant
//
//  OAuth2/PKCE authentication controller using WebKit
//

import Foundation
import WebKit
import SwiftUI
import Combine
import CommonCrypto

/// OAuth2 authentication result
struct OAuthResult {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
}

/// OAuth2 authentication controller using WebView
class WebViewAuthController: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseUrl: String
    private let clientId = "https://home-assistant.io/ios"
    private let redirectUri = "homeassistant://auth-callback"
    private var codeVerifier: String = ""
    private var codeChallenge: String = ""
    
    private var completion: ((Result<OAuthResult, Error>) -> Void)?
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        super.init()
    }
    
    /// Start OAuth2 authentication flow
    func authenticate(completion: @escaping (Result<OAuthResult, Error>) -> Void) {
        self.completion = completion
        self.error = nil
        self.isLoading = true
        
        // Generate PKCE parameters
        codeVerifier = generateCodeVerifier()
        codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        print("🔐 Starting OAuth2 flow for: \(baseUrl)")
    }
    
    /// Get the authorization URL for the WebView
    func getAuthorizationURL() -> URL? {
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
    func handleCallback(url: URL) {
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
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.completeWithError(error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.completeWithError(AuthError.invalidResponse)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    self.completeWithError(AuthError.httpError(httpResponse.statusCode))
                    return
                }
                
                guard let data = data else {
                    self.completeWithError(AuthError.noData)
                    return
                }
                
                // Parse token response
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    guard let accessToken = json?["access_token"] as? String else {
                        self.completeWithError(AuthError.noAccessToken)
                        return
                    }
                    
                    let refreshToken = json?["refresh_token"] as? String
                    let expiresIn = json?["expires_in"] as? Int
                    
                    print("✅ Token exchange successful")
                    
                    let result = OAuthResult(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        expiresIn: expiresIn
                    )
                    
                    self.completeWithSuccess(result)
                } catch {
                    self.completeWithError(error)
                }
            }
        }.resume()
    }
    
    private func completeWithSuccess(_ result: OAuthResult) {
        isLoading = false
        completion?(.success(result))
        completion = nil
    }
    
    private func completeWithError(_ error: Error) {
        isLoading = false
        self.error = error.localizedDescription
        completion?(.failure(error))
        completion = nil
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

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCallback
    case authorizationFailed(String)
    case noAuthorizationCode
    case invalidResponse
    case httpError(Int)
    case noData
    case noAccessToken
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid callback URL"
        case .authorizationFailed(let error):
            return "Authorization failed: \(error)"
        case .noAuthorizationCode:
            return "No authorization code received"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noData:
            return "No data received from server"
        case .noAccessToken:
            return "No access token in response"
        case .cancelled:
            return "Authentication cancelled"
        }
    }
}

// MARK: - SwiftUI WebView Wrapper

struct WebViewAuthView: View {
    let baseUrl: String
    let onSuccess: (String) -> Void
    let onCancel: () -> Void
    
    @StateObject private var authController: WebViewAuthController
    @Environment(\.dismiss) var dismiss
    
    init(baseUrl: String, onSuccess: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.baseUrl = baseUrl
        self.onSuccess = onSuccess
        self.onCancel = onCancel
        _authController = StateObject(wrappedValue: WebViewAuthController(baseUrl: baseUrl))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if let url = authController.getAuthorizationURL() {
                    WebView(url: url, authController: authController, onSuccess: { token in
                        onSuccess(token)
                        dismiss()
                    })
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Invalid URL")
                            .font(.headline)
                        Text(baseUrl)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if authController.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Authenticating...")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .alert("Authentication Error", isPresented: .constant(authController.error != nil)) {
                Button("OK") {
                    authController.error = nil
                    onCancel()
                    dismiss()
                }
            } message: {
                Text(authController.error ?? "Unknown error")
            }
        }
        .onAppear {
            authController.authenticate { result in
                switch result {
                case .success(let oauthResult):
                    onSuccess(oauthResult.accessToken)
                    dismiss()
                case .failure(let error):
                    print("❌ Authentication failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    let authController: WebViewAuthController
    let onSuccess: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(authController: authController, onSuccess: onSuccess)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let authController: WebViewAuthController
        let onSuccess: (String) -> Void
        
        init(authController: WebViewAuthController, onSuccess: @escaping (String) -> Void) {
            self.authController = authController
            self.onSuccess = onSuccess
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.absoluteString.starts(with: "homeassistant://auth-callback") {
                authController.handleCallback(url: url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

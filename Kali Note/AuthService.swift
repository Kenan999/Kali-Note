//
//  AuthService.swift
//  Kali Note
//
//  Created by Antigravity on 21.03.26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import AuthenticationServices

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authStatusMessage: String = ""
    @Published var errorMessage: String?
    @Published var needsVerification = false {
        didSet {
            if needsVerification {
                // Delay so previous sheets (Account Management) can dismiss fully
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.isPresentingOTP = true
                }
            } else {
                self.isPresentingOTP = false
            }
        }
    }
    @Published var isPresentingOTP = false
    @Published var isSwitchingAccount = false
    @Published var pendingEmail: String = ""
    @Published var lastUserEmail: String? { didSet { UserDefaults.standard.set(lastUserEmail, forKey: "lastUserEmail") }}
    @Published var savedUsers: [SavedUser] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(savedUsers) {
                UserDefaults.standard.set(data, forKey: "savedUsers")
            }
        }
    }
    
    private var modelContext: ModelContext?
    private var activeSession: ASWebAuthenticationSession?
    private let baseURL = "https://nonprovided-bunglingly-roxane.ngrok-free.dev"
    
    private var pollingTimer: AnyCancellable?
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "savedUsers"),
           let users = try? JSONDecoder().decode([SavedUser].self, from: data) {
            self.savedUsers = users
        }
        self.lastUserEmail = UserDefaults.standard.string(forKey: "lastUserEmail")
        
        startCommandPolling()
    }
    
    func resetLocalDatabase() {
        guard let context = modelContext else { return }
        
        isLoading = true
        authStatusMessage = "Resetting Local Data..."
        
        do {
            // Delete all Users
            let users = try context.fetch(FetchDescriptor<User>())
            for user in users { context.delete(user) }
            
            // Delete all AuthMethods
            let auths = try context.fetch(FetchDescriptor<AuthMethod>())
            for auth in auths { context.delete(auth) }
            
            try context.save()
            
            // Reset local state
            currentUser = nil
            savedUsers = []
            needsVerification = false
            pendingEmail = ""
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            
            isLoading = false
            print("SUCCESS: Local database cleared.")
        } catch {
            isLoading = false
            errorMessage = "Reset failed: \(error.localizedDescription)"
        }
    }

    func startCommandPolling() {
        pollingTimer?.cancel()
        pollingTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.checkRemoteCommands()
                }
            }
    }
    
    private func checkRemoteCommands() async {
        let url = URL(string: "\(baseURL)/api/dev/check-commands")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let command = json["command"] as? String,
               command == "reset_swift" {
                print("DEV: Remote reset triggered from dashboard.")
                resetLocalDatabase()
            }
        } catch { } // Silently fail polling
    }
    
    struct SavedUser: Codable, Identifiable, Equatable {
        var id: String { email }
        let email: String
        let name: String
        let photoURL: String?
        let deviceName: String?
    }
    
    var deviceID: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func signInWithApple() async throws {
        try await startNativeSession(provider: "apple")
    }
    
    func signInWithGoogle() async throws {
        try await startNativeSession(provider: "google")
    }
    
    private func startNativeSession(provider: String) async throws {
        guard let context = modelContext else { return }
        
        let clientID = provider == "google" ? "103469241476-4autkq8c4fim13otimr76rak14ch0ish.apps.googleusercontent.com" : "YOUR_APPLE_CLIENT_ID"
        let authBaseURL = provider == "google" ? "https://accounts.google.com/o/oauth2/v2/auth" : "https://appleid.apple.com/auth/authorize"
        let redirectURI = "https://nonprovided-bunglingly-roxane.ngrok-free.dev/oauth2redirect"
        
        let authURL = URL(string: "\(authBaseURL)?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code&scope=openid%20profile%20email")!
        let callbackScheme = "com.kenan.Kali-Note"
        
        isLoading = true
        authStatusMessage = "Connecting to \(provider.capitalized)..."
        
        // Use a continuation to wait for the delegate/callback
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var isContinuationResumed = false
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                Task { @MainActor in
                    guard !isContinuationResumed else { return }
                    isContinuationResumed = true
                    
                    self.activeSession = nil
                    
                    if let error = error {
                        self.isLoading = false
                        if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            continuation.resume(throwing: CancellationError())
                        } else {
                            self.errorMessage = "Login failed: \(error.localizedDescription)"
                            continuation.resume(throwing: error)
                        }
                        return
                    }
                    
                    guard let callbackURL = callbackURL else {
                        self.isLoading = false
                        self.errorMessage = "No callback URL received."
                        continuation.resume(throwing: NSError(domain: "Auth", code: -1))
                        return
                    }
                    
                    // 1. EXTRACT CODE
                    let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true)
                    guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
                        self.isLoading = false
                        self.errorMessage = "Code missing."
                        continuation.resume(throwing: NSError(domain: "Auth", code: -2))
                        return
                    }
                    
                    // 2. EXCHANGE
                    self.authStatusMessage = "Validating..."
                    do {
                        let userResponse = try await self.exchangeCodeWithBackend(code: code, provider: provider)
                        
                        if userResponse.requiresVerification == true {
                            self.pendingEmail = userResponse.email
                            self.needsVerification = true
                            self.isLoading = false
                            continuation.resume()
                            return
                        }
                        
                        // 3. PERSIST (If bypass or verified)
                        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.email == userResponse.email })
                        let existingUsers = (try? context.fetch(descriptor)) ?? []
                        
                        if let existingUser = existingUsers.first {
                            self.currentUser = existingUser
                            self.currentUser?.username = userResponse.name
                            self.currentUser?.profilePhotoURL = userResponse.photoURL
                        } else {
                            let newUser = User(email: userResponse.email, username: userResponse.name)
                            newUser.profilePhotoURL = userResponse.photoURL
                            context.insert(newUser)
                            self.currentUser = newUser
                        }
                        
                        self.updatePersistence(with: self.currentUser!)
                        try? context.save()
                        self.isLoading = false
                        
                        // Explicitly set isLoggedIn to true
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        
                        continuation.resume()
                        print("SUCCESS: Logged in as \(userResponse.email)")
                    } catch {
                        self.isLoading = false
                        self.errorMessage = "Backend error: \(error.localizedDescription)"
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            self.activeSession = session
            session.presentationContextProvider = AuthPresentationAnchor.shared
            session.prefersEphemeralWebBrowserSession = false
            
            if !session.start() {
                self.isLoading = false
                continuation.resume(throwing: NSError(domain: "Auth", code: -3))
            }
        }
    }
    
    func resendOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        authStatusMessage = "Resending code..."
        
        let url = URL(string: "\(baseURL)/api/auth/login-request")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "password": "RESEND_REQUEST"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            isLoading = false
            authStatusMessage = "Code resent!"
        } catch {
            isLoading = false
            errorMessage = "Failed to resend: \(error.localizedDescription)"
        }
    }
    
    func signUpWithEmail(email: String, password: String, username: String) async throws {
        errorMessage = nil
        isLoading = true
        authStatusMessage = "Creating Account..."
        
        let url = URL(string: "\(baseURL)/api/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": username,
            "device_id": deviceID
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 {
                    // Success: Code sent
                    self.pendingEmail = email
                    self.needsVerification = true
                    self.isLoading = false
                    print("SUCCESS: Registration code sent to \(email)")
                } else {
                    // Error: Parse message (German)
                    let errorObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let msg = errorObj?["error"] as? String ?? "Registrierung fehlgeschlagen (\(httpResponse.statusCode))"
                    self.isLoading = false
                    self.errorMessage = msg
                }
            }
        } catch {
            self.isLoading = false
            self.errorMessage = "Netzwerkfehler: \(error.localizedDescription)"
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws -> Bool {
        errorMessage = nil
        isLoading = true
        authStatusMessage = "Anmeldedaten werden geprüft..."
        
        let url = URL(string: "\(baseURL)/api/auth/login-request")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "password": password, "device_id": deviceID]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let requiresVerification = (json?["requires_verification"] as? Bool) ?? true
                    
                    if !requiresVerification {
                        try await self.verifyOTPCode(email: email, code: "BYPASS")
                        return false
                    }
                    
                    self.pendingEmail = email
                    self.needsVerification = true
                    isLoading = false
                    authStatusMessage = "Code wurde an deine E-Mail gesendet."
                    return true
                } else {
                    let errorObj = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
                    let msg = (errorObj["error"] as? String) ?? "Anmeldung fehlgeschlagen (\(httpResponse.statusCode))"
                    self.isLoading = false
                    self.errorMessage = msg
                    return false
                }
            }
            return false
        } catch {
            self.isLoading = false
            self.errorMessage = "Server nicht erreichbar: \(error.localizedDescription)"
            return false
        }
    }
    
    func verifyOTPCode(email: String, code: String) async throws {
        guard let context = modelContext else { return }
        errorMessage = nil
        isLoading = true
        authStatusMessage = "Code wird verifiziert..."
        
        let backendURL = URL(string: "\(baseURL)/api/auth/verify-code")!
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "code": code, "device_id": deviceID]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let userResponse = try JSONDecoder().decode(BackendUser.self, from: data)
                
                // Persist locally
                let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.email == userResponse.email })
                let existingUsers = (try? context.fetch(descriptor)) ?? []
                
                if let existingUser = existingUsers.first {
                    self.currentUser = existingUser
                    existingUser.username = userResponse.name
                    existingUser.profilePhotoURL = userResponse.photoURL
                } else {
                    let newUser = User(email: userResponse.email, username: userResponse.name)
                    newUser.profilePhotoURL = userResponse.photoURL
                    context.insert(newUser)
                    self.currentUser = newUser
                }
                
                self.updatePersistence(with: self.currentUser!)
                try? context.save()
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                isLoading = false
            } else {
                isLoading = false
                errorMessage = "Invalid or expired verification code."
            }
        } catch {
            isLoading = false
            errorMessage = "Verification failed: \(error.localizedDescription)"
        }
    }
    
    private func updatePersistence(with user: User) {
        lastUserEmail = user.email
        
        let deviceName = UIDevice.current.name
        let newSavedUser = SavedUser(email: user.email, name: user.username, photoURL: user.profilePhotoURL, deviceName: deviceName)
        
        if !savedUsers.contains(where: { $0.email == user.email }) {
            savedUsers.append(newSavedUser)
        } else if let index = savedUsers.firstIndex(where: { $0.email == user.email }) {
            savedUsers[index] = newSavedUser // Update info
        }
    }
    
    func removeSavedUser(at offsets: IndexSet) {
        savedUsers.remove(atOffsets: offsets)
    }
    
    func removeSavedUser(email: String) {
        savedUsers.removeAll(where: { $0.email == email })
    }
    
    // --- REAL BACKEND LOGIC ---
    
    struct BackendUser: Codable {
        let email: String
        let name: String
        let photoURL: String?
        let token: String? // Optional if verification is required
        let requires_verification: Bool?
        
        var requiresVerification: Bool { requires_verification ?? false }
    }
    
    private func exchangeCodeWithBackend(code: String, provider: String) async throws -> BackendUser {
        let backendURL = URL(string: "https://nonprovided-bunglingly-roxane.ngrok-free.dev/auth/\(provider)")!
        
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["code": code, "device_id": deviceID, "device_name": UIDevice.current.name]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(BackendUser.self, from: data)
    }
    
    func continueOffline() {
        guard let context = modelContext else { return }
        errorMessage = nil
        
        let offlineEmail = "offline@local"
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.email == offlineEmail })
        let existingUsers = (try? context.fetch(descriptor)) ?? []
        
        if let offlineUser = existingUsers.first {
            self.currentUser = offlineUser
        } else {
            let newUser = User(email: offlineEmail, username: "Guest User", isOffline: true)
            context.insert(newUser)
            try? context.save()
            self.currentUser = newUser
        }
    }
    
    func logout() {
        currentUser = nil
        authStatusMessage = ""
        errorMessage = nil
    }
}

// MARK: - Presentation Context Provider
class AuthPresentationAnchor: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthPresentationAnchor()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the main window as the anchor
        #if os(macOS)
        return NSApplication.shared.windows.first ?? NSWindow()
        #else
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // Fallback: Create a window using the first available scene
        if let firstScene = scenes.first {
            return UIWindow(windowScene: firstScene)
        }
        
        // Final fallback: Return the first available window from help connected scenes
        if let window = scenes.first?.windows.first {
            return window
        }
        
        // If no scene or window exists, we return a basic window as a last resort.
        // On iOS 26+, if we are in this state, authentication cannot realistically proceed.
        if let windowScene = scenes.first {
            return UIWindow(windowScene: windowScene)
        }
        
        // Suppress warning if possible or use basic init for compilation
        return UIWindow()
        #endif
    }
}

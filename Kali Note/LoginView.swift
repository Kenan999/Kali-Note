//
//  LoginView.swift
//  Kali Note
//
//  Created by Antigravity on 20.03.26.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var verificationCode = ""
    @State private var isSigningUp = false
    @State private var isVerifying = false
    
    var body: some View {
        ZStack {
            // Deep Dark Background with Subtle Glows
            Color(red: 0.04, green: 0.06, blue: 0.1) // Deep Navy
                .ignoresSafeArea()
            
            // Subtle Ambient Glows
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: -150, y: -250)
                
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 150, y: 300)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 35) {
                // Logo & Header with Orbiting Themes
                VStack(spacing: 20) {
                    OrbitingThemesView()
                        .frame(width: 200, height: 200)
                        .shadow(color: .indigo.opacity(0.4), radius: 25)
                    
                    VStack(spacing: 4) {
                        Text("Kali Note")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(2.0)
                        
                        Text("All aspects of life, captured.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(0.5)
                    }
                }
                .padding(.top, 40)
                
                // Auth Card
                VStack(spacing: 25) {
                    if isVerifying {
                        verificationSection
                    } else {
                        loginSection
                    }
                }
                .padding(32)
                .background(.ultraThinMaterial.opacity(0.8)) // Darker material feel
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 20)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            // Loading Overlay
            if authService.isLoading {
                LoadingOverlay(message: authService.authStatusMessage)
            }
        }
    }
    
    private var loginSection: some View {
        VStack(spacing: 25) {
            Text(isSigningUp ? "Account erstellen" : "Willkommen zurück")
                .font(.headline)
                .foregroundColor(.white)
                .tracking(0.5)
            
            if let error = authService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 15) {
                #if canImport(UIKit)
                if isSigningUp {
                    customTextField(placeholder: "Benutzername", text: $username, icon: "person", contentType: .username)
                }
                
                customTextField(placeholder: "E-Mail", text: $email, icon: "envelope", keyboardType: .emailAddress, contentType: .emailAddress)
                
                customSecureField(placeholder: "Passwort", text: $password, icon: "lock", contentType: .password)
                #else
                if isSigningUp {
                    customTextField(placeholder: "Benutzername", text: $username, icon: "person")
                }
                
                customTextField(placeholder: "E-Mail", text: $email, icon: "envelope")
                
                customSecureField(placeholder: "Passwort", text: $password, icon: "lock")
                #endif
            }
            
            if !isSigningUp, let lastEmail = authService.lastUserEmail, !lastEmail.isEmpty {
                Button {
                    email = lastEmail
                } label: {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("Fortfahren als \(lastEmail)")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.indigo.opacity(0.9))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(.white.opacity(0.05))
                    .cornerRadius(20)
                }
            }
            
            Button(action: handleAuthAction) {
                Text(isSigningUp ? "Registrieren" : "Anmelden")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(color: .white.opacity(0.1), radius: 10)
            }
            
            HStack(spacing: 15) {
                Rectangle().frame(height: 0.5).foregroundColor(.white.opacity(0.15))
                Text("ODER").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.3))
                Rectangle().frame(height: 0.5).foregroundColor(.white.opacity(0.15))
            }
            
            SocialLoginSection(isLoggedIn: $isLoggedIn)
            
            VStack(spacing: 15) {
                Button("Offline fortfahren") {
                    authService.continueOffline()
                    if authService.currentUser != nil {
                        isLoggedIn = true
                    }
                }
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 14, weight: .medium))
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSigningUp.toggle()
                        authService.errorMessage = nil
                    }
                } label: {
                    Text(isSigningUp ? "Bereits ein Konto? Anmelden" : "Noch kein Konto? Registrieren")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.indigo.opacity(0.9))
                }
            }
        }
    }
    
    private var verificationSection: some View {
        VStack(spacing: 25) {
            Text("Verifizierung")
                .font(.headline).foregroundColor(.white).tracking(0.5)
            
            Text("Wir haben einen 6-stelligen Code an \(authService.pendingEmail) gesendet. Bitte gib diesen unten ein.")
                .font(.caption).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
            
            if let error = authService.errorMessage {
                Text(error).font(.caption).foregroundColor(.red.opacity(0.8)).padding(.horizontal).multilineTextAlignment(.center)
            }
            
            customTextField(placeholder: "6-stelliger Code", text: $verificationCode, icon: "key.fill")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                #if canImport(UIKit)
                .keyboardType(.numberPad)
                #endif
            
            Button {
                Task {
                    try? await authService.verifyOTPCode(email: authService.pendingEmail, code: verificationCode)
                    if authService.currentUser != nil {
                        isLoggedIn = true
                        authService.needsVerification = false
                        isVerifying = false
                    }
                }
            } label: {
                Text("Code verifizieren")
                    .font(.system(size: 16, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.white).foregroundColor(.black).cornerRadius(12)
            }
            
            Button("Zurück zum Login") {
                withAnimation { isVerifying = false }
            }
            .font(.caption).foregroundColor(.indigo.opacity(0.8))
        }
    }
    
    private func handleAuthAction() {
        Task {
            if isSigningUp {
                try? await authService.signUpWithEmail(email: email, password: password, username: username)
                if authService.needsVerification {
                    withAnimation { isVerifying = true }
                }
            } else {
                let success = try? await authService.signInWithEmail(email: email, password: password)
                if success == true {
                    withAnimation { isVerifying = true }
                }
            }
        }
    }
}

// MARK: - Components

struct OrbitingThemesView: View {
    @State private var rotation: Double = 0
    @State private var animateThemes = false
    
    // 20 Themes representing 'All Aspects of Life'
    let themes = [
        "flask", "atom", "function", "curlybraces", "music.note",
        "book", "paintbrush", "leaf", "star", "dollarsign.circle",
        "gavel", "cross.case", "sportscourt", "airplane", "fork.knife",
        "tree", "person.2", "cpu", "lock.shield", "eye.slash"
    ]
    
    var body: some View {
        ZStack {
            // Orbiting Icons (Disorderly / Artistic Cloud)
            ForEach(0..<themes.count, id: \.self) { index in
                Image(systemName: themes[index])
                    .font(.system(size: CGFloat.random(in: 12...18), weight: .light))
                    .foregroundColor(.white.opacity(Double.random(in: 0.05...0.2)))
                    .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -100...100))
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .rotationEffect(.degrees(rotation * (index % 2 == 0 ? 1 : -1) * 0.5)) // Slow opposite rotations
                    .scaleEffect(animateThemes ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: Double.random(in: 3...6)).repeatForever(autoreverses: true), value: animateThemes)
            }
            
            // Central Glyph (The chosen primary)
            AppLogoView(size: 80)
        }
        .onAppear {
            animateThemes = true
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct customTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    #if canImport(UIKit)
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    #endif
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                #if canImport(UIKit)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                #endif
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.2)))
    }
}

struct customSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    #if canImport(UIKit)
    var contentType: UITextContentType? = nil
    #endif
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
                #if canImport(UIKit)
                .textContentType(contentType)
                #endif
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.2)))
    }
}

struct SocialLoginSection: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            SocialButton(
                title: "Mit Apple anmelden",
                systemName: "apple.logo",
                color: .black,
                textColor: .white
            ) {
                Task {
                    try? await authService.signInWithApple()
                    if authService.currentUser != nil {
                        withAnimation { isLoggedIn = true }
                    }
                }
            }
            
            SocialButton(
                title: "Mit Google anmelden",
                imageName: "GoogleLogo", // User should add this
                systemName: "g.circle.fill", // Fallback
                color: .white,
                textColor: .black.opacity(0.8),
                isGoogle: true
            ) {
                Task {
                    try? await authService.signInWithGoogle()
                    if authService.currentUser != nil {
                        withAnimation { isLoggedIn = true }
                    }
                }
            }
        }
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .indigo))
                    .scaleEffect(1.2)
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .medium))
                    .tracking(0.5)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct SocialButton: View {
    let title: String
    var imageName: String? = nil
    var systemName: String? = nil
    let color: Color
    let textColor: Color
    var isGoogle: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let imageName = imageName, let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                } else if let systemName = systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 18))
                        .symbolRenderingMode(isGoogle ? .multicolor : .monochrome) // Google specific fallback
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isGoogle ? .clear : .white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isGoogle ? 0.1 : 0), radius: 5, y: 2)
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}

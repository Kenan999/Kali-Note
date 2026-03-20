//
//  LoginView.swift
//  Kali Note
//
//  Created by Antigravity on 20.03.26.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email: String = ""
    @State private var animateGradients: Bool = false
    
    var body: some View {
        ZStack {
            // Animated Background Gradient
            LinearGradient(colors: [.indigo, .purple, .blue], 
                           startPoint: animateGradients ? .topLeading : .bottomLeading, 
                           endPoint: animateGradients ? .bottomTrailing : .topTrailing)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        animateGradients.toggle()
                    }
                }
            
            VStack(spacing: 30) {
                // Logo & Header
                VStack(spacing: 10) {
                    Image(systemName: "pencil.and.outline")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    Text("Kali Note")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 50)
                
                // Glassmorphic Card
                VStack(spacing: 20) {
                    Text("Welcome Back")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        TextField("", text: $email)
                            .padding()
                            .background(.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.2)))
                    }
                    
                    Button {
                        isLoggedIn = true
                    } label: {
                        Text("Login")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.indigo)
                            .cornerRadius(12)
                    }
                    
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
                        Text("OR").font(.caption2).foregroundColor(.white.opacity(0.5))
                        Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
                    }
                    
                    // Social Login
                    HStack(spacing: 20) {
                        SocialButton(systemName: "apple.logo", color: .black) { isLoggedIn = true }
                        SocialButton(systemName: "g.circle.fill", color: .red) { isLoggedIn = true }
                        SocialButton(systemName: "play.fill", color: .green) { isLoggedIn = true }
                    }
                }
                .padding(30)
                .background(.ultraThinMaterial)
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 25)
                
                Spacer()
            }
        }
    }
}

struct SocialButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(.white.opacity(0.1))
                .foregroundColor(.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}

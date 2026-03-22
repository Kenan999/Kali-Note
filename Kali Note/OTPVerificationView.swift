import SwiftUI
import Combine

struct OTPVerificationView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var verificationCode = ""
    @Environment(\.dismiss) var dismiss
    
    @State private var timeLeft = 120
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.1).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.bottom, 10)
                        
                        Text("Verifizierung erforderlich")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Wir haben einen 6-stelligen Code an\n**\(authService.pendingEmail)** gesendet.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(timeString(timeLeft))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(timeLeft > 0 ? .blue : .red)
                            .padding(.top, 5)
                            .onReceive(timer) { _ in
                                if timeLeft > 0 {
                                    timeLeft -= 1
                                }
                            }
                    }
                    
                    VStack(spacing: 20) {
                        TextField("6-stelliger Code", text: $verificationCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button {
                            Task {
                                try? await authService.verifyOTPCode(email: authService.pendingEmail, code: verificationCode)
                                if authService.currentUser != nil {
                                    authService.needsVerification = false
                                    dismiss()
                                }
                            }
                        } label: {
                            if authService.isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("Code bestätigen")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .disabled(verificationCode.count < 6 || authService.isLoading || timeLeft == 0)
                        
                        Button {
                            Task {
                                await authService.resendOTP(email: authService.pendingEmail)
                                timeLeft = 120
                            }
                        } label: {
                            Text("Code erneut senden")
                                .font(.subheadline.bold())
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 10)
                        .disabled(authService.isLoading)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        authService.needsVerification = false
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
    
    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

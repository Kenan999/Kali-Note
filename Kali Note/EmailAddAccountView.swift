import SwiftUI

struct EmailAddAccountView: View {
    enum AuthMode: String, CaseIterable {
        case login = "Anmelden"
        case register = "Registrieren"
    }
    
    enum Field: Hashable {
        case username, email, password
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @FocusState private var focusedField: Field?
    
    @State private var authMode: AuthMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.1).ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Modern Segmented Picker
                    Picker("Modus", selection: $authMode) {
                        ForEach(AuthMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    VStack(spacing: 20) {
                        if authMode == .register {
                            customTextField(placeholder: "Dein Name", text: $username, icon: "person")
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                        }
                        
                        customTextField(placeholder: "E-Mail Adresse", text: $email, icon: "envelope", keyboardType: .emailAddress)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                        
                        passwordField
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                    }
                    .padding(.horizontal)
                    
                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    submitButton
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle(authMode == .login ? "Anmelden" : "Neues Konto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .onSubmit {
                handleSubmission()
            }
            .onAppear {
                focusedField = authMode == .register ? .username : .email
            }
        }
    }
    
    private var passwordField: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            
            if isPasswordVisible {
                TextField("Passwort", text: $password)
                    .foregroundColor(.white)
            } else {
                SecureField("Passwort", text: $password)
                    .foregroundColor(.white)
            }
            
            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15)))
    }
    
    private var submitButton: some View {
        Button {
            handleSubmission()
        } label: {
            HStack {
                if authService.isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(authMode == .login ? "Jetzt Anmelden" : "Konto Erstellen")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .disabled(authService.isLoading || email.isEmpty || password.isEmpty || (authMode == .register && username.isEmpty))
    }
    
    private func handleSubmission() {
        if focusedField == .username {
            focusedField = .email
        } else if focusedField == .email {
            focusedField = .password
        } else {
            Task {
                if authMode == .register {
                    try? await authService.signUpWithEmail(email: email, password: password, username: username)
                } else {
                    _ = try? await authService.signInWithEmail(email: email, password: password)
                }
            }
        }
    }
    
    private func customTextField(placeholder: String, text: Binding<String>, icon: String, keyboardType: UIKeyboardType = .default) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15)))
    }
}

import SwiftUI

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var showingEmailAdd = false
    
    var body: some View {
        NavigationView {
            ZStack {
                KaliColor.background.ignoresSafeArea()
                
                List {
                    savedAccountsSection
                    addAccountSection
                    developerSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Konten")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(KaliColor.primaryText.opacity(0.8))
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingEmailAdd) {
                EmailAddAccountView()
                    .environmentObject(authService)
            }
            .onChange(of: authService.needsVerification) { newValue in
                if newValue { dismiss() }
            }
        }
    }
    
    // --- SUB-VIEWS ---
    
    private var savedAccountsSection: some View {
        Section {
            ForEach(authService.savedUsers) { savedUser in
                Button {
                    Task {
                        let success = try? await authService.signInWithEmail(email: savedUser.email, password: "SAVED_SESSION")
                        if success == true {
                            authService.pendingEmail = savedUser.email
                            authService.needsVerification = true
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        initialsOrImage(for: savedUser)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(savedUser.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(KaliColor.primaryText)
                            HStack(spacing: 4) {
                                Text(savedUser.email)
                                if let device = savedUser.deviceName {
                                    Text("•")
                                    Text(device).italic()
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundColor(KaliColor.secondaryText)
                        }
                        
                        Spacer()
                        
                        if authService.currentUser?.email == savedUser.email {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(KaliColor.secondaryText.opacity(0.2))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: authService.removeSavedUser)
        } header: {
            Text("Gespeicherte Konten")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(KaliColor.secondaryText)
        } footer: {
            Text("Wische nach links, um ein Konto zu entfernen.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
    }
    
    private var addAccountSection: some View {
        Section {
            Menu {
                Button { Task { try? await authService.signInWithGoogle() } } label: {
                    Label("Google", systemImage: "g.circle.fill")
                }
                Button { Task { try? await authService.signInWithApple() } } label: {
                    Label("Apple", systemImage: "apple.logo")
                }
                Button { showingEmailAdd = true } label: {
                    Label("E-Mail", systemImage: "envelope.fill")
                }
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Konto hinzufügen")
                    Spacer()
                    if authService.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(KaliColor.secondaryText.opacity(0.4))
                    }
                }
                .padding(.vertical, 4)
            }
            .disabled(authService.isLoading)
        }
        .listRowBackground(KaliColor.primaryText.opacity(0.04))
    }
    
    private var developerSection: some View {
        Section {
            Button(role: .destructive) {
                authService.resetLocalDatabase()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Lokale Datenbank zurücksetzen")
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                }
            }
        } header: {
            Text("Entwickler")
        } footer: {
            Text("Löscht alle lokalen Daten unwiderruflich.")
        }
    }
    
    @ViewBuilder
    private func initialsOrImage(for user: AuthService.SavedUser) -> some View {
        ZStack {
            if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsCircle(user.name)
                }
            } else {
                initialsCircle(user.name)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
    
    private func initialsCircle(_ name: String) -> some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Text(String(name.prefix(2)).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(KaliColor.secondaryText)
            )
    }
}

#Preview {
    AccountManagementView()
        .environmentObject(AuthService.shared)
}

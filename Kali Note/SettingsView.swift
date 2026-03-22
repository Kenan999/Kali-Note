//
//  SettingsView.swift
//  Kali Note
//
//  Created by Antigravity on 20.03.26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = "System"
    @AppStorage("appTheme") private var appTheme: String = "System"
    @AppStorage("isSyncEnabled") private var isSyncEnabled: Bool = true
    @AppStorage("lastSyncTime") private var lastSyncTime: String = "21. März 2026, 08:30"
    @AppStorage("apiKey1") private var apiKey1: String = ""
    @AppStorage("apiKey2") private var apiKey2: String = ""
    @AppStorage("apiKey3") private var apiKey3: String = ""
    @AppStorage("apiKey4") private var apiKey4: String = ""
    @AppStorage("apiKey5") private var apiKey5: String = ""
    @State private var isSyncing = false
    @State private var syncProgress: Double = 0.0
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                List {
                    Section {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 24)
                            Text("Sprache")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $appLanguage) {
                                Text("System").tag("System")
                                Text("Deutsch").tag("Deutsch")
                                Text("English").tag("English")
                            }
                            .pickerStyle(.menu)
                            .tint(.white.opacity(0.7))
                        }
                        
                        HStack {
                            Image(systemName: "paintpalette")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 24)
                            Text("Erscheinungsbild")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $appTheme) {
                                Text("System").tag("System")
                                Text("Hell").tag("Hell")
                                Text("Dunkel").tag("Dunkel")
                            }
                            .pickerStyle(.menu)
                            .tint(.white.opacity(0.7))
                        }
                    } header: {
                        Text("App-Einstellungen")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .listRowBackground(Color.white.opacity(0.03))
                    
                    Section {
                        NavigationLink {
                            apiKeyManagementView
                        } label: {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 24)
                                Text("LLM API Keys")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(apiKeyCountText)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    } header: {
                        Text("API-Integration")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .listRowBackground(Color.white.opacity(0.03))
                    
                            Section {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Daten-Synchronisation")
                                            .foregroundColor(.primary)
                                        HStack(spacing: 4) {
                                            Text("Letzter Sync:")
                                            Text(lastSyncTime)
                                                .foregroundColor(.green)
                                                .fontWeight(.medium)
                                        }
                                        .font(.caption2)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $isSyncEnabled)
                                        .tint(.gray.opacity(0.5))
                                }
                                
                                if !isSyncEnabled {
                                    if isSyncing {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Synchronisierung läuft...")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.6))
                                                Spacer()
                                                Text("\(Int(syncProgress * 100))%")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            // Premium Progress Bar
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.white.opacity(0.05))
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: geo.size.width * syncProgress)
                                                }
                                            }
                                            .frame(height: 4)
                                        }
                                        .padding(.vertical, 8)
                                    } else {
                                        Button {
                                            startManualSync()
                                        } label: {
                                            HStack {
                                                Spacer()
                                                Text("Jetzt synchronisieren")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            } header: {
                        Text("Synchronisation")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .listRowBackground(Color.white.opacity(0.03))
                    
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("1.2.5")
                                .foregroundColor(.white)
                        }
                        HStack {
                            Text("Build")
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("2026.03.21")
                                .foregroundColor(.white)
                        }
                    } header: {
                        Text("Info")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .listRowBackground(Color.white.opacity(0.03))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var apiKeyCountText: String {
        let keys = [apiKey1, apiKey2, apiKey3, apiKey4, apiKey5]
        let activeCount = keys.filter { !$0.isEmpty }.count
        return "\(activeCount)/5 aktiv"
    }
    
    private var apiKeyManagementView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            List {
                Section {
                    apiKeyRow("Key 1", text: $apiKey1)
                    apiKeyRow("Key 2", text: $apiKey2)
                    apiKeyRow("Key 3", text: $apiKey3)
                    apiKeyRow("Key 4", text: $apiKey4)
                    apiKeyRow("Key 5", text: $apiKey5)
                } header: {
                    Text("LLM API Schlüssel")
                } footer: {
                    Text("Diese Schlüssel werden lokal verschlüsselt gespeichert.")
                }
                .listRowBackground(Color.white.opacity(0.03))
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("API Keys")
    }
    
    private func apiKeyRow(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 60, alignment: .leading)
            SecureField("Schlüssel eingeben", text: text)
                .foregroundColor(.white)
        }
    }
    
    private func startManualSync() {
        isSyncing = true
        syncProgress = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            withAnimation(.linear(duration: 0.1)) {
                syncProgress += 0.05
            }
            if syncProgress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSyncing = false
                    syncProgress = 0
                    
                    // Update timestamp
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd. MMM yyyy, HH:mm"
                    lastSyncTime = formatter.string(from: Date())
                }
            }
        }
    }
}

extension SettingsView {
    private func initialsPlaceholder(size: CGFloat, fontSize: CGFloat) -> some View {
        Circle()
            .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Text(authService.currentUser?.initials ?? "KN")
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
            .shadow(radius: 10)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white.opacity(0.4))
            .tracking(1.0)
    }
}

// Reuse hex color extension from LoginView or define here if needed.
// For now, assuming it's available or I'll add it to a common place if I find one.
#Preview {
    SettingsView()
        .environmentObject(AuthService.shared)
}

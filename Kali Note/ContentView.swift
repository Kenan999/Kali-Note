//
//  ContentView.swift
//  Kali Note
//
//  Created by Kenan Ali on 20.03.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("appTheme") private var appTheme: String = "System"
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthService.shared
    @State private var showSettings = false
    @State private var showAccountManagement = false
    @AppStorage("sortOption") private var sortOption: String = "Datum"
    @State private var searchText = ""
    @Query private var items: [Item]
    
    init() {
        // Ensure shared instance is used
    }

    var body: some View {
        ZStack {
            if !isLoggedIn {
                LoginView(isLoggedIn: $isLoggedIn)
                    .onAppear {
                        authService.setContext(modelContext)
                    }
                    .preferredColorScheme(colorScheme)
            } else {
                mainContent
                    .preferredColorScheme(colorScheme)
            }
        }
        .sheet(isPresented: $authService.isPresentingOTP) {
            OTPVerificationView()
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "Hell": return .light
        case "Dunkel": return .dark
        default: return nil
        }
    }

    private var mainContent: some View {
        NavigationSplitView {
            ZStack(alignment: .bottomLeading) {
                List {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
                .searchable(text: $searchText, prompt: "Suchen...")
                
                // Floating Add Button (Bottom Left)
                Button(action: addItem) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                }
                .padding(.leading, 20)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 12) {
                        // 1. Account Profile
                        Menu {
                            Section("Account") {
                                Button { showAccountManagement = true } label: { Label("Konten verwalten", systemImage: "person.2.fill") }
                                Button(role: .destructive) { isLoggedIn = false; authService.logout() } label: { Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right") }
                            }
                        } label: {
                            profileMenuLabel
                        }
                        
                        // 2. Settings
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // 3. Cloud Sync Status (New)
                        Button {
                            // Could trigger a manual sync or show sync status
                        } label: {
                            Image(systemName: "icloud.and.arrow.down.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue.opacity(0.9))
                        }
                        
                        // 4. Sort Menu
                        Menu {
                            Button { sortOption = "A-Z" } label: { Label("A-Z", systemImage: "sort.ascending") }
                            Button { sortOption = "Z-A" } label: { Label("Z-A", systemImage: "sort.descending") }
                            Button { sortOption = "1-9" } label: { Label("0-9", systemImage: "textformat.123") }
                            Button { sortOption = "9-1" } label: { Label("9-0", systemImage: "textformat.123") }
                            Button { sortOption = "Datum" } label: { Label("Datum", systemImage: "calendar") }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showAccountManagement) {
                AccountManagementView()
                    .environmentObject(authService)
            }
        } detail: {
            Text("Select an item")
        }
    }

    private var profileMenuLabel: some View {
        ZStack {
            if let photoURL = authService.currentUser?.profilePhotoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        initialsPlaceholder
                    }
                }
                .frame(width: 34, height: 34)
                .clipShape(Circle())
            } else {
                initialsPlaceholder
            }
        }
        .frame(width: 34, height: 34)
        .contentShape(Circle())
    }

    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        } else {
            // Simple filtering by timestamp string for demo
            return items.filter { item in
                item.timestamp.description.contains(searchText)
            }
        }
    }

    private var initialsPlaceholder: some View {
        Circle()
            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 34, height: 34)
            .overlay(
                Text(authService.currentUser?.initials ?? "KN")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

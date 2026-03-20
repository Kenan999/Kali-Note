# Information - Kali Note Feature Log

This file documents the features and changes made to the "Kali Note" project.

## [2026-03-20] - Initial Setup & Documentation

- Created `README.md` and `information.md`.
- Established DBML-based database modeling.
- Recommended VS Code extensions for ERD visualization.
- Initial project structure for macOS/iOS development.

## [2026-03-20] - User Authentication Schema

- Added `users` table to the database schema.
- Added `auth_methods` to support multi-account login:
    - **Google Account**
    - **Apple Account**
    - **Android (Google Play) Account**
    - **Normal Account (Email/Password)**
- Supported account switching and adding multiple accounts per user.

## [2026-03-20] - iOS Implementation: Authentication & UI

- **SwiftData Models**: Implemented `User` and `AuthMethod` models with relational and "document-oriented" (JSON metadata) support.
- **Premium Login UI**: Created `LoginView.swift` with animated gradients, glassmorphism, and multi-provider login buttons.
- **State Management**: Integrated authentication state in `ContentView.swift` using `@AppStorage`.
- **Logout Feature**: Added a logout button for easy account switching.

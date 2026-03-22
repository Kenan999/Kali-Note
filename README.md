# Kali Note

Kali Note is a professional, local-first note-taking framework designed for cross-platform performance and secure intelligence. We prioritize data integrity, native speed, and a foundation architected for semantic search.

## 🏗 Core Architecture

Kali Note is built with a sophisticated multi-tier architecture to ensure reliability across the Apple ecosystem and beyond.

- **iOS Client**: Native **SwiftUI** implementation utilizing **SwiftData** for robust local persistence.
- **Backend Hub**: A RESTful **Flask** infrastructure managing identity and state synchronization.
- **Database Layer**: Normalized **SQLite** schema designed for consistent state management.
- **Security**: Environment-centric configuration via `.env` abstraction.

## ✨ Implemented Features

- 🔐 **Multi-Method Authentication**: Native integration for Apple ID, Google OAuth, and secure Email/Password accounts.
- 📬 **Security Gateboarding**: Dynamic 6-digit OTP verification enforced for all paths.
- ☁️ **State Synchronization**: Automatic background syncing to maintain parity between devices.
- 🎨 **Professional Interface**: A curated dark mode UI specialized for power users.

---

## 🚀 Setup

Kali Note requires a `.env` file in the project root for local configuration:

1.  **Define Secrets**:
    ```bash
    NGROK_AUTH_TOKEN=[your_token]
    GOOGLE_CLIENT_ID=[your_client_id]
    GOOGLE_CLIENT_SECRET=[your_client_secret]
    ```
2.  **Boot System**:
    - **Backend**: `python3 app.py`
    - **Tunnel**: `ngrok http 3000`

---

## 🪐 Development Roadmap

The architecture is engineered to transition into a **Semantic Memory Engine**:

- **Phase 1**: Contextual Search & Knowledge Retrieval.
- **Phase 2**: Automated Note Summarization.
- **Phase 3**: Offline AI intelligence.

---

<p align="center">
  <b>© 2026 Kenan Ali. All Rights Reserved.</b>
</p>

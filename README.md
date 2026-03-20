# Kali Note

Kali Note is a premium note-taking application designed for seamless synchronization across multiple platforms, including macOS, iOS (iPhone/iPad), Android, and Windows.

## Project Overview

- **Design Philosophy**: High-end aesthetics and user experience, similar to OneNote or Notion but with a focus on local-first and cross-platform performance.
- **Database Modeling**: Uses DBML (Database Markup Language) for schema design and ERD visualization via `dbdiagram.io`.
- **Target Platforms**: Initially focusing on macOS and iOS, with future support for Android and Windows.
- **Git Strategy**: [Branching Strategy Guide](BRANCHING_STRATEGY.md)

## Getting Started

### DBML Support in VS Code

To view Entity-Relationship Diagrams (ERDs) and get syntax highlighting for `.dbml` files, please install the **official dbdiagram.io extension**:
- [dbdiagram-vscode](https://marketplace.visualstudio.com/items?itemName=holistics.dbdiagram-vscode)

#### Opening the Preview
When you have a `.dbml` file open, you can view the ERD in two ways:
- **Editor Button**: Click the preview icon in the editor title bar (visible when a `.dbml` file is open).
- **Command Palette**: Open the command palette (`Cmd+Shift+P` on macOS) and search for **"DBML: Open Preview to the Side"**.

#### Editing
Simply edit your DBML file in the editor — the diagram updates automatically as you make changes.

#### Login for Paid Features
To access premium features (if you have a paid plan), log in with your `dbdiagram.io` account:
- **Command Palette**: Search for **"Login with dbdiagram"**.
- **VS Code Manage Accounts**: Click the account icon in the bottom left corner and select **"Sign in with dbdiagram"**.

### Schema Visualization

The project uses `schema.dbml` to define the database structure. Opening this file in VS Code with the recommended extension will provide a live ERD visualization.

## Database Connection & DBML Generation

We are implementing support for generating DBML directly from database connections (PostgreSQL, MySQL, SQL Server).

## Authentication & User Management

Kali Note supports a multi-account authentication system, allowing users to link and switch between various login methods:
- **Google Account**
- **Apple Account**
- **Android (Google Play) Account**
- **Normal Account** (Email/Password)

The database schema (`schema.dbml`) is designed to handle multiple authentication providers per user for a flexible login experience.

- [x] Multi-platform support (Planned)
- [x] DBML Integration
- [x] ERD Visualization

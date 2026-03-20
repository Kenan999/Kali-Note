# Git Branching Strategy - Kali Note

This document outlines the Git branching strategy for the "Kali Note" cross-platform project.

## Concept

- **`main` Branch**: Contains only platform-independent core logic (business logic, database handling, API clients). This branch must always be stable and production-ready.
- **Platform Branches**: `platform/web`, `platform/ios`, `platform/android`, `platform/desktop`. These branches extend from `main` and contain only UI, device-specific features, and OS adaptations.

## Rules

1. **Core Logic First**: All business logic and shared code must be developed in `main` or a feature branch targeting `main`.
2. **No Duplication**: Platform branches must strictly reuse the core logic from `main`.
3. **Synchronization**: `main` should be regularly merged into all platform branches to ensure they have the latest core features.
4. **Upward Merges**: Only merge a platform branch back into `main` if the changes made are platform-independent and beneficial to the entire project.

---

### 1. Why This Structure is Optimal

**Scalability**:
- **Parallel Development**: Different teams can work on different platforms (e.g., iOS vs. Android) without blocking each other or polluting the core logic.
- **Micro-Services for UI**: Each platform branch acts as a specialized "subscriber" to the core logic, allowing the UI to scale independently of the backend/engine.

**Maintainability**:
- **Single Source of Truth**: Any bug found in the business logic is fixed once in `main` and propagated to all platforms via merges. This eliminates "divergent logic" bugs.
- **Clean Separation**: New developers can focus on a specific platform without needing to understand the intricacies of every other OS's implementation.

---

### 2. Merges and Conflict Resolution

**Regular Synchronization**:
- **Strategy**: Use `git merge main` into platform branches daily or after any significant core update.
- **Conflict Handling**:
    - **Core Conflicts**: If two platforms require different core behaviors, refactor the core logic in `main` to be more generic or injectable (e.g., using Interfaces/Protocols) rather than creating platform-specific hacks in the core.
    - **UI Conflicts**: Should be localized to the platform branch and resolved there.

**Merging Back to Main**:
- Use Pull Requests (PRs) to ensure that any code moving from a platform branch to `main` is truly platform-independent.
- If a feature developed on `platform/ios` is found to be useful for Android/Web, it should be extracted into a core module and moved to `main`.

---

### 3. CI/CD Workflow

**Continuous Integration (Core)**:
- **Trigger**: Every push/PR to `main`.
- **Actions**: Run platform-independent unit tests, linting, and database migration checks.

**Continuous Integration (Platform)**:
- **Trigger**: Every push to a `platform/*` branch.
- **Actions**: Build the platform-specific app (e.g., Xcode for iOS, Gradle for Android) and run UI/Integration tests.

**Continuous Deployment**:
- **`platform/ios`**: Auto-deploy to TestFlight on successful build.
- **`platform/android`**: Auto-deploy to Play Store Internal Testing.
- **`platform/web`**: Auto-deploy to a staging/production URL (e.g., Vercel, Firebase).
- **`main`**: Acts as the "release gate"—when `main` is tagged with a version, all platform branches should be synced and deployed as a coordinated release.

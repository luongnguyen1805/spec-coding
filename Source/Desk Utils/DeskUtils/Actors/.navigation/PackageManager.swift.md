# PackageManager.swift

## Responsibility
Concurrency layer actor coordinating package scanning.

## Role
Fans out Homebrew, npm, and pip ecosystem scanning concurrently via `async let` statements. Delegates execution to the synchronous `PackageTracker` coordinator and merges outcomes into a combined `ScanResult`. Exposes path resolution via `resolveInstallPath(for:)`.

Source: [PackageManager.swift](/Users/Workspaces/AI-SpecCoding/Source/DeskUtils/Actors/PackageManager.swift)

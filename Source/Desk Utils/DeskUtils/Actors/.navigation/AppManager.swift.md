# AppManager.swift

## Responsibility
Concurrency layer actor coordinating desktop application discovery.

## Role
Delegates synchronous scanning to `AppTracker.scan()` and returns the computed `ScanResult` asynchronously to ViewModels. Exposes path resolution via `resolveInstallPath(for:)` for `.userApp` items.

Source: [AppManager.swift](/Users/Workspaces/AI-SpecCoding/Source/DeskUtils/Actors/AppManager.swift)

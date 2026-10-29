# FolderTracker.swift

## Responsibility and Role

Queues filesystem traversal on a serial utility DispatchQueue, reports snapshots through onReport/onComplete callbacks, persists resumable scan state, and supports explicit cancellation via `stop()`. The current API does not use AsyncStream.

Source: [FolderTracker.swift](/Users/Workspaces/AI-SpecCoding/Source/DeskUtils/Keys/FolderTracker.swift)

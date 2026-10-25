# FolderItem Equatable/Hashable Pitfall

`FolderItem.==`/`hash(into:)` previously included `sizeBytes` (a mutable field) alongside `id`. `sizeBytes` changes on every scan tick in `ManageFoldersViewModel.startScan()`'s `onReport` callback, so a `FolderItem` bound to `List(selection:)`/`.tag(...)` stopped comparing equal to itself between ticks — selection appeared to silently reset while a scan was in progress.

Fix: base `==`/`hash(into:)` on `id` (the path) only, matching `SoftwareItem`'s pattern. Keep row/content refresh as a separate concern: SwiftUI `List` rows can keep visible content stale when their view identity remains path-only while `sizeBytes` changes. Use a display-only key such as `FolderItem.sizeRefreshID` for non-expandable row refresh only; expandable tree nodes must keep path-based identity and store disclosure state separately from live scan data.

Lesson: never fold a field that mutates during a live update stream into `Equatable`/`Hashable` for a type used as `List` selection, `.tag()`, or expandable tree identity. If mutable fields must invalidate visible content, scope the rendering identity to the smallest display-only view that needs it.

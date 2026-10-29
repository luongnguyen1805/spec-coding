# Actor and Tracker Concurrency Boundary

`AppManager`, `PackageManager`, and `FolderManager` are actors wrapping their corresponding query trackers. Actor isolation protects actor-owned state; it does not automatically isolate work dispatched by trackers.

`AppManager.loadApps()` invokes the synchronous `AppTracker.scan()`. `PackageManager.loadPackages()` uses `async let` to run the synchronous Homebrew, npm, and pip queries concurrently, then combines their results.

`PackageTracker` and its ecosystem trackers declare `@unchecked Sendable`. This bypasses compiler verification: preserve the absence of shared mutable per-scan state, and review synchronization before adding mutable stored properties.

`FolderManager.startScanning(onReport:onComplete:)` forwards callbacks to `FolderTracker`; `stopScanning()` forwards to `FolderTracker.stop()`. The tracker owns mutable scan state and dispatches scanning onto a serial utility `DispatchQueue`. Its persisted-state fetch also accesses tracker state; the actor wrapper alone does not establish synchronization with that queue. Do not infer comprehensive race safety from `@unchecked Sendable`.

`ManageFoldersViewModel` receives reports through explicit main-actor tasks. The current folder API uses callbacks, not `AsyncStream`.

# Keys Execution Model

Application and package query methods are synchronous. `PackageTrackerProtocol` exposes `isAvailable()`, `scan()`, and `resolveInstallPath(for:)` without `async`. `ShellHelper` runs processes synchronously and calls `waitUntilExit()`; an asynchronous caller does not make these operations non-blocking.

`FolderTracker.scan(onReport:onComplete:)` dispatches filesystem traversal to its serial utility worker queue. It maintains a mutable scan tree and pending paths, persists resumable state, and sends folder snapshots through `@Sendable` callbacks. `FolderScan` is the internal tree; `FolderItem` is the reported value snapshot.

Concurrency orchestration belongs to the managers and view-models. The current implementation has no folder `AsyncStream` API. Cancellation is explicit: `FolderTracker.stop()` sets a lock-guarded flag checked before each folder; the worker then persists the unprocessed queue for resumption, drops callbacks without a final report or completion, and goes idle. Cancelling the consumer task alone does not stop the dispatched scan. See the local memory index for the corresponding review lesson.

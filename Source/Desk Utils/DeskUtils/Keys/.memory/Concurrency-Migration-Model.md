# Concurrency Review Pitfall

Earlier metadata described an async/await and `AsyncStream` migration as completed. Inspection of the implementation showed synchronous query methods, `FolderTracker`'s serial `DispatchQueue`, and progress/completion callbacks instead.

When reviewing concurrency changes, verify method signatures, execution contexts, mutable state ownership, and termination behavior directly. `async let` in an orchestrator does not make synchronous shell or filesystem operations non-blocking. `@unchecked Sendable` suppresses compiler checking and is not proof of race safety.

If a future migration introduces `AsyncStream`, verify producer cancellation and termination explicitly; do not assume an independently dispatched producer stops when its consumer task is cancelled. Keep the current execution contract in local knowledge rather than recording proposed behavior as completed history.

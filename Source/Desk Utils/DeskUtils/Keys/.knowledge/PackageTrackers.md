# Package Tracker Design

## Ecosystem Separation

`PackageTracker` originally mixed Homebrew, npm, and pip shell invocation, JSON
parsing, and install-path resolution in one file. Each ecosystem's parsing
logic and failure modes are unrelated to the others, so bugs or format changes
in one (e.g. a `brew info` JSON schema change) risked touching code for the
others. Splitting each ecosystem into its own `PackageTrackerProtocol`
conformer isolates that logic: `HomebrewPackageTracker`, `NpmPackageTracker`,
`PipPackageTracker`. `PackageTracker` is now a thin coordinator that only
checks availability and delegates.

## Unavailable Runtimes

A missing `brew`/`npm`/`pip` family binary is normal machine state, not a scan
failure. Each tracker's `isAvailable()` is checked by the coordinator before
`scan()` is called synchronously; if unavailable, the coordinator returns an empty
`ScanResult()` with no entry in `errors`. `ScanResult.errors` is reserved for
cases where the runtime exists but the scan or parse actually fails (non-zero
exit, malformed JSON, etc). Do not reintroduce "not installed" error strings.

## Adding an Ecosystem

To add support for another ecosystem (e.g. Gem, Cargo, Go, DotNet, Composer):

1. Create a new file conforming to `PackageTrackerProtocol`.
   The current protocol and its three conformers are synchronous: use `func isAvailable() -> Bool`, `func scan() -> ScanResult`, and `func resolveInstallPath(for:) -> String?`. Each tracker owns a private `ShellHelper`; asynchronous orchestration occurs in the manager and view-model layers.
2. Instantiate it in `PackageTracker` and add a corresponding `scanX()` method
   that checks `isAvailable()` before delegating to `scan()`.
3. Add the new source's case to `resolveInstallPath(for:)`'s switch.

Update `PackageManager` aggregation and the source model/UI where needed; a new coordinator method alone does not include another ecosystem in the scan.

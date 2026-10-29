
# App

- DeskUtils: macOS desktop utilities app
- Swift, SwiftUI, Swift Concurrency
- Independent small utils, one screen per util
    - Software Manager: installed applications and packages
    - Folder Manager: disk usage by folder
- Read-only: inspect and reveal in Finder; no install, uninstall, delete

# UI

- User Interface

- "UI.md" 

# Architecture

- Layers, top to bottom
    - Views: SwiftUI screens and shared components
    - ViewModels: main-actor observable UI state
    - Actors (Managers): orchestration, isolation boundary
    - Keys (Trackers): synchronous system queries
    - Models: value types shared by all layers
- Dependency direction: downward only
- One ViewModel per util, owned by the root view, survives screen switches
- Each Manager actor wraps its Tracker(s)
- Trackers have no shared mutable per-scan state, except FolderTracker

# Models

- SoftwareSource
    - Cases: Applications, homebrew, pip, npm
    - Raw value: display label
    - UI traits per source
        - Icon, tint color, gradient
        - Item noun: "App" for Applications, "Package" otherwise
- SoftwareItem
    - Fields: name, version?, source, installPath?, description?, dependencies?, metadata (key → value)?
    - Identity: installPath, fallback "source:name"
    - Equality and hash: identity only
- ScanResult
    - items: SoftwareItem list
    - errors: message list
- FolderItem
    - Immutable snapshot of one folder node
    - Fields: name, path, sizeBytes, fileCount, childs (name → FolderItem)
    - Identity: path; equality and hash: path only
    - sortedChilds: by size, descending
    - Clone to max depth: deeper childs dropped, size kept
    - Size refresh key: (path, sizeBytes, fileCount), display refresh only
- FolderScan
    - Mutable internal tree node owned by FolderTracker
    - Same fields as FolderItem; Codable for persistence
    - Converts to FolderItem with max depth

## Identity Rules

- Selection identity must be a stable real-world key
- Never random IDs or fields mutated by rescans or live updates
- Mutable fields may drive display refresh only, never selection or tree identity

# Software Manager

## Flow

- Screen appear → full scan
- Refresh → full scan
- Scan
    - Clear items and errors; set scanning
    - Run AppManager and PackageManager concurrently
    - Merge items; sort by name, case-insensitive
    - Merge errors
    - Keep selection if still present; else select first filtered item
- Category change → select first filtered item

## SoftwareViewModel State

- items, scanErrors, isScanning
- selectedCategory: default Applications
- selectedItem
- filteredItems: items of selected category
- itemCount per source
- Install path resolution routed by source
    - Applications → AppManager
    - Packages → PackageManager

## AppManager / AppTracker

- Search dirs: /Applications, ~/Applications
- Top level only, ".app" bundles only, exclude /System
- Name: bundle name without extension
- Version: bundle short version, fallback bundle version
- Install path: bundle path
- Sort by name, case-insensitive
- No errors reported

## PackageManager / PackageTracker

- PackageTracker: thin coordinator over ecosystem trackers
- Scan Homebrew, npm, pip concurrently
- Per ecosystem: availability check → scan
    - Unavailable runtime → empty result, no error
    - Errors only when runtime exists but scan or parse fails
- Aggregate: concat items and errors
- Sort: name case-insensitive, then source
- Install path resolution delegated by source

## PackageTrackerProtocol

- source
- isAvailable
- scan → ScanResult
- resolveInstallPath(item) → path?
- Synchronous; one conformer per ecosystem
- New ecosystem
    - New conformer
    - Coordinator scan method and resolution case
    - Manager aggregation, SoftwareSource case, UI traits

## HomebrewPackageTracker

- Available: "brew" resolvable
- Scan: brew info, JSON v2, installed
- Formulae
    - name, first installed version, desc, dependencies (omit empty)
    - Path: prefix, fallback Cellar path (Homebrew prefix / Cellar / name / version)
    - Homebrew prefix: /opt/homebrew if present, else /usr/local
- Casks
    - token as name, installed version (string or first of list), desc
    - Path: appdir
- Resolve path: brew --prefix name, if exists; else stored path

## NpmPackageTracker

- Available: "npm" resolvable
- Global root: npm root -g
- Scan: npm list global, depth 0, JSON
    - Empty stdout → error
    - Non-zero exit with output → warning error, still parse
    - Parse from first "{" (skip preamble)
- Per dependency: name, version
    - Path: reported path, fallback global root / name
    - Metadata: resolved URL
- Resolve path: stored path

## PipPackageTracker

- Invocation discovery, first match
    - pip3, pip
    - python3 -m pip, python -m pip (only if "pip --version" succeeds)
- Scan: pip list JSON, fallback chain
    - verbose → plain → user verbose → user plain
    - First success wins; all fail → empty, no error
- Package path from location
    - location / name, if exists
    - Matching dist-info folder
    - location
- dist-info match: lowercase, "-" → "_", compare prefix before first "-"
- Resolve path: pip show name → "Location:" line → same path rules; try pip3, pip, python3 -m pip

## ShellHelper

- Synchronous process run, wait for exit
- Capture: stdout, stderr, exit code; never throws
- Run: stdout on success, else throws exit code and stderr
- Launch failure → exit code -1
- Augmented PATH
    - Prepend Homebrew (both arches) and system bin dirs, skip existing
    - Reason: GUI apps get minimal PATH
- which(name)
    - /usr/bin/which with augmented PATH
    - Fallback: probe known absolute locations
        - brew, npm: Homebrew bins
        - pip, pip3: Homebrew, system, pyenv, asdf, conda, user-local
        - Other: Homebrew, system

# Folder Manager

## Flow

- Screen appear
    - Load persisted state
    - Empty or in-progress → start scan (resume)
    - Else show persisted snapshot
- Refresh → start scan
- Screen disappear → stop scan (real cancellation)
- Updates: periodic reports, then final completion

## ManageFoldersViewModel State

- foldersByDrive: drive path → FolderItem tree
- isScanning
- Three-level selection
    - topFolders (drives) → selectedTopFolder
    - bigFolders: childs of selected drive → selectedBigFolder
    - subFolders: childs of selected big folder, cloned to depth 3
- All lists: shallow clones, sorted by size descending
- On each report
    - Replace foldersByDrive
    - Rebuild lists
    - Reselect by identity, else none
- Drive change → clear big folder selection
- No big folder selected → select first
- No drive selected → select first

## FolderManager

- Actor wrapper over FolderTracker
- startScanning(onReport, onComplete)
- stopScanning
- fetchLoadedFoldersAndInProgressStatus → (snapshot, isInProgress)

## FolderTracker

- Single serial utility worker queue
- Single active scan
    - Scan request while scanning → replace callbacks only
- State
    - scannedFolders: drive → FolderScan tree
    - scanningFolders: pending path queue
- Start
    - Persisted queue non-empty → resume
    - Else root "/" named by volume name (fallback "Mac"), queue ["/"]

### Scan Algorithm

- Breadth-first traversal over path queue, index cursor
- Per folder
    - List entries, non-recursive; unreadable → empty
    - Subfolders → enqueue
    - Insert into tree only when depth ≤ 6 components
    - Files: sum size, count
    - Propagate size and count to root and every existing ancestor
- Deeper folders: sizes counted in nearest tree ancestor
- Queue compaction: every 1000 processed, drop processed prefix, reset cursor
- Autorelease per folder
- End
    - Final report, then completion
    - Clear queue, persist, mark idle

### Cancellation

- Stop request sets a cancellation flag, checked before each folder
- On cancel
    - Exit traversal loop
    - Persist tree and remaining queue (resumable)
    - Drop callbacks; no further report or completion
    - Mark idle
- Stop takes effect within one folder step
- Stop when idle: no-op
- Next start resumes from persisted queue

### Filtering

- Directories
    - Real directories only, skip symlinks
    - Skip /dev, /cores, /Volumes, /System/Volumes and descendants
    - Skip system names: .nofollow, .resolve, .vol, .Spotlight-V100, .Trashes, .TemporaryItems, .fseventsd, .DocumentRevisions-V100
- Files
    - Regular files only
    - Skip "._" prefix
    - Skip .DS_Store, .VolumeIcon.icns, .apdisk, .localized
- Size: logical file size

### Reporting

- Snapshot: tree → FolderItem, max depth 6
- Report every ≥ 1 second
- Callbacks Sendable; consumer hops to main actor

### Persistence

- Location: Application Support / DeskUtils / FolderTracker
- Files: scanned tree JSON, pending queue JSON
- Save at compaction, at most every 5 seconds
- Save at completion with empty queue
- In progress: persisted queue non-empty
- Purpose: resume after quit or crash

# Concurrency

- ViewModels: main actor
- Managers: actors
- Trackers: synchronous, blocking
- Async callers do not make tracker work non-blocking
- Concurrency at manager and view-model level
    - Software: parallel app and package scans; parallel ecosystem scans
    - Folder: dispatched worker queue with callbacks
- Unchecked Sendable trackers: no race-safety guarantee; review before adding mutable state
- Folder scan must support real cancellation; cancelling the consumer task alone is insufficient

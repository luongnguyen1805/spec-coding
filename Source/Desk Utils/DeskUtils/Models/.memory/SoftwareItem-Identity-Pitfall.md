# SoftwareItem Identity Pitfall

`SoftwareItem.id` was previously a fresh random `UUID()` generated in `init`, so two `SoftwareItem` instances representing the same real-world app/package across separate scans never compared equal — `List(selection:)`/`.tag(...)` in `SoftwareSecondPanelView` lost selection on every rescan even though the item was "the same" to the user.

Fix: derive `id` from `installPath` (`self.id = installPath ?? "\(source.rawValue):\(name)"`), matching `FolderItem`'s `id == path` pattern. The fallback covers items whose install path is unavailable.

Lesson: same class of bug as [FolderItem identity lesson](/Users/Workspaces/AI-SpecCoding/Source/DeskUtils/Models/.memory/FolderItem-Equatable-Pitfall.md) — for a type used as `List` selection identity, `id` must be derived from a stable real-world key, never a freshly generated value (`UUID()`) or a field that mutates across rescans.

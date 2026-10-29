# Font

- Default: System, 15
- Bold: System, 15, bold
- Numbers: monospaced digits
- Secondary info: secondary color

# Selection

- Row/Card Subview when Selected
    + Background: Lightgray
    + No Text color, Tint color change
- Tap row to select
- Selection by stable identity; survives rescans

# Formatting

- Size: KB (no decimals), MB / GB (1 decimal), base 1024
- Folder summary: "{count} file(s) | {size}"
- Count label: "{n} item(s)", "{n} folder(s)"
- Version: "v{version}"

# Scenes and Windows

- Main scene
  - Main window
    - Min and default size: 1200 × 600
    - Title bar, unified toolbar with title
    - No "New Window" command
- Root routing
  - Dashboard by default
  - One util screen at a time
  - Back returns to Dashboard

# Views

- Dashboard View
    - Title: "Desktop Utilities"
    - Grid: 3 flexible columns
    - Card View 
        Rounded Rect radius=10
        Gray border 1px
        Text: Default Font
        Icon: rounded square, source gradient, white symbol
        Tap → open util

    - Utils
        Manage Applications and Packages
        Manage Folders 

- Side View
    - Back to Dashboard
    - Refresh
        - Replaced by progress indicator while scanning

- Split Layout
    - Three columns: First Panel, Second Panel, Detail
    - Resizable, min / max widths

- Software Manager View
    - Title: "Application Manager"
    - First Panel View: Categories
        - One row per SoftwareSource: icon, label, count badge (if > 0)
        - Warnings section: scan errors, if any
    - Second Panel View: Apps / Packages
        - Header: category name, item count
        - App Row: source icon (tint), name, version
    - Detail View
        - Empty: "Select an Item"
        - Header: source icon tile, name, source badge, version
        - Details Card
            - "{App|Package} Name", Source, Version
            - Install Path + Reveal button
            - Description
        - Dependencies Card, if any: capsule tags, flow layout
        - Metadata Card, if any: sorted keys
    - Reveal in Finder
        - Resolve path on demand; progress while locating
        - Disabled when no path
        - Missing path → alert "Cannot Locate Folder"

- Folder Manager View
    - Title: "Folder Manager"
    - First Panel View: Drives
        - Drive Row: drive icon, name, summary
    - Second Panel View: Big Folders
        - Header: drive name, folder count
        - Folder Row View
        - Empty: "Select a Drive", "No Folders"
    - Detail View
        - Empty: "Select a Folder"
        - Card: big folder name, path, summary
        - Folders Card
            - Toggle: only folders ≥ 100 MB, applied recursively
            - Folder tree: sub folders, 3 nested levels
                - Expand / collapse via chevron or row tap
                - Indent per depth; leaf rows aligned with expandable rows
                - Expansion state kept by path, separate from scan data
    - Live update while scanning

- Folder Row View
	[folder-icon] Name  --- Files | Size [reveal-button]

- Shared Components
    - Card Container: title + content, Card View style
    - Detail Row: secondary label, selectable value
    - Reveal Button: arrow-circle icon, opens Finder at path

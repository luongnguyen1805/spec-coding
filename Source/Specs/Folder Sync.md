
# Main

- List differences between two folders.
    - Left and right folder roots
    - Corresponding files and folders
    - Differences: left-only, right-only, changed

- Allow the user to choose a file or folder as the sync source.
    - Per-item source choice: left or right
    - Selected item replaces its counterpart
    - One-sided items copy to the missing side
    - Selecting the empty side deletes the counterpart file or folder

# Folder Input

- Left and right roots use typed paths
    - Double-click selects text; no folder picker
    - Save the last left and right folder paths on edit, according to `lastProfile`
    - Restore on utility launch according to `lastProfile`

- Folder Input Field
    - Flexible width; height: 50
    - Transparent background
    - No top, left, or right border
    - Black bottom border; width: 1
    - Single-click focuses the field for editing
    - Native macOS editing behavior
    - Placeholder text: "Left Folder", "Right Folder"

# Sync Profiles

- Profile content: left folder, right folder, and custom ignore patterns

```text
LeftFolder=
Right Folder=
Ignores=
```

- Profile storage: Application Support → DeskUtils → Sync Profiles → `{name}.txt`
    - Migrate profiles from the previous Desk Utils folder without overwriting existing profiles
- `lastProfile`: selected profile stored in app preferences; nil means no profile
- On utility launch
    - `lastProfile` is nil → load left folder, right folder, and ignores from app preferences
    - Otherwise → load fields from `lastProfile`
- On field edit (left folder, right folder, ignores)
    - `lastProfile` is nil → save to app preferences
    - Otherwise → save to the `lastProfile` data file
    - Loading fields from a profile or preferences is not an edit

- Profile selector in the top-right corner, with an adjacent add-icon button
    - Pen-icon rename button on its left
        - Hidden when `lastProfile` is nil
    - Minimum width: 200 points
    - Expand to fit the selected profile name
    - System font: 15 points
    - List saved profiles and a "None" option
    - No selected profile → show "None"
    - Selected profile → show its name only, without `.txt`
- Add button → alert requesting a profile name
    - OK → create `{name}.txt` with the current left folder, right folder, and ignores
        - Select the saved profile and persist it as `lastProfile` after successful creation
    - Cancel → save nothing
- Rename button → alert to edit the selected profile name
    - OK → rename `{name}.txt` to `{newName}.txt`, keeping its content
        - Do not overwrite an existing profile
        - Persist the new name as `lastProfile` after successful rename
        - Profile selector shows the new name
    - Cancel → rename nothing
- Selecting a profile
    - Set `lastProfile` to the selected profile in app preferences
    - Populate the folder and filter fields from the profile
    - Apply comparison changes only when Refresh is clicked
- Selecting "None"
    - Set `lastProfile` to nil in app preferences
    - Populate the folder and filter fields from app preferences

# Comparison

- Refresh button applies the current folder paths and filter patterns
    - Editing fields preserves displayed differences, errors, selection, and expansion
    - Enter does not trigger comparison
    - Disable synchronization while inputs differ from the displayed comparison
    - Empty-result status describes the last applied comparison until Refresh

- Match entries by root-relative path
    - Exact filename and file type match
    - File/folder type mismatches are differences
- Compare file size in bytes first
    - Differs → changed
    - Matches → compare contents in 1024-byte blocks, stop at first differing block
- Modification date is not compared
- Include hidden files and package contents, except ignored entries
- Default comparison ignore list
    - Exact entry names: `.DS_Store`, `.git`, `.gitignore`, `node-modules`, `.swift-module-cache`, `.build`, `xcshareddata`, `xcuserdata`
    - Apply on both sides at every folder depth
    - Skip ignored folders and their descendants
- Do not follow symbolic links
- A folder is changed when its descendants differ
- Detect differences without a content diff explorer

# Replacement

- Apply immediately when the user selects an item's action
- Replace the whole destination folder when a folder is selected
- Selecting an empty row deletes the counterpart file or entire folder
- Replace without overwrite confirmation or recovery flow
- Preserve timestamps, permissions, and extended attributes
- Process replacements and deletions one at a time
    - Show loading while an operation is in progress
- Report unreadable entries and failed replacements or deletions
- Refresh affected differences after successful replacement or deletion
    - Resolved difference rows disappear

# UI 

- Refresh button: refresh icon with a transparent background
    - Size: 50 × 50
    - Button bottom = input bottom-border bottom + 15 (15 points below)
- No full-width horizontal borders except the filter input's bottom border

- Layout

```
                                  <rename> (profile-selector) <add>
 (filter-field)
 (left-text-field)_____ <button-refresh> _____(right-text-field)
 (tree-of-files-folders)        |        (tree-of-files-folders)
```

- Trees follow Folder Manager detail-panel style
    - Folder and file icons
    - Expand / collapse folders
    - Indentation by depth
    - Synchronized expansion and scrolling
    - Keyboard navigation when the tree is focused
        - Up / Down: select previous / next visible row
        - Left: collapse the selected folder
        - Right: expand the selected folder
        - A: use the selected row's left side as the replacement source
        - D: use the selected row's right side as the replacement source
        - A / D follow the corresponding source-selection button, including empty-side deletion
        - Replacement shortcuts require synchronization to be enabled; ignore modified keys and key repeats
        - Keep the selected row visible
- Show only new/changed files/folders
    - Retain ancestor folders needed to navigate differences
- If new, leave empty row in opponent-side
    - Align corresponding rows across both trees
- Each row, including empty counterpart rows, ends with a source-selection icon button
    - Replacement direction follows the selected side
    - Selecting an empty row deletes the opposite file or folder to synchronize the row

- When no difference rows remain, show "Folders are synchronized."

- Filter field: custom comparison ignore patterns above the folder input row
    - Full width, spanning both folder inputs and the refresh-button gap
    - Same style as folder inputs: height 50, transparent background, black 1-point bottom border, native text editing
    - Double-click selects text; no folder picker
    - Semicolon-separated paths relative to either root, for example `automation/*.obj; cache`
    - Trim surrounding whitespace; ignore empty patterns
    - Save the filter text on edit, according to `lastProfile`; default to empty when no saved preference exists
    - Restore on utility launch according to `lastProfile`
    - Pattern syntax
        - Case-sensitive; match the entire root-relative path
        - Component matches the exact entry name, for example `vscode` → `./vscode`, `child/vscode` → `./child/vscode`
        - No trailing `/` → match files and folders
        - Trailing `/` → match folders only, for example `claude/` → `./claude/`, `child/claude/` → `./child/claude/`
        - `*` matches zero or more characters within one component, for example `*/vscode`, `automation/*.obj`
        - `**` component matches zero or more components, for example `**/vscode` → `./vscode`, `./child/vscode`, `./child/child2/vscode`
    - Apply on both sides alongside the default ignore list
    - Matching folders exclude their descendants
    - Folder-only pattern ignores the entry on both sides when either side is a folder
    - Edits remain pending until the user clicks Refresh
    - Disabled while comparing or synchronizing
    - Filters affect comparison only; folder actions still replace or delete the whole folder

# Deferred

- Identical or overlapping root validation
- Separate destination-only descendant policy
- Revalidation of items changed since comparison


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

- Left and right roots support typed paths and folder pickers
    - Double-click an input field to open its folder picker
    - No separate open-folder button
    - Save the last left and right folder paths in app preferences
    - Restore saved paths as defaults on the next app launch

- Folder Input Field
    - Flexible width; height: 50
    - Transparent background
    - No top, left, or right border
    - Black bottom border; width: 1
    - Single-click focuses the field for editing
    - Black insertion cursor with native macOS editing behavior
    - Placeholder text: "Left Folder", "Right Folder"

# Comparison

- Match entries by root-relative path
    - Exact filename and file type match
    - File/folder type mismatches are differences
- Compare file size and modification date first
    - Either differs → changed
    - Both match → compare contents to detect remaining differences
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
- No full-width horizontal borders

- Layout

```
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
        - Keep the selected row visible
- Show only new/changed files/folders
    - Retain ancestor folders needed to navigate differences
- If new, leave empty row in opponent-side
    - Align corresponding rows across both trees
- Each row, including empty counterpart rows, ends with a source-selection icon button
    - Replacement direction follows the selected side
    - Selecting an empty row deletes the opposite file or folder to synchronize the row

- When no difference rows remain, show "Folders are synchronized."

# Deferred

- Identical or overlapping root validation
- Separate destination-only descendant policy
- Revalidation of items changed since comparison

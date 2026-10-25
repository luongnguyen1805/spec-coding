# Folder List Selection Hit Testing

Folder Manager rows use `List(selection:)` for native selected-row styling, but the visible row content must also provide a full-width hit target. Keep Folder Manager list rows framed to `maxWidth: .infinity`, give them a rectangular `contentShape`, and update the matching selection binding on tap.

Use direct `FolderItem` tags with the optional selection bindings. `FolderItem` equality and hashing remain path/id based, so refreshed scan clones continue to match the selected row across live scan updates.

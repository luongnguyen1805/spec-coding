import AppKit
import SwiftUI

struct FolderSyncView: View {
    @ObservedObject var viewModel: FolderSyncViewModel
    @FocusState private var treeHasFocus: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Label("Dashboard", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                Text("Folder Sync")
                    .font(.defaultFontBold)
                Spacer()
            }
            .padding(16)

            HStack(alignment: .bottom, spacing: 12) {
                folderInput("Left Folder", path: $viewModel.leftPath)
                Group {
                    if viewModel.isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Button(action: viewModel.refresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 24))
                                .frame(width: 50, height: 50)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Compare folders")
                        .accessibilityLabel("Compare folders")
                        .accessibilityIdentifier("folderSync.refresh")
                    }
                }
                .frame(width: 50, height: 50)
                .offset(y: 15)
                folderInput("Right Folder", path: $viewModel.rightPath)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 31)

            if !viewModel.errors.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.errors.enumerated()), id: \.offset) { _, error in
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }
                .frame(maxHeight: 120)
            }

            if viewModel.isSynchronized {
                Text("Folders are synchronized.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Each visible row contains both sides. A shared scroll position and
                // expansion set keep counterparts aligned, including empty cells.
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(viewModel.visibleRows) { row in
                                HStack(spacing: 0) {
                                    cell(row, side: .left)
                                    Divider()
                                    cell(row, side: .right)
                                }
                                .frame(height: 36)
                                .background(viewModel.selectedPath == row.id ? Color.gray.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .id(row.id)
                            }
                        }
                        .padding(12)
                    }
                    .focusable()
                    .focusEffectDisabled()
                    .focused($treeHasFocus)
                    .onKeyPress(.upArrow) {
                        viewModel.moveSelection(by: -1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        viewModel.moveSelection(by: 1)
                        return .handled
                    }
                    .onKeyPress(.leftArrow) {
                        viewModel.setSelectedFolderExpanded(false)
                        return .handled
                    }
                    .onKeyPress(.rightArrow) {
                        viewModel.setSelectedFolderExpanded(true)
                        return .handled
                    }
                    .onChange(of: viewModel.selectedPath) {
                        if let selectedPath = viewModel.selectedPath {
                            proxy.scrollTo(selectedPath)
                        }
                    }
                }
            }
        }
        .font(.defaultFont)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: viewModel.leftPath) { viewModel.invalidateComparison() }
        .onChange(of: viewModel.rightPath) { viewModel.invalidateComparison() }
    }

    private func folderInput(_ title: String, path: Binding<String>) -> some View {
        FolderInputTextField(
            placeholder: title,
            text: path,
            isEnabled: !viewModel.isBusy,
            onSubmit: viewModel.refresh,
            onDoubleClick: {
                let panel = NSOpenPanel()
                panel.title = "Choose \(title.lowercased())"
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.treatsFilePackagesAsDirectories = true
                panel.showsHiddenFiles = true
                if panel.runModal() == .OK, let url = panel.url {
                    path.wrappedValue = url.path
                }
            }
        )
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(height: 50)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.black).frame(height: 1)
        }
        .accessibilityLabel(title)
        .help("Double-click to choose \(title.lowercased())")
        .disabled(viewModel.isBusy)
    }

    private func cell(_ row: FolderSyncRow, side: FolderSyncSide) -> some View {
        let item = row.item
        let entry = item.entry(on: side)
        return HStack(spacing: 6) {
            if let entry {
                if !item.children.isEmpty {
                    Button {
                        treeHasFocus = true
                        viewModel.toggleExpansion(item)
                    } label: {
                        Image(systemName: viewModel.expandedPaths.contains(item.id) ? "chevron.down" : "chevron.right")
                            .foregroundStyle(.secondary)
                            .frame(width: 14)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Expand or collapse \(item.name)")
                } else {
                    Color.clear.frame(width: 14, height: 1)
                }
                Image(systemName: entry.kind == .folder ? "folder.fill" : entry.kind == .symbolicLink ? "link" : "doc.fill")
                    .foregroundStyle(entry.kind == .folder ? Color.yellow : Color.secondary)
                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 4)
                Text(item.entry(on: side.opposite) == nil ? "New" : "Changed")
                    .foregroundStyle(.secondary)
                    .font(.defaultFont)
            } else {
                Spacer(minLength: 0)
            }
            Button { viewModel.synchronize(item, from: side) } label: {
                Image(systemName: side == .left ? "arrow.right.circle" : "arrow.left.circle")
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.canSynchronize)
            .help(entry == nil ? "Delete opposite \(item.name)" : "Use this \(item.name) as the source")
            .accessibilityLabel(entry == nil ? "Delete opposite \(item.name)" : "Use \(side == .left ? "left" : "right") \(item.name) as source")
        }
        .padding(.leading, 6 + CGFloat(row.depth) * 18)
        .padding(.trailing, 8)
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            treeHasFocus = true
            if entry != nil { viewModel.toggleExpansion(item) }
        }
    }
}

@MainActor
private struct FolderInputTextField: NSViewRepresentable {
    private static let font = NSFont.systemFont(ofSize: 15)
    static let lineHeight = NSLayoutManager().defaultLineHeight(for: font)

    let placeholder: String
    @Binding var text: String
    let isEnabled: Bool
    let onSubmit: () -> Void
    let onDoubleClick: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> FolderInputControl {
        let control = FolderInputControl(frame: .zero)
        let field = control.field
        field.cell = FolderInputCell(textCell: "")
        field.font = Self.font
        field.isEditable = true
        field.isSelectable = true
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.usesSingleLineMode = true
        field.lineBreakMode = .byClipping
        field.cell?.isScrollable = true
        field.delegate = context.coordinator
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.setAccessibilityLabel(placeholder)
        update(field)
        context.coordinator.observeDoubleClicks(in: control)
        return control
    }

    func updateNSView(_ control: FolderInputControl, context: Context) {
        context.coordinator.parent = self
        update(control.field)
    }

    static func dismantleNSView(_ control: FolderInputControl, coordinator: Coordinator) {
        coordinator.stopObservingDoubleClicks()
    }

    private func update(_ field: NSTextField) {
        if field.stringValue != text { field.stringValue = text }
        field.placeholderString = placeholder
        field.isEnabled = isEnabled
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FolderInputTextField
        private var doubleClickMonitor: Any?

        init(parent: FolderInputTextField) {
            self.parent = parent
        }

        func observeDoubleClicks(in control: FolderInputControl) {
            // Editing clicks go to AppKit's shared field editor rather than the
            // NSTextField. Observe local events so double-click works in both states.
            doubleClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self, weak control] event in
                // AppKit invokes local monitors synchronously on the main thread,
                // but the callback signature does not express actor isolation.
                let handled = MainActor.assumeIsolated {
                    guard let self, let control, self.parent.isEnabled,
                          event.clickCount == 2, let window = control.window,
                          event.window === window, !control.isHiddenOrHasHiddenAncestor,
                          control.bounds.contains(control.convert(event.locationInWindow, from: nil)) else {
                        return false
                    }
                    self.parent.onDoubleClick()
                    return true
                }
                return handled ? nil : event
            }
        }

        func stopObservingDoubleClicks() {
            if let doubleClickMonitor {
                NSEvent.removeMonitor(doubleClickMonitor)
                self.doubleClickMonitor = nil
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            parent.onSubmit()
            return true
        }
    }
}

@MainActor
private final class FolderInputControl: NSView {
    let field = NSTextField(frame: .zero)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(field)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(field)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsLayout = true
    }

    override func mouseDown(with event: NSEvent) {
        if field.isEnabled { window?.makeFirstResponder(field) }
    }

    override func layout() {
        super.layout()
        // Keep text near the bottom border using AppKit's default cell layout.
        field.frame = NSRect(x: 5, y: 4, width: max(0, bounds.width - 10), height: FolderInputTextField.lineHeight)
    }
}

private final class FolderInputCell: NSTextFieldCell {
    // A dedicated native editor keeps cursor styling local to this input.
    private lazy var inputEditor: NSTextView = {
        let editor = NSTextView(frame: .zero)
        editor.isFieldEditor = true
        return editor
    }()

    override func fieldEditor(for controlView: NSView) -> NSTextView? {
        inputEditor
    }

    override func setUpFieldEditorAttributes(_ textObj: NSText) -> NSText {
        let editor = super.setUpFieldEditorAttributes(textObj)
        // Configure before AppKit draws the first insertion point, including
        // focus through clicking or keyboard navigation without text changes.
        if let textView = editor as? NSTextView {
            textView.insertionPointColor = .black
            var selectionAttributes = textView.selectedTextAttributes
            selectionAttributes[.backgroundColor] = NSColor.lightGray
            selectionAttributes[.foregroundColor] = NSColor.black
            textView.selectedTextAttributes = selectionAttributes
        }
        return editor
    }
}


import AppKit
import SwiftUI

struct FolderSyncView: View {
    @ObservedObject var viewModel: FolderSyncViewModel
    @FocusState private var treeHasFocus: Bool
    @State private var showingAddProfile = false
    @State private var newProfileName = ""
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
                Menu {
                    Button("None") {
                        Task { await viewModel.selectProfile(nil) }
                    }
                    ForEach(viewModel.profileNames, id: \.self) { name in
                        Button(name) {
                            Task { await viewModel.selectProfile(name) }
                        }
                    }
                } label: {
                    Text(verbatim: viewModel.selectedProfile ?? "None")
                        .frame(minWidth: 200, alignment: .leading)
                }
                .font(.system(size: 15))
                .fixedSize(horizontal: true, vertical: false)
                .disabled(viewModel.isBusy)
                .accessibilityLabel("Sync profile")
                .accessibilityIdentifier("folderSync.profileSelector")

                Button {
                    newProfileName = ""
                    showingAddProfile = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isBusy)
                .help("Add sync profile")
                .accessibilityLabel("Add sync profile")
                .accessibilityIdentifier("folderSync.addProfile")
            }
            .padding(16)

            FolderInputTextField(
                placeholder: "Ignore relative paths, e.g. automation/*.obj; cache",
                text: $viewModel.ignorePatterns,
                isEnabled: !viewModel.isBusy
            )
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 50)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.black).frame(height: 1)
            }
            .accessibilityLabel("Ignore relative paths")
            .accessibilityIdentifier("folderSync.ignorePatterns")
            .help("Semicolon-separated, case-sensitive relative paths. * matches within a path component. Folder actions still affect the whole folder.")
            .disabled(viewModel.isBusy)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

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
                    .onKeyPress(keys: ["a", "d"], phases: [.down, .repeat]) { press in
                        guard press.modifiers.isEmpty else { return .ignored }
                        // Consume repeats so holding a key cannot apply successive rows.
                        guard press.phase == .down else { return .handled }
                        guard viewModel.canSynchronize,
                              let row = viewModel.visibleRows.first(where: { $0.id == viewModel.selectedPath }) else {
                            return .handled
                        }
                        viewModel.synchronize(row.item, from: press.key == "a" ? .left : .right)
                        return .handled
                    }
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
        .task { await viewModel.loadProfiles() }
        .alert("Add Sync Profile", isPresented: $showingAddProfile) {
            TextField("Profile name", text: $newProfileName)
            Button("OK") {
                let name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                Task { await viewModel.createProfile(named: name) }
            }
            .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { newProfileName = "" }
        } message: {
            Text("Save the current folders and ignore patterns as a profile.")
        }
        .alert("Sync Profile Error", isPresented: Binding(
            get: { viewModel.profileError != nil },
            set: { if !$0 { viewModel.profileError = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.profileError = nil }
        } message: {
            Text(viewModel.profileError ?? "")
        }
    }

    private func folderInput(_ title: String, path: Binding<String>) -> some View {
        FolderInputTextField(
            placeholder: title,
            text: path,
            isEnabled: !viewModel.isBusy
        )
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(height: 50)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.black).frame(height: 1)
        }
        .accessibilityLabel(title)
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
        return control
    }

    func updateNSView(_ control: FolderInputControl, context: Context) {
        context.coordinator.parent = self
        update(control.field)
    }

    private func update(_ field: NSTextField) {
        if field.stringValue != text { field.stringValue = text }
        field.placeholderString = placeholder
        field.isEnabled = isEnabled
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FolderInputTextField

        init(parent: FolderInputTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
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
    // A dedicated native editor keeps selection styling local to this input.
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
        if let textView = editor as? NSTextView {
            var selectionAttributes = textView.selectedTextAttributes
            selectionAttributes[.backgroundColor] = NSColor.lightGray
            selectionAttributes[.foregroundColor] = NSColor.black
            textView.selectedTextAttributes = selectionAttributes
        }
        return editor
    }
}


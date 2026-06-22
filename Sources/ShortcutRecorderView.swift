import AppKit
import SwiftUI

/// Picks the hold-to-talk key. Clicking the field drops a panel of supported
/// keys; the choice only applies after the user presses Confirm — no confusing
/// "press a key to capture" step.
struct ShortcutRecorderView: View {
    @Binding var shortcut: KeyboardShortcut
    @State private var showingPicker = false
    @State private var pending: UInt16 = KeyboardShortcut.rightOption.keyCode

    var body: some View {
        Button {
            pending = shortcut.keyCode
            showingPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .foregroundStyle(.secondary)
                Text(shortcut.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 360)
        .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
            pickerPanel
        }
    }

    private var pickerPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                Text("Hold-to-talk key")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(KeyboardShortcut.presets, id: \.keyCode) { preset in
                        Button {
                            pending = preset.keyCode
                        } label: {
                            HStack {
                                Text(preset.displayName)
                                Spacer()
                                if pending == preset.keyCode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Brand.yellow)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(pending == preset.keyCode ? Brand.yellow.opacity(0.12) : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
            .frame(height: 280)

            Divider()

            HStack {
                Button("Cancel") { showingPicker = false }
                Spacer()
                Button("Confirm") {
                    if let preset = KeyboardShortcut.presets.first(where: { $0.keyCode == pending }) {
                        shortcut = preset
                    }
                    showingPicker = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Brand.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 300)
    }
}

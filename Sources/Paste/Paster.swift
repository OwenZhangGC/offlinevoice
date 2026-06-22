import AppKit
import CoreGraphics

/// Pastes text at the current cursor location in whatever app is focused, by
/// putting it on the pasteboard and synthesizing ⌘V. Requires Accessibility
/// permission. The previous clipboard contents are restored shortly after.
enum Paster {
    private static let vKeyCode: CGKeyCode = 9 // 'v'

    static func insert(_ text: String, autoPaste: Bool, restoreClipboard: Bool) {
        guard !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let writtenChangeCount = pasteboard.changeCount

        if autoPaste {
            sendCommandV()
        }

        guard autoPaste, restoreClipboard, let previous else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Only restore if nothing wrote the pasteboard since (a fresh user
            // copy, or a newer dictation) — otherwise we'd clobber their data.
            guard pasteboard.changeCount == writtenChangeCount else { return }
            pasteboard.clearContents()
            pasteboard.setString(previous, forType: .string)
        }
    }

    static func paste(_ text: String) {
        insert(text, autoPaste: true, restoreClipboard: true)
    }

    private static func sendCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            Log.write("Paster: failed to synthesize ⌘V events; text left on clipboard")
            return
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

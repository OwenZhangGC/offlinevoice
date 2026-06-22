import AppKit

/// Push-to-talk via a held modifier key. Default: Right Option (keyCode 61).
/// Requires Accessibility permission so the global monitor receives events
/// while other apps are focused.
final class HotkeyMonitor {
    var onPress: () -> Void = {}
    var onRelease: () -> Void = {}

    var shortcut: KeyboardShortcut = .rightOption

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isDown = false

    func start() {
        // Idempotent: drop any existing monitors so resume-after-suspend can't
        // register duplicates that would fire push-to-talk twice.
        stop()
        let mask: NSEvent.EventTypeMask = [.flagsChanged, .keyDown, .keyUp]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        // Diagnostic: log every modifier event so we can see whether the global
        // monitor fires (= accessibility OK) and what keycode the user's key sends.
        Log.write("\(event.type) keyCode=\(event.keyCode) flags=\(event.modifierFlags.rawValue) target=\(shortcut.displayName)")

        if shortcut.isModifierOnly {
            handleModifierOnly(event)
        } else {
            handleCombination(event)
        }
    }

    private func handleModifierOnly(_ event: NSEvent) {
        guard event.type == .flagsChanged,
              event.keyCode == shortcut.keyCode,
              let flag = shortcut.modifierOnlyFlag else { return }
        setDown(event.modifierFlags.contains(flag))
    }

    private func handleCombination(_ event: NSEvent) {
        guard event.keyCode == shortcut.keyCode else { return }
        let requiredFlags = shortcut.modifierFlags.intersection([.command, .shift, .option, .control, .function])
        let currentFlags = event.modifierFlags.intersection([.command, .shift, .option, .control, .function])

        switch event.type {
        case .keyDown where currentFlags.isSuperset(of: requiredFlags):
            setDown(true)
        case .keyUp:
            setDown(false)
        default:
            break
        }
    }

    private func setDown(_ down: Bool) {
        if down, !isDown {
            isDown = true
            Log.write("PTT press")
            onPress()
        } else if !down, isDown {
            isDown = false
            Log.write("PTT release")
            onRelease()
        }
    }
}

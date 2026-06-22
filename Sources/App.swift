import AppKit

// AppKit owns the global hotkey and menu bar pieces; SwiftUI owns the product UI.
@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}

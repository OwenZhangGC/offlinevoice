import SwiftUI

/// iOS host app entry point. On iOS the Mac app's global-hotkey + synthetic-paste
/// flow is impossible (sandbox), so this is a self-contained dictation surface:
/// hold to talk, transcribe on-device, copy or share the result. It also doubles
/// as the App Store-shippable container required before any keyboard extension.
@main
struct OfflineVoiceApp: App {
    var body: some Scene {
        WindowGroup {
            DictationView()
                .preferredColorScheme(.dark)
        }
    }
}

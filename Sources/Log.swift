import Foundation

/// Lightweight file logger for debugging. Writes to /tmp/offlinevoice.log so we
/// can trace the dictation pipeline without a debugger attached.
enum Log {
    private static let url = URL(fileURLWithPath: "/tmp/offlinevoice.log")
    private static let queue = DispatchQueue(label: "offlinevoice.log")

    static func write(_ message: String) {
        NSLog("[OfflineVoice] \(message)")
        queue.async {
            let line = "\(Self.stamp()) \(message)\n"
            guard let data = line.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                try? data.write(to: url)
            }
        }
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}

import AVFoundation
import Foundation
import Speech

/// On-device transcription via Apple's own Speech framework (SFSpeechRecognizer).
///
/// Fully native: no model download, no background service, no Python. This is
/// the "Apple native" path — the lightest and most private engine, at the cost
/// of weaker punctuation than the heavier engines. On-device recognition keeps
/// audio on this Mac.
actor AppleSpeechEngine: ASREngine {
    private let locale: Locale
    private var recognizer: SFSpeechRecognizer?

    /// Max time to wait for a final result before giving up. Apple's recognizer
    /// occasionally never delivers `isFinal`; without this the Pipeline would be
    /// stuck in `.processing` forever and swallow every later hotkey press.
    private let recognitionTimeout: Duration = .seconds(15)

    /// Defaults to the system locale so English (and every other) Mac gets
    /// sensible recognition out of the box — no hardcoded Chinese.
    init(locale: Locale = .current) {
        self.locale = locale
    }

    func prepare() async throws {
        try await Self.requestAuthorization()
        guard let rec = SFSpeechRecognizer(locale: locale) else {
            throw err("No speech recognizer for locale \(locale.identifier).")
        }
        guard rec.isAvailable else {
            throw err("Apple speech recognizer is not available right now.")
        }
        // Offline-first: refuse to fall back to Apple's servers. If the on-device
        // model for this locale isn't installed, surface it instead of leaking audio.
        guard rec.supportsOnDeviceRecognition else {
            throw err("On-device speech for \(locale.identifier) isn't installed. Enable Dictation in System Settings ▸ Keyboard so macOS downloads the local model, then retry.")
        }
        Log.write("AppleSpeech ready locale=\(locale.identifier) onDevice=true")
        recognizer = rec
    }

    func transcribe(_ samples: [Float]) async throws -> String {
        let rec = try await loaded()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        // Force fully-local recognition so nothing leaves the Mac, when the
        // on-device model for this locale is installed.
        request.requiresOnDeviceRecognition = true
        request.addsPunctuation = true

        guard let buffer = Self.makeBuffer(from: samples) else {
            throw err("Could not build the audio buffer for Apple speech.")
        }
        request.append(buffer)
        request.endAudio()

        // Guards the three resume paths (final result, error, timeout) so the
        // continuation is resumed exactly once even though the recognizer
        // callback fires on an arbitrary queue.
        let lock = NSLock()
        var resumed = false
        var task: SFSpeechRecognitionTask?
        let timeout = recognitionTimeout

        return try await withCheckedThrowingContinuation { continuation in
            func finish(_ work: () -> Void) {
                lock.lock(); defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                work()
            }

            // The task is held by the recognizer until the final result; we only
            // care about the final transcription for paste-and-go dictation.
            task = rec.recognitionTask(with: request) { result, error in
                if let error {
                    finish { continuation.resume(throwing: error) }
                    return
                }
                guard let result, result.isFinal else { return }
                finish {
                    continuation.resume(returning: result.bestTranscription.formattedString
                        .trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }

            // Fallback: if Apple's recognizer never delivers a final result,
            // cancel it and surface a timeout so the Pipeline returns to idle.
            Task {
                try? await Task.sleep(for: timeout)
                finish {
                    task?.cancel()
                    continuation.resume(throwing: self.err("Apple speech timed out after \(timeout). Try again."))
                }
            }
        }
    }

    private func loaded() async throws -> SFSpeechRecognizer {
        if let recognizer { return recognizer }
        try await prepare()
        guard let recognizer else { throw err("Apple speech recognizer failed to load.") }
        return recognizer
    }

    // MARK: - Helpers

    private func err(_ message: String) -> NSError {
        NSError(domain: "OfflineVoice.AppleSpeech", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }

    private static func requestAuthorization() async throws {
        if SFSpeechRecognizer.authorizationStatus() == .authorized { return }
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else {
            throw NSError(domain: "OfflineVoice.AppleSpeech", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Speech Recognition permission is needed for Apple-native mode (System Settings ▸ Privacy ▸ Speech Recognition)."])
        }
    }

    /// Wraps 16 kHz mono Float samples into the PCM buffer SFSpeech expects.
    private static func makeBuffer(from samples: [Float]) -> AVAudioPCMBuffer? {
        guard
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false),
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
            let channel = buffer.floatChannelData
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            if let base = src.baseAddress { channel[0].update(from: base, count: samples.count) }
        }
        return buffer
    }
}

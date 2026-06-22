import AVFoundation
import SwiftUI

/// Drives the record → transcribe → show flow for the iOS host app.
///
/// Mirrors the Mac pipeline minus everything the iOS sandbox forbids (no global
/// hotkey, no synthetic paste). Recording uses the shared `AudioRecorder`;
/// transcription uses Apple's on-device `SFSpeechRecognizer` (`AppleSpeechEngine`).
///
/// Engine choice (decided on device): Apple-native only. iOS ships the dictation
/// model, so it's instant, offline, and accurate for Chinese. SpeechAnalyzer and
/// WhisperKit were tried and dropped — on a phone they download large models and
/// the recognition quality was worse in practice.
@MainActor
final class DictationViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case recording
        case transcribing
        case error(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published var transcript: String = ""
    /// Toast-style status line under the result (permissions, empty captures…).
    @Published var notice: String?

    private let recorder = AudioRecorder()
    private let engine: ASREngine = AppleSpeechEngine(locale: Locale(identifier: "zh-CN"))

    var isRecording: Bool { phase == .recording }
    var isBusy: Bool { phase == .recording || phase == .transcribing }

    /// Ask for microphone permission up front so the first hold-to-talk doesn't
    /// race the system prompt. Speech permission is requested lazily by the engine.
    func requestPermissionsIfNeeded() {
        // AVAudioApplication.requestRecordPermission is iOS 17+; this path keeps
        // the iOS 16 deployment floor working.
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func startRecording() {
        guard phase == .idle || isErrorPhase else { return }
        notice = nil
        do {
            try recorder.start()
            phase = .recording
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func stopAndTranscribe() {
        guard phase == .recording else { return }
        let samples = recorder.stop()
        phase = .transcribing

        guard !samples.isEmpty else {
            phase = .idle
            notice = "没采到声音，请检查麦克风权限后重试。"
            return
        }

        let engine = engine
        Task {
            do {
                // Watchdog so a stuck recognizer surfaces an error instead of an
                // endless "识别中". The engine also self-times-out internally.
                let text = try await Self.withTimeout(seconds: 30) {
                    try await engine.transcribe(samples)
                }
                await MainActor.run {
                    if text.isEmpty {
                        self.notice = "没听清，再说一次试试。"
                    } else {
                        self.transcript = self.transcript.isEmpty ? text : self.transcript + " " + text
                    }
                    self.phase = .idle
                }
            } catch {
                await MainActor.run {
                    self.phase = .error(error.localizedDescription)
                }
            }
        }
    }

    func clear() {
        transcript = ""
        notice = nil
        if isErrorPhase { phase = .idle }
    }

    private var isErrorPhase: Bool {
        if case .error = phase { return true }
        return false
    }

    // MARK: - Timeout helper

    private struct TimeoutError: LocalizedError {
        var errorDescription: String? { "识别超时，请再试一次。" }
    }

    private static func withTimeout<T: Sendable>(
        seconds: Double,
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else { throw TimeoutError() }
            return result
        }
    }
}

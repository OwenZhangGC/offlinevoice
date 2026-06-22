import Foundation

/// Pluggable speech-to-text backend. Implementations: WhisperKit (now),
/// SenseVoice/FunASR via a local HTTP service (later).
protocol ASREngine: Sendable {
    /// Load/download the model ahead of time so the first utterance is fast.
    func prepare() async throws

    /// Transcribe 16 kHz mono Float samples to text.
    func transcribe(_ samples: [Float]) async throws -> String
}

extension ASREngine {
    func prepare() async throws {}
}

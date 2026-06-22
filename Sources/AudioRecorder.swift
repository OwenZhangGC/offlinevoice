import AVFoundation

/// Captures microphone audio and resamples it to 16 kHz mono Float — the
/// format Whisper-family models expect.
final class AudioRecorder {
    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!

    private let lock = NSLock()
    private var samples: [Float] = []

    func start() throws {
        lock.withLock { samples.removeAll(keepingCapacity: true) }

        // iOS requires an active, record-capable audio session before the engine's
        // input node has a usable format; macOS has no AVAudioSession.
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: [])
        #endif

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            // Some uncommon mic formats can't be resampled to 16 kHz mono; surface
            // it instead of silently recording nothing.
            Log.write("AudioRecorder: no converter for input format \(inputFormat)")
            throw NSError(
                domain: "OfflineVoice.AudioRecorder",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "This microphone's audio format is not supported."]
            )
        }
        self.converter = converter

        input.installTap(onBus: 0, bufferSize: 4_096, format: inputFormat) { [weak self] buffer, _ in
            self?.append(buffer)
        }
        engine.prepare()
        try engine.start()
    }

    /// Stops capture and returns the resampled mono samples.
    func stop() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        // Release the session on iOS so other apps regain audio; harmless no-op
        // elsewhere. Failure here must not lose the capture, so it's best-effort.
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
        let captured = lock.withLock { samples }
        // Diagnostic: log how loud the capture actually was. When a recording
        // transcribes to "" we need to tell apart "mic captured silence" (peak
        // near 0 — a capture/device bug) from "good audio, Whisper dropped it".
        var peak: Float = 0
        for s in captured { let a = abs(s); if a > peak { peak = a } }
        Log.write("audio level peak=\(String(format: "%.4f", peak)) samples=\(captured.count)")
        return captured
    }

    private func append(_ buffer: AVAudioPCMBuffer) {
        guard let converter else { return }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1_024
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var consumed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        if let error {
            Log.write("resample error: \(error)")
            return
        }
        guard let channel = out.floatChannelData?[0], out.frameLength > 0 else { return }
        let chunk = Array(UnsafeBufferPointer(start: channel, count: Int(out.frameLength)))
        lock.withLock { samples.append(contentsOf: chunk) }
    }
}

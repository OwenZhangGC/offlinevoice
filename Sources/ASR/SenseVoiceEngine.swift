import Foundation

/// Transcription via the local SenseVoice service (sherpa-onnx, see `service/`).
/// Sends raw little-endian float32 mono samples over HTTP. Stronger than
/// Whisper for Chinese and Chinese-English mixed speech.
struct SenseVoiceEngine: ASREngine {
    var host = "http://127.0.0.1:8765"
    var sampleRate = 16_000

    func prepare() async throws {
        guard let url = URL(string: host + "/health") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        _ = try await URLSession.shared.data(for: request)
    }

    func transcribe(_ samples: [Float]) async throws -> String {
        guard var components = URLComponents(string: host + "/transcribe") else {
            throw NSError(domain: "OfflineVoice.SenseVoice", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid SenseVoice host: \(host)"])
        }
        components.queryItems = [URLQueryItem(name: "sr", value: String(sampleRate))]
        guard let url = components.url else {
            throw NSError(domain: "OfflineVoice.SenseVoice", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not build SenseVoice request URL."])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = samples.withUnsafeBytes { Data($0) } // float32 LE on arm64

        let (data, _) = try await URLSession.shared.data(for: request)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (object?["text"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

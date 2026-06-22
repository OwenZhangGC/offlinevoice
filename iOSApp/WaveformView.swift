import SwiftUI

/// A lightweight animated bar waveform shown while recording. Decorative — it
/// signals "listening" without needing live audio levels piped through. Drawn
/// with TimelineView so it animates without a model timer.
struct WaveformView: View {
    private let barCount = 5

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<barCount, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 4, height: barHeight(i, t))
                }
            }
        }
    }

    private func barHeight(_ index: Int, _ t: TimeInterval) -> CGFloat {
        let phase = Double(index) * 0.7
        let wave = sin(t * 6 + phase)
        return 10 + CGFloat((wave + 1) / 2) * 34
    }
}

import SwiftUI

/// The single screen of the iOS host app: a big hold-to-talk mic, the running
/// transcript, and copy/share. Dark cosmic styling to match the brand.
struct DictationView: View {
    @StateObject private var model = DictationViewModel()
    @State private var showShare = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header
                transcriptArea
                Spacer(minLength: 12)
                statusLine
                micButton
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
        }
        .onAppear { model.requestPermissionsIfNeeded() }
        .sheet(isPresented: $showShare) {
            ShareSheet(text: model.transcript)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("OfflineVoice")
                    .font(.title2.bold())
                Text("本地语音输入 · 全程离线")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private var transcriptArea: some View {
        ScrollView {
            Text(model.transcript.isEmpty ? "按住下方麦克风开始说话…" : model.transcript)
                .font(.body)
                .foregroundStyle(model.transcript.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) { resultActions }
    }

    @ViewBuilder
    private var resultActions: some View {
        if !model.transcript.isEmpty {
            HStack(spacing: 14) {
                Button { UIPasteboard.general.string = model.transcript } label: {
                    Image(systemName: "doc.on.doc")
                }
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                Button { model.clear() } label: {
                    Image(systemName: "trash")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(12)
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if let notice = model.notice {
            Text(notice)
                .font(.footnote)
                .foregroundStyle(.orange)
                .padding(.bottom, 8)
        } else if case .error(let message) = model.phase {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        } else if model.phase == .transcribing {
            Label("识别中…", systemImage: "waveform")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    private var micButton: some View {
        ZStack {
            if model.isRecording {
                WaveformView()
                    .frame(height: 56)
                    .transition(.opacity)
            }
            Circle()
                .fill(model.isRecording ? Color.red : Color.accentColor)
                .frame(width: 84, height: 84)
                .overlay(Image(systemName: "mic.fill").font(.system(size: 32)).foregroundStyle(.white))
                .scaleEffect(model.isRecording ? 1.1 : 1.0)
                .shadow(color: (model.isRecording ? Color.red : Color.accentColor).opacity(0.5), radius: 16)
                .animation(.spring(response: 0.3), value: model.isRecording)
        }
        // Hold-to-talk: press starts capture, release transcribes.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !model.isRecording { model.startRecording() } }
                .onEnded { _ in model.stopAndTranscribe() }
        )
        .disabled(model.phase == .transcribing)
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.10, green: 0.06, blue: 0.20)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Wraps UIActivityViewController for the share button.
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

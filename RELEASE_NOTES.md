# OfflineVoice v0.3.1

**The fastest local dictation for Mac.** Private, offline voice input — now near-instant.

OfflineVoice turns your speech into text in any app — hold one key, talk, release, and
the text is pasted at your cursor. Because it runs entirely on your Mac, it's faster
*and* more private than cloud-based tools. No account, no subscription, no cloud upload.

🔗 **Website:** https://www.offlinevoice.ai
⬇️ **Download:** [OfflineVoice-mac.dmg](https://www.offlinevoice.ai/downloads/OfflineVoice-mac.dmg)

---

## What's new in 0.3.1

A reliability fix for dictation when a Bluetooth headset is in the picture:

- **No more phantom text.** When your input device was busy on another device —
  classically AirPods connected to your phone — OfflineVoice used to capture silence
  and paste a hallucinated "Thank you." It now detects a silent capture, skips
  transcription entirely, and tells you on the spot instead of pasting nonsense.
- **The waveform tells the truth.** The listening bars now track your real mic level,
  so they visibly flatten the moment no sound is reaching the mic.
- **Pick your microphone.** Settings has a new input-device picker if you want to pin
  dictation to your built-in mic. System default still follows macOS.

## Two recognition modes

Choose your engine in **Privacy & Local AI**:

- **Speed (default)** — Apple's native on-device recognition. Near-instant, the
  lightest option, with zero extra downloads.
- **Accuracy** — Whisper (large-v3 turbo). More accurate for English and technical or
  specialized content. The model downloads once on first use, then works fully offline.

Either way, everything runs on your Mac.

## Highlights

- **The fastest local dictation** — Speed mode returns text almost instantly.
- **100% local** — transcription runs on-device (Apple on-device, or optional Whisper).
  Your audio and text never leave your Mac.
- **Works in any app** — pastes into the focused text field across your Mac apps.
- **Hold-to-talk** — hold **Right Option** (configurable), speak, release to paste.
- **Signed & notarized** — Developer ID signed and Apple notarized; double-click to
  open with no Gatekeeper warning.

## Requirements

- **Apple Silicon Mac (M1 or newer)** — Intel Macs are not supported.
- **macOS 14 (Sonoma) or later.**
- **~2 GB free disk** — only if you choose **Accuracy** mode. The Whisper model is
  downloaded once on first use (~1.5 GB) and cached for offline use afterward. Speed
  mode needs no download.

## Install

1. Download and open the DMG, drag **OfflineVoice** to Applications, and launch it.
2. Grant **Microphone**, **Speech Recognition**, and **Accessibility** when prompted
   (Accessibility is what lets OfflineVoice paste into other apps).
3. Hold **Right Option**, speak, release.

## Privacy

100% local. Transcription happens on your Mac (Apple on-device, or optional Whisper).
OfflineVoice does not upload your audio, does not sync transcripts, and does not train
on your data. Model files are cached locally after first download and work offline.
See the [privacy policy](https://www.offlinevoice.ai/#privacy-policy).

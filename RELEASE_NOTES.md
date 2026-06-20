# OfflineVoice v0.3.0

**The fastest local dictation for Mac.** Private, offline voice input — now near-instant.

OfflineVoice turns your speech into text in any app — hold one key, talk, release, and
the text is pasted at your cursor. Because it runs entirely on your Mac, it's faster
*and* more private than cloud-based tools. No account, no subscription, no cloud upload.

🔗 **Website:** https://www.offlinevoice.ai
⬇️ **Download:** [OfflineVoice-mac.dmg](https://www.offlinevoice.ai/downloads/OfflineVoice-mac.dmg)

---

## What's new in 0.3.0

**OfflineVoice is now the fastest local dictation for Mac.** The default engine
switched to Apple's native on-device speech recognition, so your words appear almost
the instant you stop talking — no model download, no cloud round-trip, no wait.

We also stripped the pipeline down to its fastest path:

```
Hold key → on-device speech recognition → paste
```

That means the old LLM/Ollama **cleanup** step is gone — there's no rewrite stage
between your voice and the text anymore. The **Dictionary** (hotwords) page and the
**Personalization** (per-app tone) page have been **removed** too. The result is a
simpler, faster, no-rewrite experience that just transcribes what you say and pastes it.

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

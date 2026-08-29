#!/usr/bin/env python3
"""Generate the placeholder SFX for Cottage Sort.

Stdlib only. Writes short, quiet, cozy-toned 16-bit mono WAVs into game/audio/.
Re-run any time to regenerate: `python tools/gen_sfx.py`
"""
import math
import os
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "audio")


def _env(n, i, attack=0.005, tau=0.05):
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * math.exp(-t / tau)


def tone(freq, dur, tau=0.05, gain=0.22, harm2=0.0, sweep_to=None):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = freq if sweep_to is None else freq + (sweep_to - freq) * (i / n)
        s = math.sin(2 * math.pi * f * t)
        if harm2:
            s += harm2 * math.sin(4 * math.pi * f * t)
        out.append(s * _env(n, i, tau=tau) * gain)
    return out


def squareish(freq, dur, tau=0.06, gain=0.18):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        s = 0.0
        for k in (1, 3, 5, 7):
            s += math.sin(2 * math.pi * freq * k * t) / k
        out.append(s * 0.7 * _env(n, i, tau=tau) * gain)
    return out


def seq(parts):
    """Overlay (offset_seconds, samples) parts into one buffer."""
    total = max(int(off * SR) + len(buf) for off, buf in parts)
    mix = [0.0] * total
    for off, buf in parts:
        start = int(off * SR)
        for i, v in enumerate(buf):
            mix[start + i] += v
    peak = max(1e-9, max(abs(v) for v in mix))
    if peak > 0.95:
        mix = [v * (0.95 / peak) for v in mix]
    return mix


def write(name, samples):
    path = os.path.normpath(os.path.join(OUT, name))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
        w.writeframes(frames)
    print("wrote", path, f"({len(samples)/SR*1000:.0f} ms)")


def music(dur=12.0):
    """A very quiet, slow ambient pad loop — soft sine chords with a gentle drift."""
    n = int(SR * dur)
    # C major-ish: C3 E3 G3 C4 A3, rolled in and out so the loop seam is soft
    voices = [130.81, 164.81, 196.00, 261.63, 220.00]
    out = [0.0] * n
    for vi, f in enumerate(voices):
        detune = 1.0 + (vi - 2) * 0.0006
        phase = vi * 1.7
        for i in range(n):
            t = i / SR
            # slow amplitude drift per voice + a global fade at the loop seam
            drift = 0.55 + 0.45 * math.sin(2 * math.pi * (0.03 + vi * 0.008) * t + phase)
            seam = min(1.0, t / 1.5, (dur - t) / 1.5)
            s = math.sin(2 * math.pi * f * detune * t)
            s += 0.3 * math.sin(4 * math.pi * f * detune * t)
            out[i] += s * drift * seam * 0.05
    peak = max(1e-9, max(abs(v) for v in out))
    if peak > 0.6:
        out = [v * (0.6 / peak) for v in out]
    return out


def main():
    os.makedirs(OUT, exist_ok=True)

    write("music.wav", music())
    write("tap.wav", tone(520, 0.05, tau=0.025, gain=0.20, sweep_to=380))
    write("place.wav", seq([
        (0.0, tone(300, 0.09, tau=0.045, gain=0.18)),
        (0.0, tone(150, 0.09, tau=0.05, gain=0.10)),
    ]))
    write("pour.wav", seq([
        (0.00, tone(500, 0.05, tau=0.03, gain=0.16)),
        (0.05, tone(430, 0.05, tau=0.03, gain=0.16)),
        (0.10, tone(370, 0.06, tau=0.035, gain=0.16)),
    ]))
    write("buzz.wav", squareish(150, 0.13, tau=0.06, gain=0.16))
    write("win.wav", seq([
        (0.00, tone(523.25, 0.55, tau=0.18, gain=0.16, harm2=0.25)),
        (0.08, tone(659.25, 0.55, tau=0.18, gain=0.16, harm2=0.25)),
        (0.16, tone(783.99, 0.55, tau=0.18, gain=0.16, harm2=0.25)),
        (0.24, tone(1046.5, 0.60, tau=0.20, gain=0.16, harm2=0.25)),
    ]))


if __name__ == "__main__":
    main()

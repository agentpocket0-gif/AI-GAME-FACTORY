#!/usr/bin/env python3
"""Generate small original PCM sound effects for Prism Grove."""
from __future__ import annotations
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
RATE = 22050


def write_tone(name: str, notes: list[tuple[float, float, float]], duration: float,
               noise: float = 0.0) -> None:
    samples = int(RATE * duration)
    rng = random.Random(name)
    pcm = bytearray()
    for i in range(samples):
        t = i / RATE
        amp = 0.0
        for start, freq, gain in notes:
            local = t - start
            if local < 0:
                continue
            envelope = math.exp(-local * (7.5 + freq / 1800.0))
            amp += math.sin(2.0 * math.pi * freq * local) * gain * envelope
        if noise:
            amp += (rng.random() * 2.0 - 1.0) * noise * math.exp(-t * 22.0)
        amp = max(-0.92, min(0.92, amp * 0.48))
        pcm.extend(struct.pack("<h", int(amp * 32767)))
    with wave.open(str(OUT / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write_tone("place.wav", [(0.0, 520.0, 0.55), (0.025, 780.0, 0.30)], 0.18, 0.015)
    write_tone("clear.wav", [(0.0, 660.0, 0.36), (0.07, 880.0, 0.34), (0.14, 1100.0, 0.30)], 0.46, 0.008)
    write_tone("invalid.wav", [(0.0, 180.0, 0.38), (0.045, 145.0, 0.25)], 0.18, 0.01)
    print("Generated original place, clear and invalid sound effects.")


if __name__ == "__main__":
    main()

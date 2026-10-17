"""Render the game's original, loopable chiptune scores using only Python 3.

Run from any directory: python3 tools/compose_music.py
No recordings, external samples or third-party compositions are used.
"""

from array import array
from math import exp, pi, sin, sqrt
from pathlib import Path
import random
import sys
import wave

RATE = 22050
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
TAU = 2 * pi


class Score:
    def __init__(self, bpm, bars=16):
        self.beat = 60 / bpm
        self.samples = array("f", [0.0]) * round(bars * 4 * self.beat * RATE)
        self.rng = random.Random(817)

    def note(self, beat, length, midi, gain, voice="bell", echo=False):
        start = round(beat * self.beat * RATE)
        duration = length * self.beat
        count = round(duration * RATE)
        frequency = 440 * 2 ** ((midi - 69) / 12)
        for i in range(count):
            t = i / RATE
            phase = TAU * frequency * t
            attack = min(1.0, t / 0.012)
            release = min(1.0, (duration - t) / 0.06)
            if voice == "pad":
                envelope = min(1.0, t / 0.16) * min(1.0, (duration - t) / 0.22)
                tone = sin(phase) + 0.18 * sin(phase * 2) + 0.08 * sin(phase * 3)
            elif voice == "bass":
                envelope = attack * release * exp(-t * 2.6)
                tone = sin(phase) + 0.20 * sin(phase * 3)
            elif voice == "pulse":
                envelope = attack * release * exp(-t * 3.2)
                tone = sin(phase) + sin(phase * 3) / 3 + sin(phase * 5) / 5
            else:
                envelope = attack * release * exp(-t * 4.0)
                tone = sin(phase) + 0.28 * sin(phase * 2) + 0.12 * sin(phase * 4)
            value = tone * envelope * gain
            self.samples[(start + i) % len(self.samples)] += value
            if echo:
                for delay, amount in [(0.75, 0.23), (1.5, 0.09)]:
                    self.samples[(start + i + round(delay * self.beat * RATE)) % len(self.samples)] += value * amount

    def drum(self, beat, kind, gain):
        duration = {"kick": 0.24, "snare": 0.15, "hat": 0.045}[kind]
        start = round(beat * self.beat * RATE)
        last_noise = 0.0
        for i in range(round(duration * RATE)):
            t = i / RATE
            noise = self.rng.uniform(-1, 1)
            if kind == "kick":
                # Integral of an exponentially falling pitch, with a soft attack.
                phase = TAU * (46 * t + 90 * (1 - exp(-t * 28)) / 28)
                tone = sin(phase) * exp(-t * 19)
            elif kind == "snare":
                tone = (noise * 0.65 + sin(TAU * 180 * t) * 0.3) * exp(-t * 30)
            else:
                tone = (noise - last_noise) * 0.45 * exp(-t * 95)
            last_noise = noise
            envelope = min(1, t / 0.002) * min(1, (duration - t) / 0.008)
            self.samples[(start + i) % len(self.samples)] += tone * envelope * gain

    def save(self, name):
        # Circular echo preserves tails across the end/start of each loop.
        peak = max(abs(value) for value in self.samples)
        scale = 0.78 / peak
        pcm = array("h", (round(value * scale * 32767) for value in self.samples))
        if sys.byteorder != "little":
            pcm.byteswap()
        OUTPUT.mkdir(parents=True, exist_ok=True)
        with wave.open(str(OUTPUT / name), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(pcm.tobytes())
        rms = sqrt(sum(value * value for value in self.samples) / len(self.samples)) * scale
        print(f"{name}: {len(pcm) / RATE:.2f}s, peak=0.78, RMS={rms:.3f}, seam={abs(pcm[-1] - pcm[0])}")


# D minor, Bb, F, C; the second phrase returns through G minor and A.
CHORDS = [(50, 53, 57), (46, 50, 53), (48, 53, 57), (48, 52, 55),
          (50, 53, 57), (46, 50, 53), (43, 50, 58), (45, 52, 61)]
MENU_MELODY = [
    [(0, 74, 1), (1.5, 77, 0.5), (2.5, 76, 1)],
    [(0.5, 74, 1), (2, 69, 1.5)],
    [(0, 72, 1), (1.5, 69, 0.5), (2.5, 65, 1)],
    [(0.5, 67, 1), (2, 72, 1.5)],
    [(0, 69, 0.5), (1, 74, 1), (2.5, 77, 1)],
    [(0.5, 76, 0.5), (1.5, 74, 1.5)],
    [(0, 70, 1), (1.5, 69, 0.5), (2.5, 67, 1)],
    [(0, 69, 1.5), (2, 73, 1.5)],
]
GAME_MELODY = [
    [74, None, 74, 77, 76, 74, 69, None],
    [70, None, 74, 77, 74, None, 70, 69],
    [72, 72, None, 69, 72, 77, 76, None],
    [76, None, 79, 76, 72, None, 67, 72],
    [74, 77, 81, None, 79, 77, 76, 74],
    [77, None, 74, 70, 74, 77, 76, None],
    [79, None, 77, 74, 70, None, 69, 67],
    [69, 73, 76, None, 73, 76, 81, 73],
]


def menu():
    score = Score(92)
    for bar in range(16):
        chord = CHORDS[bar % 8]
        base = bar * 4
        for pitch in chord:
            score.note(base, 3.8, pitch + 12, 0.037, "pad")
        for step, index in enumerate([0, 1, 2, 1, 0, 2, 1, 2]):
            score.note(base + step * 0.5, 0.40, chord[index] + 24, 0.033, echo=True)
        for beat in [0, 2]:
            score.note(base + beat, 1.7, chord[0] - 12, 0.13, "bass")
        for beat, pitch, length in MENU_MELODY[bar % 8]:
            score.note(base + beat, length, pitch + (12 if bar >= 12 else 0), 0.095, echo=True)
        for beat in [1, 3]:
            score.drum(base + beat, "hat", 0.025)
    score.save("menu_theme.wav")


def game():
    score = Score(132)
    for bar in range(16):
        chord = CHORDS[bar % 8]
        base = bar * 4
        for step in range(8):
            pitch = chord[0] - 12 if step % 4 != 3 else chord[0]
            score.note(base + step * 0.5, 0.38, pitch, 0.13, "bass")
            score.note(base + step * 0.5 + 0.25, 0.20, chord[[0, 2, 1, 2][step % 4]] + 24, 0.029, "pulse", echo=True)
            score.drum(base + step * 0.5, "hat", 0.045 if step % 2 else 0.025)
        for beat in [0, 2, 2.75]:
            score.drum(base + beat, "kick", 0.19)
        for beat in [1, 3]:
            score.drum(base + beat, "snare", 0.085)
        for step, pitch in enumerate(GAME_MELODY[bar % 8]):
            if pitch is not None:
                score.note(base + step * 0.5, 0.40, pitch, 0.080, "pulse", echo=True)
        if bar >= 8:
            for pitch in chord:
                score.note(base, 3.7, pitch + 12, 0.022, "pad")
    score.save("game_theme.wav")


if __name__ == "__main__":
    menu()
    game()

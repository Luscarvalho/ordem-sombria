"""Original short combat effects, rendered without external samples (Python 3)."""
from array import array
from math import exp, pi, sin, sqrt
from pathlib import Path
import random
import sys
import wave

RATE = 22050
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def render(name, duration):
    rng = random.Random(130 + len(name))
    samples = []
    filtered_noise = 0.0
    phase = 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        filtered_noise += 0.24 * (noise - filtered_noise)
        if name == "revolver":
            body = sin(2 * pi * (85 * t + 90 * (1 - exp(-45 * t)) / 45))
            value = body * exp(-34 * t) * 0.58 + noise * exp(-110 * t) * 0.48
        elif name == "shotgun":
            body = sin(2 * pi * (48 * t + 100 * (1 - exp(-28 * t)) / 28))
            value = body * exp(-17 * t) * 0.64 + filtered_noise * exp(-22 * t) * 0.90 + noise * exp(-140 * t) * 0.28
        elif name == "wand":
            phase += 2 * pi * (730 * exp(-7 * t) + 180) / RATE
            value = (sin(phase) + 0.24 * sin(phase * 2)) * exp(-16 * t) * 0.62
            value += filtered_noise * exp(-35 * t) * 0.15
        elif name in ("reload_start", "reload_end"):
            value = 0.0
            for start in (0.0, 0.055 if name == "reload_start" else 0.08):
                age = t - start
                if age >= 0:
                    frequency = 360 if name == "reload_start" else 760
                    value += (filtered_noise * 0.70 + sin(2 * pi * frequency * age) * 0.25) * exp(-75 * age)
        elif name == "enemy_hit":
            body = sin(2 * pi * (150 * t + 100 * (1 - exp(-65 * t)) / 65))
            value = body * exp(-65 * t) * 0.48 + filtered_noise * exp(-60 * t) * 0.65
        elif name == "player_hurt":
            # A descending, rounded chip buzz: clearly different from enemy hits.
            phase += 2 * pi * (100 + 200 * exp(-9 * t)) / RATE
            value = (sin(phase) + 0.22 * sin(phase * 3)) * exp(-10 * t) * 0.58
            value += filtered_noise * exp(-24 * t) * 0.35
        elif name == "level_up":
            value = 0.0
            for start, frequency in [(0.0, 587.33), (0.065, 698.46), (0.13, 880.0), (0.195, 1174.66)]:
                age = t - start
                if age >= 0:
                    value += (sin(2 * pi * frequency * age) + 0.12 * sin(4 * pi * frequency * age)) * exp(-14 * age) * min(1, age / 0.004) * 0.30
        else:  # Shield block: a short crystal chime.
            value = (sin(2 * pi * 880 * t) + 0.40 * sin(2 * pi * 1320 * t)) * exp(-22 * t) * 0.45
        envelope = min(1, t / 0.0015) * min(1, (duration - t) / 0.018)
        samples.append(value * envelope)
    peak = max(abs(x) for x in samples)
    scale = 0.76 / max(peak, 0.01)
    pcm = array("h", (round(x * scale * 32767) for x in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())
    rms = sqrt(sum(x*x for x in samples) / len(samples)) * scale
    print(f"{name}: {duration:.2f}s, peak=0.76, RMS={rms:.3f}")


if __name__ == "__main__":
    for name, duration in [("revolver", 0.16), ("shotgun", 0.30), ("wand", 0.24),
                           ("enemy_hit", 0.085), ("player_hurt", 0.32), ("shield_block", 0.20), ("level_up", 0.55), ("reload_start", 0.16), ("reload_end", 0.20)]:
        render(name, duration)

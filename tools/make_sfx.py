"""Sinh hiệu ứng âm thanh (SFX) 8-bit cho vòng chơi -> assets/sfx/*.wav.

Tự tổng hợp bằng sóng vuông/tam giác nên không vướng bản quyền.
Chạy: python tools/make_sfx.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")


def tone(freq, ms, wave_kind="square", vol=0.35, slide_to=None):
    n = int(RATE * ms / 1000)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        f = freq if slide_to is None else freq + (slide_to - freq) * t
        phase += f / RATE
        p = phase % 1.0
        if wave_kind == "square":
            s = 1.0 if p < 0.5 else -1.0
        elif wave_kind == "triangle":
            s = 4 * abs(p - 0.5) - 1
        else:  # noise
            s = random.uniform(-1, 1)
        env = min(1.0, i / (RATE * 0.004)) * (1 - t) ** 1.5  # attack ngắn, tắt dần
        out.append(s * vol * env)
    return out


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


random.seed(7)
write("correct.wav", tone(988, 70) + tone(1319, 160))  # B5 -> E6 (kiểu ăn xu)
write("wrong.wav", tone(220, 120, "square", 0.3, slide_to=150) + tone(140, 200, "square", 0.3, slide_to=90))
write("jump.wav", tone(400, 140, "square", 0.25, slide_to=900))
write("hit.wav", tone(0, 90, "noise", 0.45) + tone(160, 120, "triangle", 0.5, slide_to=60))
write("life.wav", tone(659, 80) + tone(784, 80) + tone(1047, 180))
write("powerup.wav", tone(523, 60, "triangle", 0.4) + tone(784, 60, "triangle", 0.4) + tone(1047, 120, "triangle", 0.4))
write("win.wav", tone(523, 120) + tone(659, 120) + tone(784, 120) + tone(1047, 360))
write("lose.wav", tone(392, 180) + tone(330, 180) + tone(262, 420, slide_to=200))
print("OK ->", os.path.abspath(OUT))

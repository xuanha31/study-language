#!/usr/bin/env python3
"""Sinh icon app (tự thiết kế, không vướng bản quyền): nền đỏ bo góc + chữ 学 trắng.
Xuất 2 file cho flutter_launcher_icons:
  assets/icon/app_icon.png     -> icon đầy đủ (legacy + iOS)
  assets/icon/app_icon_fg.png  -> foreground trong suốt (adaptive icon Android)
"""
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
RED_TOP = (239, 83, 80)    # EF5350
RED_BOT = (198, 40, 40)    # C62828
WHITE = (255, 255, 255)
FONT = "/System/Library/Fonts/STHeiti Medium.ttc"
CHAR = "学"  # học


def gradient(top, bot):
    img = Image.new("RGB", (SIZE, SIZE), top)
    d = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        d.line([(0, y), (SIZE, y)],
               fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    return img


def draw_char(img, font_px, dy=0, color=WHITE, shadow=True):
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, font_px)
    cx, cy = SIZE // 2, SIZE // 2 + dy
    if shadow:
        d.text((cx + 8, cy + 12), CHAR, font=font, fill=(0, 0, 0, 70), anchor="mm")
    d.text((cx, cy), CHAR, font=font, fill=color, anchor="mm")


def legacy():
    base = gradient(RED_TOP, RED_BOT).convert("RGBA")
    # viền sáng mảnh cho chiều sâu
    d = ImageDraw.Draw(base)
    d.rounded_rectangle([60, 60, SIZE - 60, SIZE - 60], radius=150,
                        outline=(255, 255, 255, 60), width=10)
    draw_char(base, 640)
    # bo góc bằng mask
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=190, fill=255)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    out.save("assets/icon/app_icon.png")


def foreground():
    # nền trong suốt; chữ nằm trong vùng an toàn (~62%) của adaptive icon
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_char(img, 470, shadow=False)
    img.save("assets/icon/app_icon_fg.png")


legacy()
foreground()
print("Đã tạo assets/icon/app_icon.png + app_icon_fg.png")

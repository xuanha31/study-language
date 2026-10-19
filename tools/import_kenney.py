"""Chép sprite cần dùng từ Kenney "New Platformer Pack" (CC0) vào assets/images/kenney.

Tải gói: https://kenney.nl/assets/new-platformer-pack -> giải nén -> chạy
    python tools/import_kenney.py <thư mục đã giải nén>
Dùng bản "Double" (2x) cho nét trên màn hình mật độ cao. Nấm được cắt sát viền
(ảnh gốc có nhiều khoảng trống). Nhân vật/quái giữ nguyên khung để các frame khớp nhau.
"""
import os
import shutil
import sys

from PIL import Image

SRC = os.path.join(sys.argv[1], "Sprites")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "kenney")

CHARACTERS = ["beige", "green", "pink", "purple", "yellow"]
CHAR_FRAMES = ["idle", "walk_a", "walk_b", "jump", "hit"]
ENEMIES = {
    "slime_normal": ["walk_a", "walk_b", "flat"],
    "slime_fire": ["walk_a", "walk_b", "flat"],
    "slime_spike": ["walk_a", "walk_b", "flat"],
    "snail": ["walk_a", "walk_b", "shell"],
    "mouse": ["walk_a", "walk_b", "rest"],
    "ladybug": ["walk_a", "walk_b", "rest"],
    "slime_block": ["walk_a", "walk_b", "jump", "rest"],  # boss
}
SCENES = ["hills", "trees", "mushrooms", "desert"]
TERRAINS = ["grass", "dirt", "sand", "purple"]


def copy(rel_src, rel_dst, crop=False):
    src = os.path.join(SRC, rel_src)
    dst = os.path.join(OUT, rel_dst)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if crop:
        im = Image.open(src).convert("RGBA")
        im.crop(im.getbbox()).save(dst, optimize=True)
    else:
        shutil.copyfile(src, dst)


for c in CHARACTERS:
    for f in CHAR_FRAMES:
        copy(f"Characters/Double/character_{c}_{f}.png", f"characters/{c}_{f}.png")
        if f == "idle":  # ảnh xem trước trong cửa hàng (cắt sát)
            copy(f"Characters/Double/character_{c}_{f}.png", f"characters/{c}_preview.png", crop=True)
for e, frames in ENEMIES.items():
    for f in frames:
        copy(f"Enemies/Double/{e}_{f}.png", f"enemies/{e}_{f}.png")
for s in SCENES:
    copy(f"Backgrounds/Double/background_color_{s}.png", f"backgrounds/{s}.png")
for t in TERRAINS:
    for part in ["top", "center"]:
        copy(f"Tiles/Double/terrain_{t}_block_{part}.png", f"tiles/terrain_{t}_{part}.png")
copy("Tiles/Double/mushroom_red.png", "tiles/mushroom_red.png", crop=True)
shutil.copyfile(os.path.join(sys.argv[1], "License.txt"), os.path.join(OUT, "License.txt"))
print("OK ->", os.path.abspath(OUT), sum(len(f) for _, _, f in os.walk(OUT)), "files")

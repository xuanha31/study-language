# Nguồn tài nguyên (hình ảnh / âm thanh / font)

> **Mình KHÔNG tải/nhúng ảnh trực tiếp vào repo** vì không tự xác minh được bản quyền từng file.
> Dưới đây là các **nguồn miễn phí, ưu tiên CC0** (dùng được cả thương mại) kèm danh sách asset cần.
> **Bước E8-3: kiểm tra license từng file trước khi dùng.**

## ⚠️ Cảnh báo bản quyền QUAN TRỌNG

- Game lấy **cảm hứng** từ Mario là OK, nhưng **TUYỆT ĐỐI KHÔNG dùng sprite/nhân vật/nhạc Mario thật** (Mario, nấm 🍄 đặc trưng, ống xanh... là **tài sản trí tuệ của Nintendo**). Dùng sẽ vi phạm bản quyền.
- → Dùng **nhân vật & vật phẩm gốc hoặc CC0** (nấm chung chung, nhân vật tự thiết kế). "Ăn nấm" giữ làm *cơ chế*, nhưng tạo hình phải khác Mario.

## Asset cần cho game (gameplay hướng A)

| Loại | Mô tả | Ưu tiên |
|------|-------|---------|
| Nhân vật | sprite idle / chạy / nhảy (animation) | Cao |
| Vật phẩm | nấm (+điểm), tim/mạng, nấm vàng (combo), power-up | Cao |
| Tileset | mặt đất, bục, nền platformer side-scroll | Cao |
| Background | nền cuộn (parallax) | Trung |
| HUD | icon mạng, nấm, đồng hồ, nút | Trung |
| Hiệu ứng | đúng/sai, ăn nấm, lên level | Trung |
| Âm thanh | nhảy, ăn nấm, đúng/sai, nhạc nền | Trung |

## Nguồn hình ảnh (ưu tiên CC0)

### 1. Kenney — CC0 hoàn toàn, chất lượng cao, đồng bộ (khuyên dùng nhất)
Tất cả CC0, dùng cả thương mại. Hợp game platformer 2D.
- [New Platformer Pack](https://kenney.nl/assets/new-platformer-pack) — 440+ asset: tile, nhân vật, quái, HUD, nền, âm thanh.
- [Platformer Pack Redux](https://kenney.nl/assets/platformer-pack-redux) — 360 asset.
- [Platformer Art Deluxe](https://kenney.nl/assets/platformer-art-deluxe) — 930 asset.
- [Pixel Platformer](https://kenney.nl/assets/pixel-platformer) — phong cách pixel.
- [Simplified Platformer Pack](https://kenney.nl/assets/simplified-platformer-pack) — 90 asset, tối giản.
- [Kenney Game Assets All-in-1 (itch.io)](https://kenney.itch.io/kenney-game-assets) — gói tổng hợp.

### 2. OpenGameArt.org — kho cộng đồng (LỌC theo CC0)
Có cả nhân vật, tileset, nấm. Lưu ý: nhiều license khác nhau — **lọc CC0** và kiểm từng file.
- [CC0 resources](https://opengameart.org/content/cc0-resources)
- [Good CC0-Art](https://opengameart.org/content/good-cc0-art)
- [CC0 Tiles & Tilesets](https://opengameart.org/content/cc0-tiles-tilesets)
- Tìm thêm: "Platformer Art: Mushroom Land", "Forest Boy - Platformer Animated Character".

### 3. itch.io — chợ asset (lọc CC0 / free)
- [Platformer assets — CC0](https://itch.io/game-assets/assets-cc0/genre-platformer)
- [Platformer assets — free](https://itch.io/game-assets/free/genre-platformer)
- [Tileset platformer — free](https://itch.io/game-assets/free/genre-platformer/tag-tileset)
- Gói nổi bật (kiểm license): "Sunny Land", "Pixel Adventure", "Pixel Prototype Player Sprites".

## Font chữ Hán (CJK) — cho hiển thị chữ Hán đẹp & đồng nhất

- **Noto Sans SC / Noto Serif SC** (Google Fonts) — miễn phí (SIL Open Font License), phủ đầy chữ giản thể.
  - Trang: https://fonts.google.com/noto/specimen/Noto+Sans+SC
- Trong Flutter: nhúng file `.otf/.ttf` vào `assets/fonts/` + khai báo `pubspec.yaml`, hoặc dùng package `google_fonts`.

## Âm thanh

- Hiệu ứng/nhạc CC0: trong các gói Kenney ở trên đã có sound; thêm [Kenney Audio](https://kenney.nl/assets?q=audio).
- Phát âm tiếng Trung: dùng **TTS động** (`flutter_tts`) — xem [design.md](design.md) mục 9. Không cần tải file đọc.

## Quy ước lưu trong repo (đề xuất)

```
assets/
  images/
    characters/   sprites nhân vật
    items/        nấm, tim, power-up
    tiles/        tileset
    bg/           background
    hud/          icon HUD
  audio/sfx/      hiệu ứng
  fonts/          Noto Sans SC
  LICENSES.md     ghi rõ nguồn + license từng asset đã dùng
```

> Tạo `assets/LICENSES.md` ghi công từng asset (kể cả CC0 nên ghi nguồn) — gọn gàng & an toàn pháp lý.

---

**Sources:**
- [Kenney's Assets (CC0) — Godot Forum](https://forum.godotengine.org/t/kenneys-assets-free-and-creative-commons-cc0/36658)
- [Kenney — New Platformer Pack](https://kenney.nl/assets/new-platformer-pack)
- [Kenney — Platformer Pack Redux](https://kenney.nl/assets/platformer-pack-redux)
- [OpenGameArt — CC0 resources](https://opengameart.org/content/cc0-resources)
- [OpenGameArt — CC0 Tiles & Tilesets](https://opengameart.org/content/cc0-tiles-tilesets)
- [itch.io — CC0 platformer assets](https://itch.io/game-assets/assets-cc0/genre-platformer)
- [12 Best Sources for 2D Game Assets Free](https://makegameswithai.com/blog/2-d-game-assets-free/)

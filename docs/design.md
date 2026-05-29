# Đặc tả thiết kế — Game học tiếng Trung

> Tài liệu này gom toàn bộ quyết định thiết kế đã thống nhất. Là "kim chỉ nam" khi code.
> Cập nhật tài liệu này khi có thay đổi thiết kế.

## 1. Tổng quan

- **Nền tảng:** Mobile, **Flutter/Dart** (Android + iOS).
- **Mục tiêu:** Học ngoại ngữ bằng game kiểu Mario. Bắt đầu với **tiếng Trung**, kiến trúc đa ngôn ngữ để mở rộng (Nhật/Anh...).
- **Triết lý:** *Học là chính, game là động lực.* Khi cân nhắc đánh đổi, ưu tiên hiệu quả học.

## 2. Vòng lặp gameplay

- Mỗi **vòng** = **20 câu hỏi**, 4 đáp án.
- Trả lời **đúng** → nhân vật nhảy ăn nấm, **+1 nấm** (điểm/tiền tệ trong game).
- Trả lời **sai** → **-1 mạng**.
- Mặc định **3 mạng/vòng**. Mạng thưởng (từ câu đúng đặc biệt) **cộng dồn qua các vòng**. Hết mạng → thua vòng.
- **Combo/streak:** đúng liên tiếp → nhân điểm (vd nấm vàng x2). Sai → reset combo.
- **Boss câu 20:** câu cuối khó hơn / tính giờ gắt để "qua màn".
- **Power-up** (tiêu bằng nấm): gợi ý (xóa 1 đáp án sai), đóng băng thời gian, hồi 1 mạng.

### Cơ chế platformer — HƯỚNG A (đã chốt)

"**Dừng để hỏi**": nhân vật chạy trên màn (side-scroll) tới một điểm → màn dừng, hiện câu hỏi → chọn đúng thì nhảy ăn nấm rồi chạy tiếp tới câu sau. Platformer là "lớp áo" chuyển cảnh giữa các câu hỏi.

- KHÔNG làm hướng B (trả lời ngay trong lúc chạy/né vật) — rủi ro "game lấn học" và chi phí lớn.
- **Engine:** dùng **Flame** nếu animation chạy/nhảy/scroll phức tạp; nếu chỉ hiệu ứng nhảy đơn giản thì widget + `AnimationController`.
- **Sinh màn:** dùng **template/sinh tự động** theo số câu (20), KHÔNG vẽ tay từng bài (không kham nổi cho HSK 1→6).

## 3. Tốc độ & preview

- **Tốc độ chơi điều chỉnh được** (chậm / vừa / nhanh). Bài mới → chậm; ôn lại → nhanh (luyện phản xạ).
- **Preview trước vòng:** xem trước danh sách từ/hội thoại sẽ gặp để tự chọn tốc độ phù hợp.
- **Gợi ý tốc độ mặc định** theo độ thuộc: nhiều từ mới → gợi ý "Chậm"; toàn từ đã thuộc → gợi ý "Nhanh". Người dùng vẫn override được.

## 4. Dạng câu hỏi (đảo chiều để học sâu)

| Dạng | Hiện | Chọn | Độ khó |
|------|------|------|--------|
| Nhận diện | chữ Hán | nghĩa Việt | Dễ |
| Sản xuất | nghĩa Việt | chữ Hán | Khó hơn |
| Nghe | 🔊 audio | chữ Hán đúng | Khó |
| Thanh điệu | 🔊 đọc | chọn đúng thanh (mā/má/mǎ/mà) | Rất khó |
| Hán Việt | chữ Hán | âm Hán Việt | (cho người Việt) |

- **Đáp án sai (distractor):** lấy từ các card **cùng `distractor_group`** để "đáng tin", ép phân biệt thật.
- **Đổi chiều Việt↔Trung** là một trong các dạng trên (option người dùng nêu ban đầu).

## 5. Nội dung học

- Chia khóa **HSK 1 → HSK 6**, mỗi **bài 20 từ/hội thoại**.
- Card có đủ: chữ Hán, **pinyin có thanh điệu**, nghĩa Việt, **âm Hán Việt**, tách `chars` từng chữ. Schema chi tiết: [../content/README.md](../content/README.md).
- **Ôn tập (SRS):** xem mục 6. Có thể (a) trộn từ ôn vào mỗi vòng, hoặc (b) một phần ôn tập riêng để học lại từ đã học.
- **Hội thoại:** có ngữ cảnh (`context`: gọi món, hỏi đường...). Distractor hội thoại tạm random (chấp nhận cho MVP).

## 6. SRS — lặp lại ngắt quãng (Leitner / SM-2 rút gọn)

Mỗi từ (trong tiến độ người dùng) có:
- `level` — bậc trí nhớ (0..n).
- `nextReviewDate` — ngày nên gặp lại.

Sau mỗi lần trả lời:
- **Đúng + nhanh** → lên 1 bậc, giãn khoảng ôn (vd 1→3→7→16→35 ngày).
- **Đúng + chậm** → giữ/lên ít.
- **Sai** → rớt về bậc thấp, ôn lại sớm.

Phần "ôn tập" query các từ có `nextReviewDate <= hôm nay`. Chạy offline.

> ⚠️ **Đo "nhanh/chậm" theo thời gian TƯƠNG ĐỐI** so với tốc độ vòng đang chơi, KHÔNG theo giây tuyệt đối — vì chế độ nhanh ép mọi người chọn nhanh, sẽ làm nhiễu dữ liệu độ thuộc.

## 7. Dữ liệu & cập nhật

- **Content** (dùng chung): JSON trên server, có `version` từng card. Client tải về **offline-first**.
- **Cập nhật:** so `manifest.json` → tải khóa thay đổi. Trong khóa: so theo `id` + `version` (không chỉ `id`) để nhận cả bản *sửa* card cũ; **giữ nguyên tiến độ học** khi card được cập nhật.
- HSK 3→6: xem [data-pipeline.md](data-pipeline.md).

## 8. Đồng bộ (tùy chọn) — Google Drive

- **Tiến độ người dùng** lưu local. Đồng bộ Drive là **tùy chọn**, không bắt buộc (không login vẫn chơi offline).
- Khi login Drive: liệt kê các **bản snapshot** đã sao lưu → restore bản mới nhất / chọn bản / đồng bộ lại / **xóa** dữ liệu đồng bộ.
- Kiểu snapshot độc lập có nhãn thời gian → né được bài toán merge. Giới hạn ~10 bản gần nhất (tự xóa bản cũ).
- Khi restore: cảnh báo rõ "tiến độ hiện tại sẽ bị thay" để tránh mất dữ liệu mới hơn.

## 9. Audio

- **TTS động** (`flutter_tts`) cho cả từ vựng và hội thoại.
- **Lần đầu chạy:** tổng hợp audio ra file (`synthesizeToFile`) và **cache** để các lần sau đọc offline.
  - *[Cần kiểm chứng]* Lần đầu vẫn cần mạng + máy có engine TTS tiếng Trung. Có màn "đang chuẩn bị giọng đọc...".
- Giữ trường `audio` trong model làm **cửa thoát**: nếu TTS tệ, thay bằng mp3 thu sẵn cho từ cốt lõi mà không sửa cấu trúc.

## 10. Hiển thị chữ Hán

- *[Cần kiểm chứng]* Nhúng sẵn **font CJK** (vd Noto Sans SC) vào app để chữ Hán hiển thị đẹp & đồng nhất mọi máy. Xem [assets.md](assets.md).

## 11. Mô hình đa ngôn ngữ

Card dùng khung ngôn ngữ-agnostic: `{ target, reading, meaning_vi, audio, level, lesson, distractor_group, ... }`. Sau này thêm tiếng Nhật/Anh vào cùng cấu trúc (đổi `reading`/bổ sung trường tương ứng).

# Nguồn dữ liệu học (content)

Thư mục này chứa **nội dung học** (từ vựng + hội thoại) dùng chung cho mọi người dùng.
Đây là dữ liệu *tĩnh*, được đặt trên server và game tải về (offline-first).

> ⚠️ **CẢNH BÁO CHẤT LƯỢNG DỮ LIỆU**
> Toàn bộ dữ liệu trong `hsk*.json` hiện được sinh tự động dựa trên kiến thức của AI và
> **CHƯA được kiểm chứng bởi nguồn chính thức**. Pinyin/thanh điệu, nghĩa tiếng Việt và
> **âm Hán Việt** có thể có sai sót (nhiều chữ Hán có nhiều âm Hán Việt).
> **Bắt buộc rà soát bởi người biết tiếng Trung trước khi phát hành.**
> Mỗi card có trường `verified: false` — đặt thành `true` sau khi đã kiểm.

## Tách 2 loại dữ liệu

| Loại | Vị trí | Đặc điểm |
|------|--------|----------|
| **Nội dung học** (file này) | server, dùng chung | tĩnh, có `version` để cập nhật |
| **Tiến độ người dùng** | local + Google Drive (tùy chọn) | riêng từng người, không nằm ở đây |

## Cấu trúc thư mục

```
content/
  manifest.json   → danh mục các khóa + version, để client biết khóa nào cần cập nhật
  hsk1.json       → các card của HSK 1
  hsk2.json ...   → (sẽ bổ sung)
```

## Cơ chế cập nhật (client)

Khi có mạng, client tải `manifest.json`, so version từng khóa với bản đang có:
- Khóa chưa có          → tải toàn bộ file khóa đó.
- Khóa đã có            → tải file, duyệt từng card:
  - `id` chưa có             → thêm mới.
  - `id` đã có, `version` server > local → **cập nhật nội dung card** (GIỮ NGUYÊN tiến độ học của card đó).
  - `id` đã có, version bằng nhau        → bỏ qua.

> Lưu ý: chỉ so theo `id` là chưa đủ — server có thể *sửa* card cũ (sửa pinyin, đổi audio).
> Phải so thêm `version` để nhận được bản sửa.

## Schema một "card"

```jsonc
{
  "id": "hsk1-0001",          // duy nhất toàn hệ thống
  "type": "vocab",            // "vocab" | "dialogue"
  "level": "HSK1",
  "lesson": 1,                // mỗi bài 20 card
  "version": 1,               // tăng khi sửa nội dung card
  "verified": false,          // đã được người kiểm chưa
  "target": "你好",           // chữ Hán
  "reading": "nǐ hǎo",        // pinyin CÓ thanh điệu
  "meaning_vi": "Xin chào",   // nghĩa tiếng Việt
  "hanviet": "nễ hảo",        // âm Hán Việt cả từ
  "chars": [                  // tách từng chữ (cho từ nhiều chữ) — học sâu
    { "char": "你", "reading": "nǐ", "hanviet": "nễ", "meaning_vi": "bạn" },
    { "char": "好", "reading": "hǎo", "hanviet": "hảo", "meaning_vi": "tốt" }
  ],
  "audio": "hsk1/hsk1-0001.mp3", // đường dẫn audio (hoặc cache từ TTS lần đầu)
  "distractor_group": "greeting" // nhóm chọn 3 đáp án sai "đáng tin"
}
```

### Card hội thoại (`type: "dialogue"`)

```jsonc
{
  "id": "hsk1-d-0001",
  "type": "dialogue",
  "level": "HSK1",
  "lesson": 1,
  "version": 1,
  "verified": false,
  "context": "Chào hỏi",      // tình huống, để lọc distractor cùng ngữ cảnh
  "lines": [
    { "speaker": "A", "target": "你好！", "reading": "nǐ hǎo!", "hanviet": "nễ hảo", "meaning_vi": "Xin chào!" },
    { "speaker": "B", "target": "你好！", "reading": "nǐ hǎo!", "hanviet": "nễ hảo", "meaning_vi": "Xin chào!" }
  ],
  "audio": "hsk1/hsk1-d-0001.mp3"
}
```

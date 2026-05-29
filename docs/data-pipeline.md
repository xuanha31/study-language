# Phương án tạo dữ liệu HSK 3 → 6

## Vấn đề

HSK 1→6 có khoảng **~5000 từ** (HSK1:150, HSK2:150, HSK3:300, HSK4:600, HSK5:1300, HSK6:2500).
HSK 1 và HSK 2 (300 từ) đã được tạo tay và **đánh dấu `verified:false`** vì cần kiểm.

**Gõ tay 4500 từ còn lại từ trí nhớ AI sẽ có tỉ lệ sai cao**, đặc biệt:
- Thanh điệu pinyin (sai thanh = sai nghĩa trong tiếng Trung).
- Nghĩa tiếng Việt chính xác theo ngữ cảnh.
- **Âm Hán Việt** (nhiều chữ có nhiều âm).

Với app *học*, dạy sai còn tệ hơn không có dữ liệu. → Cần cách làm chính xác & kiểm chứng được, không phải "đổ" dữ liệu chưa kiểm.

## Phương án đề xuất (theo độ tin cậy)

### Phương án A — Pipeline từ nguồn mở + bảng Hán Việt *(khuyên dùng)*
1. Lấy **danh sách từ + pinyin + nghĩa** từ bộ dữ liệu HSK **mã nguồn mở** (nhiều bộ công khai có hanzi + pinyin + nghĩa tiếng Anh).
2. Lấy **nghĩa tiếng Việt**: dịch máy có kiểm, hoặc nguồn từ điển Việt mở (CC-BY).
3. Suy ra **âm Hán Việt** bằng **bảng tra Hán → Hán Việt theo từng chữ** (dựa Unihan/từ điển Hán-Việt mở) → ghép theo từng chữ. Cách này *nhất quán & kiểm được*, hơn hẳn gõ tay.
4. Viết **script chuyển đổi** sang schema của ta (`content/hskN.json`), tự đánh `verified:false`.
5. Lượt **người rà soát** trước khi `verified:true`.

→ Ưu: scale được tới 5000 từ, sai sót thấp, lặp lại được. Nhược: cần dựng script + kiểm license nguồn.

### Phương án B — Gõ tay theo từng khóa (như HSK 1/2)
Mình tạo tay từng khóa, `verified:false`, kèm cảnh báo.
→ Ưu: làm ngay. Nhược: **rất chậm & dễ sai** ở khối lượng lớn (HSK4-6); bắt buộc rà soát nặng.

### Phương án C — Lai
Gõ tay tới hết HSK 3 (mức còn kham được), HSK 4→6 dùng pipeline (Phương án A).

## Bản quyền

- **Danh sách từ HSK** là công khai (dùng được).
- **Câu/hội thoại trong giáo trình** có thể dính bản quyền → **tự viết hội thoại** hoặc dùng nguồn mở.
- Kiểm license của mọi bộ dữ liệu/ từ điển trước khi nhúng (ưu tiên CC0 / CC-BY).

## Trạng thái — ĐÃ TRIỂN KHAI (Phương án A)

✅ Đã dựng pipeline tái lập trong [../tools/](../tools/):
- `fetch-sources.sh` tải nguồn; `build-hsk.js` build → `content/hsk{3..6}.json`.
- Kết quả: HSK3 (298), HSK4 (598), HSK5 (1298), HSK6 (2500) — **0 thiếu nghĩa Việt, 0 thiếu Hán Việt**.

**Nguồn thực tế dùng:**
- Từ + pinyin: `drkameleon/complete-hsk-vocabulary` (HSK 2.0, MIT).
- Nghĩa Việt: **CVDICT** (CC-BY-SA 4.0) — AI dịch, cần rà soát.
- Hán Việt: `ph0ngp/hanviet-pinyin-wordlist` (MIT, tra theo phồn thể + pinyin) + Unihan dự phòng + bổ sung tay ~17 chữ.

Ghi công & ràng buộc license: [../content/CREDITS.md](../content/CREDITS.md). Còn lại: rà soát (E1-9) + xử lý CC-BY-SA (E1-11).

## Rà soát vòng 2 — đã sửa lỗi pipeline (quan trọng)

Phát hiện: nguồn có **nhiều `forms`/chữ** cho 1 chữ đa âm, và `forms[0]` THƯỜNG SAI (họ, biến thể, đọc Đài Loan) → sai pinyin + nghĩa hàng loạt (vd 鸟=diǎo "tục" thay vì niǎo "chim"). Đã sửa trong `build-hsk.js`:

1. **`pickForm()`** chấm điểm theo **nghĩa chính (meanings[0])**: phạt nặng form có nghĩa chính là `variant of / surname / used in / see / (Tw)` hoặc pinyin viết hoa (danh từ riêng). Ca khó không phân biệt được → bảng `OVERRIDE_READING` (vd 胖→pàng, 结果→jiéguǒ).
2. **Sửa form tự động sửa luôn `meaning_vi`** (vì nghĩa Việt tra CVDICT theo pinyin của form đã chọn).
3. **Làm sạch nghĩa**: gỡ ref `[py]`, `把[ba3]`, `(biến thể của …)`, `(Lượng từ: …)`, ghi chú "đọc là/Đài Loan"; theo **redirect** (`xem X`) và **bỏ đuôi 儿** để lấp nghĩa các biến thể/erhua; tối đa 5 nghĩa/thẻ.
4. **`chars[]`** giờ có đủ `reading + hanviet + meaning_vi` cho từng chữ (HSK3-6).
5. **HSK1/2** (`normalize-hsk12.js`): thêm `audio`, sửa `chars` chữ lặp (爸爸→[爸,爸]…).

Kết quả sau sửa: **4994 thẻ, 0 thiếu nghĩa Việt, 0 thiếu Hán Việt, 0 form nghi ngờ** (theo bộ dò tự động). Vẫn `verified:false` — *form đa âm hiếm gặp chọn sai âm vẫn có thể sót, cần người rà*.

## Hai điểm còn lại (không chặn)

- **Audio**: trường `audio` là **đường dẫn cache TTS**, file `.mp3` **không** nằm trong repo — sinh bằng `flutter_tts` lần đầu chạy (xem [design.md](design.md) mục 9). Không phải lỗi thiếu file.
- **Số lượng từ**: nguồn cho 298/598/1298 (HSK 3/4/5) so với chuẩn phổ biến 300/600/1300 — **thiếu ~2/level** do bộ dữ liệu nguồn. Cần đối chiếu danh sách chuẩn để bổ sung nếu muốn đủ tuyệt đối (task E1-12).

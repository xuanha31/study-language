# Ghi công & Giấy phép nguồn dữ liệu (content)

Dữ liệu HSK 3→6 trong thư mục này được tạo từ các nguồn mở dưới đây. **Phải giữ ghi công này** khi phát hành.

## Nguồn

| Trường dữ liệu | Nguồn | Tác giả | Giấy phép |
|----------------|-------|---------|-----------|
| Từ vựng, pinyin, nghĩa tiếng Anh (tham chiếu) | [complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary) | Yanis Zafirópulos | MIT |
| Nghĩa tiếng Việt (`meaning_vi`) | [CVDICT](https://github.com/ph0ngp/CVDICT) | Phong Phan | **CC-BY-SA 4.0** |
| Âm Hán Việt (`hanviet`) | [hanviet-pinyin-wordlist](https://github.com/ph0ngp/hanviet-pinyin-wordlist) | Phong Phan | MIT |
| Hán Việt (dự phòng) | [Unihan Database](https://www.unicode.org/charts/unihan.html) (`kVietnamese`) | Unicode, Inc. | Unicode License |
| Nghĩa Anh gốc trong CVDICT/HSK | [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict) | MDBG | CC-BY-SA 3.0 |

## ⚠️ Ràng buộc giấy phép QUAN TRỌNG (cần lưu ý cho sản phẩm)

- **`meaning_vi` đến từ CVDICT (CC-BY-SA 4.0)** → đây là giấy phép **"chia sẻ tương tự" (share-alike)**. Khi phát hành app, **phần dữ liệu nghĩa tiếng Việt** phải:
  1. **Ghi công** tác giả (Phong Phan / CVDICT) — ví dụ trong màn "Giới thiệu / Nguồn dữ liệu" của app.
  2. **Chia sẻ lại cùng giấy phép CC-BY-SA 4.0** nếu phân phối phần dữ liệu đó.
  - *[Lưu ý — không phải tư vấn pháp lý]* Share-alike thường áp cho **bản thân dữ liệu**, không bắt buộc mã nguồn app phải mở. Nhưng nếu muốn dữ liệu nghĩa Việt **độc quyền**, cần thay nguồn này (tự dịch / nguồn khác). Nên hỏi ý kiến pháp lý nếu thương mại hóa.
- CC-CEDICT (gốc của CVDICT) cũng là CC-BY-SA → tính chất tương tự.
- Các nguồn còn lại (MIT, Unicode License) chỉ yêu cầu **giữ thông báo bản quyền**, không share-alike.

## Trạng thái kiểm chứng

Tất cả thẻ `verified: false`. `meaning_vi` (AI dịch) và `hanviet` (chọn âm tự động) **cần rà soát bởi người rành tiếng Trung** trước khi phát hành — xem [README.md](README.md).

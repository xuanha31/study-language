# tools/ — Pipeline tạo dữ liệu HSK 3→6

Sinh `content/hsk{3..6}.json` từ nguồn mở. **Tái lập được** — không cần gõ tay.

## Cách dùng

```bash
bash tools/fetch-sources.sh   # tải nguồn về tools/_src/ (cần curl + unzip)
node tools/build-hsk.js       # build -> content/hsk3..6.json
```

## Công cụ rà soát/dọn nội dung (E1-4/9/12)

```bash
node tools/validate-content.js       # rà soát -> in tóm tắt + ghi docs/content-review.md
node tools/clean-meanings.js          # dry-run: xem trước thay đổi nghĩa
node tools/clean-meanings.js --write  # dọn rác Hán/[pinyin] trong meaning_vi + bump version
```

- `validate-content.js`: **gắn cờ thẻ nghi vấn** (id trùng, thiếu trường, pinyin sai
  định dạng/nghi thiếu thanh, lệch số âm tiết Hán Việt, nghĩa lẫn chữ Hán, nhóm
  distractor < 4, số từ thiếu so chuẩn). **Không** kết luận đúng/sai ngôn ngữ.
- `clean-meanings.js`: chỉ **bỏ rác** (chữ Hán, `[pinyin]`, tham chiếu cụt) khỏi
  `meaning_vi`, **giữ nguyên** phần tiếng Việt; vẫn `verified:false`.

> `tools/_src/` chứa file nguồn tải về (lớn, có license riêng) — **đã .gitignore**, không commit.

## Nguồn dữ liệu (xem ghi công đầy đủ ở [../content/CREDITS.md](../content/CREDITS.md))

| Mảnh | Nguồn | License |
|------|-------|---------|
| Từ + pinyin + nghĩa Anh (tham chiếu) | drkameleon/complete-hsk-vocabulary | MIT |
| Nghĩa tiếng Việt (`meaning_vi`) | CVDICT (Phong Phan) | **CC-BY-SA 4.0** |
| Âm Hán Việt (`hanviet`) | ph0ngp/hanviet-pinyin-wordlist | MIT |
| Hán Việt dự phòng | Unihan `kVietnamese` (Unicode) | Unicode License |

## Cách build hoạt động (`build-hsk.js`)

1. **Hán Việt:** tra theo chữ **PHỒN THỂ** + pinyin từng chữ (phân biệt chữ đa âm), dự phòng theo chữ giản thể → Unihan → bảng bổ sung tay (`SUPPLEMENT_HV`).
2. **Nghĩa Việt:** khớp CVDICT theo `giản_thể + pinyin số`, dự phòng theo giản thể, rồi `SUPPLEMENT_VI`.
3. **distractor_group:** suy từ `pos` (từ loại) của nguồn.
4. Chia bài 20 thẻ; `verified:false`.

## ⚠️ Lưu ý chất lượng (đọc kỹ)

- `meaning_vi` từ CVDICT do **AI dịch** (tác giả cảnh báo còn lỗi). **Cần rà soát.**
- `hanviet` lấy **âm khớp pinyin** nếu có, không thì **âm đầu tiên** trong bảng → chữ đa âm có thể chọn sai âm theo ngữ cảnh. **Cần rà soát.**
- Một số chữ giản thể đặc thù được bổ sung tay trong `SUPPLEMENT_HV` (xem file).

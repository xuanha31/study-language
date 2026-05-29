#!/usr/bin/env bash
# Tải các nguồn mở cần để build dữ liệu HSK 3-6 vào tools/_src/.
# Chạy: bash tools/fetch-sources.sh   (cần curl + unzip)
set -e
cd "$(dirname "$0")"
mkdir -p _src && cd _src

echo "[1/4] HSK old (2.0) wordlists 3-6 — drkameleon/complete-hsk-vocabulary (MIT)"
for lv in 3 4 5 6; do
  curl -sL --max-time 120 \
    "https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/main/wordlists/exclusive/old/$lv.json" \
    -o "hsk_old_$lv.json"
done

echo "[2/4] CVDICT — nghĩa tiếng Việt (Phong Phan, CC-BY-SA 4.0)"
curl -sL --max-time 180 "https://raw.githubusercontent.com/ph0ngp/CVDICT/master/CVDICT.u8" -o CVDICT.u8

echo "[3/4] hanviet.csv — âm Hán Việt từng chữ (ph0ngp/hanviet-pinyin-wordlist, MIT)"
curl -sL --max-time 120 "https://raw.githubusercontent.com/ph0ngp/hanviet-pinyin-wordlist/main/hanviet.csv" -o hanviet.csv

echo "[4/4] Unihan kVietnamese (Unicode) — dự phòng Hán Việt"
curl -sL --max-time 300 "https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip" -o Unihan.zip
unzip -o Unihan.zip Unihan_Readings.txt >/dev/null

echo "Xong. Giờ chạy: node tools/build-hsk.js"

#!/usr/bin/env node
/*
 * normalize-hsk12.js — chuẩn hóa HSK1/2 (gõ tay):
 *   1) thêm trường `audio` nếu thiếu (đường dẫn cache TTS).
 *   2) sửa `chars` cho từ có chữ lặp/đếm lệch (vd 爸爸 phải có 2 phần tử 爸).
 * Giữ nguyên mọi trường khác. Chạy: node tools/normalize-hsk12.js
 */
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, '..', 'content');

for (const lv of [1, 2]) {
  const file = path.join(OUT, `hsk${lv}.json`);
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  let fixedChars = 0, addedAudio = 0;
  for (const c of data.cards) {
    if (!c.audio) { c.audio = `hsk${lv}/${c.id}.mp3`; addedAudio++; }
    const chs = [...c.target];
    if (chs.length > 1) {
      const byChar = {};
      (c.chars || []).forEach(x => { if (!byChar[x.char]) byChar[x.char] = x; });
      if (!c.chars || c.chars.length !== chs.length) {
        c.chars = chs.map(ch => byChar[ch] || { char: ch, reading: '', hanviet: '', meaning_vi: '' });
        fixedChars++;
      }
    }
  }
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
  console.log(`HSK${lv}: thêm audio ${addedAudio} thẻ, sửa chars ${fixedChars} thẻ`);
}

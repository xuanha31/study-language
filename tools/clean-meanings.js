#!/usr/bin/env node
/**
 * Dọn "nghĩa tiếng Việt" còn dính rác từ CC-CEDICT/AI-dịch (E1-9):
 * bỏ chữ Hán, `[pinyin...]`, ngoặc tham chiếu Hán còn sót. KHÔNG đụng phần
 * tiếng Việt thật, KHÔNG khẳng định nghĩa đúng (vẫn verified:false).
 *
 *   node tools/clean-meanings.js          # dry-run: in các thay đổi
 *   node tools/clean-meanings.js --write   # ghi vào file + bump version
 */
const fs = require('fs');
const path = require('path');

const CONTENT = path.join(__dirname, '..', 'content');
const WRITE = process.argv.includes('--write');
const HAN = /[\p{Script=Han}｜|]/u;

const CONNECTIVE = 'như trong|viết tắt của|tương đương với|kết hợp với|xuất phát từ|khác với';

function clean(s) {
  if (!s || typeof s !== 'string') return s;
  let t = s;
  t = t.replace(/\(LT:[^)]*\)/gi, '');        // (LT: 漢字) — "nghĩa đen" ref
  t = t.replace(/\[[^\]]*\]/g, '');           // [pinyin / refs]
  t = t.replace(/[\p{Script=Han}｜|]+/gu, ''); // chữ Hán + pipe
  // cụm liên kết bị cụt (mất phần Hán phía sau) -> bỏ (không dùng \b vì chữ có dấu)
  t = t.replace(new RegExp(`(?:${CONNECTIVE})\\s*(?=[;,)\\]]|\\.\\.\\.|$)`, 'gi'), '');
  t = t.replace(/[，、；：·]+/g, '; ');         // dấu CJK -> ;
  // dọn dấu thừa quanh chỗ vừa xóa
  t = t.replace(/\(\s*[,;]+\s*/g, '(');
  t = t.replace(/\s*,\s*\)/g, ')');
  t = t.replace(/\s*,\s*\.\.\./g, '...');
  t = t.replace(/\s*[,;]\s*(?=[);])/g, '');
  t = t.replace(/,(\s*,)+/g, ',').replace(/;(\s*;)+/g, ';'); // dấu lặp
  t = t.replace(/,\s*;/g, ';').replace(/;\s*,/g, ';');
  // bỏ ngoặc không còn chữ cái/số bên trong
  for (let i = 0; i < 3; i++) {
    t = t.replace(/\(\s*[^A-Za-zÀ-ỹ0-9]*\s*\)/g, '');
  }
  t = t.replace(/\s+/g, ' ').replace(/\s*;\s*/g, '; ');
  t = t.replace(/\(\s+/g, '(').replace(/\s+\)/g, ')');
  t = t.replace(/\s+([;,.)])/g, '$1');
  t = t.replace(/^[;,\.\s]+/, '').replace(/[;,\s]+$/, '').trim();
  return t;
}

function cleanCard(c) {
  let changed = false;
  const nm = clean(c.meaning_vi);
  if (nm && nm !== c.meaning_vi) { c.meaning_vi = nm; changed = true; }
  if (Array.isArray(c.chars)) {
    for (const ch of c.chars) {
      const cm = clean(ch.meaning_vi);
      if (cm && cm !== ch.meaning_vi) { ch.meaning_vi = cm; changed = true; }
    }
  }
  return changed;
}

function main() {
  const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT, 'manifest.json'), 'utf8'));
  let totalChanged = 0;
  let shown = 0;
  const changedCourses = new Set();

  for (const course of manifest.courses) {
    const file = path.join(CONTENT, course.url);
    const data = JSON.parse(fs.readFileSync(file, 'utf8'));
    let fileChanged = 0;
    for (const c of data.cards || []) {
      const before = c.meaning_vi;
      if (cleanCard(c)) {
        fileChanged++;
        c.version = (c.version || 1) + 1; // để client cập nhật (giữ id -> giữ tiến độ)
        if (shown < 20 && HAN.test(before || '')) {
          console.log(`\n[${c.id}] ${c.target}`);
          console.log(`  - cũ : ${before}`);
          console.log(`  + mới: ${c.meaning_vi}`);
          shown++;
        }
      }
    }
    if (fileChanged > 0) {
      changedCourses.add(course.code);
      data.version = (data.version || 1) + 1;
      if (WRITE) fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
    }
    totalChanged += fileChanged;
    console.log(`${course.code}: ${fileChanged} thẻ ${WRITE ? 'đã sửa' : 'sẽ sửa'}`);
  }

  if (WRITE && changedCourses.size > 0) {
    for (const co of manifest.courses) {
      if (changedCourses.has(co.code)) co.version = (co.version || 1) + 1;
    }
    fs.writeFileSync(path.join(CONTENT, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
  }
  console.log(`\nTổng: ${totalChanged} thẻ ${WRITE ? 'đã sửa (đã bump version)' : 'sẽ sửa (chạy --write để áp dụng)'}`);
}

main();

#!/usr/bin/env node
/**
 * Rà soát nội dung HSK (E1-4/E1-9/E1-12) — KHÔNG xác minh đúng/sai về mặt ngôn ngữ
 * (việc đó cần người rành tiếng Trung), chỉ gắn cờ các thẻ NGHI VẤN để người rà
 * tập trung kiểm. In tóm tắt ra màn hình và ghi báo cáo docs/content-review.md.
 *
 * Kiểm tra:
 *  - id trùng (toàn hệ thống)
 *  - thiếu trường bắt buộc (id/target/reading/meaning_vi/hanviet/distractor_group)
 *  - pinyin: có chữ số (sai định dạng) hoặc 1 âm tiết mà không có dấu thanh (nghi thiếu thanh)
 *  - lệch số âm tiết Hán Việt so với số chữ Hán
 *  - meaning_vi rỗng / lẫn chữ Hán
 *  - nhóm distractor quá nhỏ (<4) -> khó dựng 4 đáp án "đáng tin"
 *  - số từ mỗi bài (≠20 ở bài giữa) và tổng số từ so chuẩn HSK
 */
const fs = require('fs');
const path = require('path');

const CONTENT = path.join(__dirname, '..', 'content');
const REPORT = path.join(__dirname, '..', 'docs', 'content-review.md');
const STANDARD = { HSK1: 150, HSK2: 150, HSK3: 300, HSK4: 600, HSK5: 1300, HSK6: 2500 };
const CAP = 15; // số ví dụ tối đa hiển thị mỗi mục

const TONE = /[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]/;
const HAN = /\p{Script=Han}/u;
const HAN_G = /\p{Script=Han}/gu;
// Âm tiết thanh nhẹ hợp lệ (không có dấu) — tránh báo nhầm "thiếu thanh".
const NEUTRAL = new Set(['de', 'le', 'ma', 'ne', 'ba', 'zhe', 'ya', 'me', 'guo', 'la', 'lo', 'lou', 'zi', 'men', 'ge']);

function hanCount(s) {
  const m = (s || '').match(HAN_G);
  return m ? m.length : 0;
}

function loadManifest() {
  const raw = fs.readFileSync(path.join(CONTENT, 'manifest.json'), 'utf8');
  return JSON.parse(raw).courses;
}

function checkCourse(course, seenIds) {
  const file = path.join(CONTENT, course.url);
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  const cards = data.cards || [];
  const issues = {
    dupId: [], missingField: [], pinyinDigit: [], pinyinNoTone: [],
    hanvietLen: [], meaningEmpty: [], meaningHan: [],
  };
  const lessonCount = {};
  const groupCount = {};

  for (const c of cards) {
    lessonCount[c.lesson] = (lessonCount[c.lesson] || 0) + 1;
    if (c.distractor_group) groupCount[c.distractor_group] = (groupCount[c.distractor_group] || 0) + 1;

    if (c.id) {
      if (seenIds.has(c.id)) issues.dupId.push(c.id);
      seenIds.add(c.id);
    }
    for (const f of ['id', 'target', 'reading', 'meaning_vi', 'hanviet', 'distractor_group']) {
      if (!c[f] || String(c[f]).trim() === '') { issues.missingField.push(`${c.id || '?'}:${f}`); }
    }
    const reading = c.reading || '';
    if (/[0-9]/.test(reading)) issues.pinyinDigit.push(`${c.id} "${reading}"`);
    else if (hanCount(c.target) === 1 && !TONE.test(reading) && !NEUTRAL.has(reading.trim().toLowerCase())) {
      issues.pinyinNoTone.push(`${c.id} ${c.target} "${reading}"`);
    }

    const hv = (c.hanviet || '').trim();
    const hvSyl = hv ? hv.split(/\s+/).length : 0;
    const hc = hanCount(c.target);
    if (hc > 0 && hvSyl > 0 && hvSyl !== hc) issues.hanvietLen.push(`${c.id} ${c.target}(${hc}) ↔ "${hv}"(${hvSyl})`);

    const mv = c.meaning_vi || '';
    if (mv.trim() === '') issues.meaningEmpty.push(c.id);
    else if (HAN.test(mv)) issues.meaningHan.push(`${c.id} "${mv}"`);
  }

  const smallGroups = Object.entries(groupCount).filter(([, n]) => n < 4).map(([g, n]) => `${g}(${n})`);
  const lessons = Object.keys(lessonCount).map(Number).sort((a, b) => a - b);
  const lastLesson = lessons[lessons.length - 1];
  const shortLessons = lessons.filter((l) => lessonCount[l] !== 20 && l !== lastLesson)
    .map((l) => `bài ${l}=${lessonCount[l]}`);

  return { course, total: cards.length, issues, smallGroups, shortLessons, lastLessonSize: lessonCount[lastLesson] };
}

function section(title, arr) {
  if (!arr.length) return `- ✅ ${title}: 0\n`;
  const sample = arr.slice(0, CAP).map((x) => `  - ${x}`).join('\n');
  const more = arr.length > CAP ? `\n  - …và ${arr.length - CAP} mục nữa` : '';
  return `- ⚠️ **${title}: ${arr.length}**\n${sample}${more}\n`;
}

function main() {
  const courses = loadManifest();
  const seenIds = new Set();
  const results = courses.map((c) => checkCourse(c, seenIds));

  const lines = [];
  lines.push('# Báo cáo rà soát nội dung (tự sinh)\n');
  lines.push('> Sinh bởi `tools/validate-content.js`. Đây là **cờ nghi vấn cần người kiểm**,');
  lines.push('> KHÔNG phải kết luận đúng/sai. Việc xác minh ngôn ngữ cần người rành tiếng Trung.\n');

  lines.push('## Tổng quan\n');
  lines.push('| Khóa | Số từ | Chuẩn | Lệch | id trùng | thiếu trường | pinyin số | nghi thiếu thanh | lệch Hán Việt | nghĩa lỗi |');
  lines.push('|------|------:|------:|-----:|---------:|-------------:|----------:|-----------------:|--------------:|----------:|');
  let totalFlags = 0;
  for (const r of results) {
    const std = STANDARD[r.course.code] ?? r.total;
    const i = r.issues;
    const meaningBad = i.meaningEmpty.length + i.meaningHan.length;
    totalFlags += i.dupId.length + i.missingField.length + i.pinyinDigit.length +
      i.pinyinNoTone.length + i.hanvietLen.length + meaningBad;
    lines.push(`| ${r.course.code} | ${r.total} | ${std} | ${r.total - std} | ${i.dupId.length} | ${i.missingField.length} | ${i.pinyinDigit.length} | ${i.pinyinNoTone.length} | ${i.hanvietLen.length} | ${meaningBad} |`);
  }
  lines.push('');

  for (const r of results) {
    const i = r.issues;
    lines.push(`## ${r.course.code} — ${r.total} từ\n`);
    if (r.shortLessons.length) lines.push(`- ⚠️ Bài chưa đủ 20 từ: ${r.shortLessons.join(', ')} (bài cuối: ${r.lastLessonSize})\n`);
    lines.push(section('id trùng', i.dupId));
    lines.push(section('Thiếu trường bắt buộc', i.missingField));
    lines.push(section('Pinyin có chữ số (sai định dạng)', i.pinyinDigit));
    lines.push(section('Nghi thiếu thanh điệu (1 âm tiết, không dấu)', i.pinyinNoTone));
    lines.push(section('Lệch số âm tiết Hán Việt ↔ số chữ Hán', i.hanvietLen));
    lines.push(section('Nghĩa rỗng', i.meaningEmpty));
    lines.push(section('Nghĩa lẫn chữ Hán', i.meaningHan));
    lines.push(section('Nhóm distractor < 4 thành viên', r.smallGroups));
  }

  fs.writeFileSync(REPORT, lines.join('\n'));
  console.log(`Đã ghi báo cáo: ${path.relative(path.join(__dirname, '..'), REPORT)}`);
  console.log(`Tổng số cờ nghi vấn: ${totalFlags}`);
  for (const r of results) {
    const std = STANDARD[r.course.code] ?? r.total;
    console.log(`  ${r.course.code}: ${r.total} từ (chuẩn ${std}, lệch ${r.total - std})`);
  }
}

main();

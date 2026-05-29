#!/usr/bin/env node
/*
 * build-hsk.js — Sinh content/hsk{3..6}.json từ 3 nguồn mở:
 *   1) HSK old (2.0) wordlists: drkameleon/complete-hsk-vocabulary (MIT)
 *      -> simplified, pinyin (tone marks + numeric), pos, nghĩa tiếng Anh (CC-CEDICT)
 *   2) CVDICT (Phong Phan, CC-BY-SA 4.0) -> nghĩa tiếng Việt
 *   3) Unihan kVietnamese (Unicode) -> âm Hán Việt từng chữ
 *
 * Nguồn tải sẵn vào tools/_src/. Chạy: node tools/build-hsk.js
 *
 * LƯU Ý: dữ liệu sinh ra verified:false. meaning_vi (CVDICT) do AI dịch, hanviet lấy
 * âm ĐẦU TIÊN trong Unihan (có thể sai theo ngữ cảnh). CẦN rà soát trước khi phát hành.
 */
const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, '_src');
const OUT = path.join(__dirname, '..', 'content');

// Bổ sung TAY các chữ giản thể không có trong bảng Hán Việt phồn thể.
// (do người soạn thêm — vẫn nên rà soát.)
const SUPPLEMENT_HV = {
  '却': 'khước', '稍': 'sảo', '卡': 'ca', '厅': 'thính', '岛': 'đảo',
  '营': 'doanh', '幕': 'mạc', '启': 'khải', '仓': 'thương', '伺': 'tý',
  '辰': 'thần', '缀': 'chuế', '膜': 'mô', '洽': 'hiệp', '缚': 'phược',
  '赁': 'nhẫm', '钻': 'toản',
};
// Bổ sung TAY nghĩa Việt các từ CVDICT không có khớp.
const SUPPLEMENT_VI = {
  '系领带': 'thắt cà vạt',
  '纽扣儿': 'khuy áo, cúc áo',
  '致力于': 'dốc sức vào, cống hiến cho',
};

// ---------- 1) Bảng Hán Việt từng chữ ----------
// Nguồn chính: hanviet.csv (ph0ngp/hanviet-pinyin-wordlist, MIT) — char,[hanviet],pinyinSố
//   -> phủ ~10k chữ PHỒN THỂ, có pinyin để phân biệt chữ đa âm.
// Dự phòng: Unihan kVietnamese (Unicode).
function loadHanViet() {
  const byCharPy = new Map(); // 'char|pinyinSố' -> hanviet
  const byChar = new Map();   // 'char' -> hanviet (âm đầu tiên gặp)
  const csv = fs.readFileSync(path.join(SRC, 'hanviet.csv'), 'utf8');
  for (const line of csv.split('\n').slice(1)) {
    const m = line.match(/^(.),\[(.*)\],(.+)$/);
    if (!m) continue;
    const ch = m[1];
    const hv = m[2].split(',')[0].replace(/['"\s]/g, ''); // âm đầu trong list
    const py = m[3].trim().toLowerCase();
    if (!hv) continue;
    byCharPy.set(ch + '|' + py, hv);
    if (!byChar.has(ch)) byChar.set(ch, hv);
  }
  // Unihan dự phòng
  const txt = fs.readFileSync(path.join(SRC, 'Unihan_Readings.txt'), 'utf8');
  for (const line of txt.split('\n')) {
    if (!line.startsWith('U+')) continue;
    const p = line.split('\t');
    if (p.length < 3 || p[1] !== 'kVietnamese') continue;
    const ch = String.fromCodePoint(parseInt(p[0].slice(2), 16));
    const hv = p[2].trim().split(/\s+/)[0];
    if (!byChar.has(ch)) byChar.set(ch, hv);
  }
  return { byCharPy, byChar };
}

// ---------- 2) CVDICT: "simp|numericPinyin" -> [nghĩa Việt] ----------
function normPinyin(s) {
  return s.toLowerCase().replace(/u:/g, 'u').replace(/\s+/g, '');
}
function loadCvdict() {
  const txt = fs.readFileSync(path.join(SRC, 'CVDICT.u8'), 'utf8');
  const byKey = new Map();   // simp+pinyin
  const bySimp = new Map();  // fallback: simp -> meanings của dòng đầu
  const re = /^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+\/(.*)\/\s*$/;
  for (const line of txt.split('\n')) {
    if (!line || line.startsWith('#')) continue;
    const m = line.match(re);
    if (!m) continue;
    const simp = m[2];
    const py = normPinyin(m[3]);
    const meanings = m[4].split('/')
      .map(x => x.trim())
      .filter(x => x && !/^(LT:|CL:)/.test(x)) // bỏ chú thích lượng từ
      .filter(x => !/^[a-zA-Z]+\|/.test(x));   // bỏ ref dạng 個|个[ge4]
    if (!meanings.length) continue;
    byKey.set(simp + '|' + py, meanings);
    if (!bySimp.has(simp)) bySimp.set(simp, meanings);
  }
  return { byKey, bySimp };
}

// ---------- pos -> distractor_group ----------
function posGroup(pos) {
  const p = (pos && pos[0]) || '';
  if (/^(n|ng|nr|ns|nt|nz)$/.test(p)) return 'noun';
  if (/^(v|vn|vd|vg)$/.test(p)) return 'verb';
  if (/^(a|ad|ag|an|b)$/.test(p)) return 'adj';
  if (/^(d|dg)$/.test(p)) return 'adverb';
  if (/^(m|mg)$/.test(p)) return 'number';
  if (p === 'q') return 'measure';
  if (/^(r|rg)$/.test(p)) return 'pronoun';
  if (p === 'p') return 'preposition';
  if (p === 'c') return 'conjunction';
  if (/^(u|y)$/.test(p)) return 'particle';
  if (/^(t|tg)$/.test(p)) return 'time';
  if (/^(i|l)$/.test(p)) return 'idiom';
  return 'other';
}

// Tra âm Hán Việt theo PHỒN THỂ + pinyin từng chữ (phân biệt đa âm),
// dự phòng theo chữ phồn thể rồi giản thể. Trả về mảng âm khớp vị trí với simplified.
function hanvietPerChar(simplified, traditional, numericPinyin, hv) {
  const simp = [...simplified];
  const trad = [...traditional];
  const syl = (numericPinyin || '').toLowerCase().trim().split(/\s+/);
  const aligned = syl.length === simp.length; // pinyin khớp số chữ?
  return simp.map((sc, i) => {
    const tc = trad[i] || sc;
    const py = aligned ? syl[i] : null;
    const r =
      (py && hv.byCharPy.get(tc + '|' + py)) ||
      (py && hv.byCharPy.get(sc + '|' + py)) ||
      hv.byChar.get(tc) ||
      hv.byChar.get(sc) ||
      SUPPLEMENT_HV[tc] ||
      SUPPLEMENT_HV[sc] ||
      '?';
    return r;
  });
}

function build(level, hv, cv) {
  const src = JSON.parse(fs.readFileSync(path.join(SRC, `hsk_old_${level}.json`), 'utf8'));
  const cards = src.map((e, i) => {
    const form = e.forms[0];
    const tr = form.transcriptions;
    const simp = e.simplified;
    const trad = form.traditional || simp;
    const py = normPinyin(tr.numeric || tr.pinyin);
    let vi = cv.byKey.get(simp + '|' + py) || cv.bySimp.get(simp) || [];
    if (!vi.length && SUPPLEMENT_VI[simp]) vi = [SUPPLEMENT_VI[simp]];
    const hvArr = hanvietPerChar(simp, trad, tr.numeric, hv);
    const card = {
      id: `hsk${level}-${String(i + 1).padStart(4, '0')}`,
      type: 'vocab',
      level: `HSK${level}`,
      lesson: Math.floor(i / 20) + 1,
      version: 1,
      verified: false,
      target: simp,
      reading: tr.pinyin,
      meaning_vi: vi.join('; '),
      meaning_en: (form.meanings || []).join('; '),
      hanviet: hvArr.join(' '),
      distractor_group: posGroup(e.pos),
      audio: `hsk${level}/hsk${level}-${String(i + 1).padStart(4, '0')}.mp3`,
    };
    if ([...simp].length > 1) {
      card.chars = [...simp].map((ch, k) => ({ char: ch, hanviet: hvArr[k] }));
    }
    return card;
  });
  const out = {
    code: `HSK${level}`,
    title_vi: `HSK ${level}`,
    version: 1,
    lessonSize: 20,
    _warning: 'Sinh tu nguon mo (HSK list MIT + CVDICT CC-BY-SA-4.0 + Unihan kVietnamese). verified=false. meaning_vi do AI dich (CVDICT), hanviet lay am dau tien Unihan - CAN ra soat.',
    _sources: {
      wordlist: 'drkameleon/complete-hsk-vocabulary (MIT)',
      meaning_vi: 'CVDICT - Phong Phan (CC-BY-SA 4.0)',
      hanviet: 'Unihan kVietnamese (Unicode)',
    },
    cards,
  };
  fs.writeFileSync(path.join(OUT, `hsk${level}.json`), JSON.stringify(out, null, 2) + '\n');
  const missVi = cards.filter(c => !c.meaning_vi).length;
  const missHv = cards.filter(c => c.hanviet.includes('?')).length;
  console.log(`HSK${level}: ${cards.length} cards | thiếu nghĩa_vi: ${missVi} | thiếu hanviet: ${missHv}`);
}

const hv = loadHanViet();
const cv = loadCvdict();
console.log(`Hán Việt chars: ${hv.byChar.size} | CVDICT keys: ${cv.byKey.size}`);
for (const lv of [3, 4, 5, 6]) build(lv, hv, cv);
console.log('Done.');

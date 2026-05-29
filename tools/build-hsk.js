#!/usr/bin/env node
/*
 * build-hsk.js — Sinh content/hsk{3..6}.json từ 3 nguồn mở:
 *   1) HSK old (2.0) wordlists: drkameleon/complete-hsk-vocabulary (MIT)
 *      -> simplified, NHIỀU forms (mỗi form có pinyin + nghĩa Anh riêng), pos
 *   2) CVDICT (Phong Phan, CC-BY-SA 4.0) -> nghĩa tiếng Việt
 *   3) hanviet.csv (ph0ngp, MIT) + Unihan kVietnamese -> âm Hán Việt từng chữ
 *
 * Chạy: node tools/build-hsk.js   (sau khi bash tools/fetch-sources.sh)
 *
 * QUAN TRỌNG: 1 chữ Hán đa âm có nhiều "form" (vd 鸟 = diǎo "biến thể tục" / niǎo "chim").
 * forms[0] trong nguồn THƯỜNG SAI (họ/biến thể/đọc Đài Loan). pickForm() chấm điểm để
 * loại các form đó và chọn form phổ thông. Vẫn còn ca khó -> OVERRIDE_READING.
 *
 * Dữ liệu verified:false. meaning_vi (CVDICT) do AI dịch; hanviet chọn theo pinyin.
 * CẦN người rành tiếng Trung rà soát trước khi phát hành.
 */
const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, '_src');
const OUT = path.join(__dirname, '..', 'content');

// Ép chọn cách đọc (numeric pinyin) cho các từ đa âm mà heuristic không phân biệt được.
const OVERRIDE_READING = {
  '胖': 'pang4', '结果': 'jie2 guo3', '假': 'jia3', '系': 'xi4',
  '种': 'zhong3', '当': 'dang1', '重': 'zhong4', '难': 'nan2',
  '行': 'xing2', '长': 'chang2', '空': 'kong1', '差': 'cha4',
  '都': 'dou1', '为': 'wei4', '会': 'hui4', '还': 'hai2',
};

// Bổ sung TAY chữ giản thể không có trong bảng Hán Việt phồn thể.
const SUPPLEMENT_HV = {
  '却': 'khước', '稍': 'sảo', '卡': 'ca', '厅': 'thính', '岛': 'đảo',
  '营': 'doanh', '幕': 'mạc', '启': 'khải', '仓': 'thương', '伺': 'tý',
  '辰': 'thần', '缀': 'chuế', '膜': 'mô', '洽': 'hiệp', '缚': 'phược',
  '赁': 'nhẫm', '钻': 'toản',
};
// Bổ sung TAY nghĩa Việt các từ CVDICT không khớp.
const SUPPLEMENT_VI = {
  '系领带': 'thắt cà vạt',
  '纽扣儿': 'khuy áo, cúc áo',
  '致力于': 'dốc sức vào, cống hiến cho',
  '辆': 'lượng từ cho xe cộ (xe, ô tô...)',
  '棵': 'lượng từ cho cây cối, thực vật',
  '颗': 'lượng từ cho vật nhỏ hình tròn (hạt, viên, ngọc, sao...)',
  '艘': 'lượng từ cho tàu, thuyền',
};

// ---------- Hán Việt từng chữ ----------
function loadHanViet() {
  const byCharPy = new Map();
  const byChar = new Map();
  const csv = fs.readFileSync(path.join(SRC, 'hanviet.csv'), 'utf8');
  for (const line of csv.split('\n').slice(1)) {
    const m = line.match(/^(.),\[(.*)\],(.+)$/);
    if (!m) continue;
    const ch = m[1];
    const hv = m[2].split(',')[0].replace(/['"\s]/g, '');
    const py = m[3].trim().toLowerCase();
    if (!hv) continue;
    byCharPy.set(ch + '|' + py, hv);
    if (!byChar.has(ch)) byChar.set(ch, hv);
  }
  const txt = fs.readFileSync(path.join(SRC, 'Unihan_Readings.txt'), 'utf8');
  for (const line of txt.split('\n')) {
    if (!line.startsWith('U+')) continue;
    const p = line.split('\t');
    if (p.length < 3 || p[1] !== 'kVietnamese') continue;
    const ch = String.fromCodePoint(parseInt(p[0].slice(2), 16));
    if (!byChar.has(ch)) byChar.set(ch, p[2].trim().split(/\s+/)[0]);
  }
  return { byCharPy, byChar };
}

// ---------- làm sạch 1 danh sách nghĩa (loại chú thích thô của từ điển) ----------
const CJK = '\\u3400-\\u9fff';
function cleanMeanings(arr) {
  const out = [];
  for (let s of arr) {
    s = s.trim();
    if (!s) continue;
    // bỏ ref dạng 個|个[ge4] hoặc 屌[diao3] đứng riêng
    if (new RegExp(`^[${CJK}]+(\\|[${CJK}]+)?\\[[A-Za-z0-9: ]+\\]$`).test(s)) continue;
    if (/^(LT:|CL:|Lượng từ)/i.test(s)) continue;       // lượng từ
    if (/^[A-Za-z]+\|/.test(s)) continue;               // 个|gè
    if (/^(biến thể|biến dạng|dạng cổ|cách viết khác|cũng viết|cũng đọc|xem |dùng trong|dùng cho)/i.test(s)) continue;
    if (/^(variant of|old variant|see |used in|abbr)/i.test(s)) continue;
    if (/(đọc là|đài loan đọc|khẩu ngữ đọc|tiếng đài loan)/i.test(s)) continue; // ghi chú phát âm
    // gỡ cụm "(biến thể của 闇[an4])" / "(variant of X)" / "(Lượng từ: ...)" trong ngoặc
    s = s.replace(/\((biến thể của|variant of|xem|cũng viết|cũng đọc|lượng từ)[^)]*\)/gi, '');
    // gỡ ref nội dòng 屌[diao3] và ref pinyin trần [xie3]
    s = s.replace(new RegExp(`[${CJK}]+(\\|[${CJK}]+)?\\[[A-Za-zü: ]+[0-9]?\\]`, 'g'), '');
    s = s.replace(/\[[A-Za-zü:]+[0-9]?\]/g, '');
    s = s.replace(/\(\s*\)/g, '').replace(/\s{2,}/g, ' ')
         .replace(/^[;,\s]+/, '').replace(/[;,\s]+$/, '').trim();
    if (s) out.push(s);
  }
  return [...new Set(out)].slice(0, 5); // tối đa 5 nghĩa cho gọn
}
// Lấy chữ giản thể đích của 1 redirect "biến thể của 繁|简[py]" / "xem 简[py]"
function redirectTarget(rawMeanings) {
  for (const s of rawMeanings) {
    if (!/^(biến thể|cũng viết|cũng đọc|xem )/i.test(s.trim())) continue;
    const m = s.match(new RegExp(`([${CJK}]+)(\\|([${CJK}]+))?\\[`));
    if (m) return m[3] || m[1];
  }
  return null;
}

// ---------- CVDICT: "simp|pinyinSố" + "simp" -> nghĩa Việt ----------
function normPinyin(s) {
  return s.toLowerCase().replace(/u:/g, 'u').replace(/\s+/g, '');
}
function loadCvdict() {
  const txt = fs.readFileSync(path.join(SRC, 'CVDICT.u8'), 'utf8');
  const byKey = new Map();
  const bySimp = new Map();
  const redirect = new Map(); // simp -> simp đích (khi chỉ là "biến thể của/xem")
  const re = /^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+\/(.*)\/\s*$/;
  for (const line of txt.split('\n')) {
    if (!line || line.startsWith('#')) continue;
    const m = line.match(re);
    if (!m) continue;
    const simp = m[2];
    const py = normPinyin(m[3]);
    const raw = m[4].split('/');
    const meanings = cleanMeanings(raw);
    if (meanings.length) {
      byKey.set(simp + '|' + py, meanings);
      if (!bySimp.has(simp)) bySimp.set(simp, meanings);
    } else {
      const tgt = redirectTarget(raw);
      if (tgt && !redirect.has(simp)) redirect.set(simp, tgt);
    }
  }
  return { byKey, bySimp, redirect };
}
// Tìm nghĩa Việt với dự phòng: trực tiếp -> theo redirect -> bỏ đuôi 儿
function resolveVi(simp, py, cv) {
  let r = cv.byKey.get(simp + '|' + py) || cv.bySimp.get(simp);
  if (r && r.length) return r;
  const tgt = cv.redirect.get(simp);
  if (tgt) { r = cv.byKey.get(tgt + '|' + py) || cv.bySimp.get(tgt); if (r && r.length) return r; }
  if (/[儿兒]$/.test(simp)) {
    const base = simp.replace(/[儿兒]$/, '');
    r = cv.bySimp.get(base) || cv.byKey.get(base + '|' + py.replace(/r5?$/, ''));
    if (r && r.length) return r;
    const bt = cv.redirect.get(base);
    if (bt) { r = cv.bySimp.get(bt); if (r && r.length) return r; }
  }
  return [];
}

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

// ---------- CHỌN FORM đúng cho chữ đa âm ----------
// "Redirect" = form chỉ trỏ tới chữ khác / là họ / biến thể / đọc vùng-Đài: NGHĨA CHÍNH dính.
const REDIRECT = /^(variant of|old variant|see\s|used in|surname|abbr|\(tw\)|\(taiwan|\(dialect\)|\(coll\.?\)|erhua|used as)/i;
function isCap(py) { return /[A-Z]/.test(py || ''); }
function formPenalty(form) {
  const primary = ((form.meanings || [])[0] || '').trim();
  let pen = 0;
  if (!primary) pen += 200;             // không có nghĩa
  if (REDIRECT.test(primary)) pen += 100; // nghĩa chính chỉ là trỏ/họ/biến thể
  if (isCap(form.transcriptions.pinyin)) pen += 60; // pinyin hoa = danh từ riêng/họ
  return pen;
}
function pickForm(entry) {
  const forms = entry.forms;
  const ov = OVERRIDE_READING[entry.simplified];
  if (ov) {
    const f = forms.find(f => normPinyin(f.transcriptions.numeric) === normPinyin(ov));
    if (f) return f;
  }
  let best = forms[0], bestPen = formPenalty(forms[0]);
  forms.forEach(f => {
    const pen = formPenalty(f);
    if (pen < bestPen) { best = f; bestPen = pen; }
  });
  return best;
}
// Nghi ngờ CHỌN NHẦM thật sự (để rà tay): pinyin hoa mà CÓ form thường khác hợp lệ,
// hoặc không còn nghĩa nào cả. ((coll.)/erhua/biến-thể-đã-resolve coi như hợp lệ.)
const HARD_REDIRECT = /^(variant of|old variant|see\s|surname)/i;
function stillSuspicious(entry, chosen, viText) {
  const primary = ((chosen.meanings || [])[0] || '').trim();
  if (!primary && !viText) return true;            // không có dữ liệu nghĩa
  if (isCap(chosen.transcriptions.pinyin)) {       // danh từ riêng -> có thể nhầm họ
    return entry.forms.some(f => f !== chosen && !isCap(f.transcriptions.pinyin)
      && !HARD_REDIRECT.test((f.meanings || [])[0] || ''));
  }
  return false;
}

function hanvietPerChar(simp, trad, numericPinyin, hv) {
  const s = [...simp], t = [...trad];
  const syl = (numericPinyin || '').toLowerCase().trim().split(/\s+/);
  const aligned = syl.length === s.length;
  return s.map((sc, i) => {
    const tc = t[i] || sc;
    const py = aligned ? syl[i] : null;
    return (py && hv.byCharPy.get(tc + '|' + py)) || (py && hv.byCharPy.get(sc + '|' + py)) ||
      hv.byChar.get(tc) || hv.byChar.get(sc) || SUPPLEMENT_HV[tc] || SUPPLEMENT_HV[sc] || '?';
  });
}

// nghĩa Việt ngắn gọn cho 1 chữ đơn
function charMeaning(ch, sylNum, cv) {
  const m = (sylNum && cv.byKey.get(ch + '|' + normPinyin(sylNum))) || cv.bySimp.get(ch);
  if (!m || !m.length) return '';
  return m[0].split(/[;,]/)[0].trim(); // lấy nghĩa đầu, ngắn
}

function build(level, hv, cv, stats) {
  const src = JSON.parse(fs.readFileSync(path.join(SRC, `hsk_old_${level}.json`), 'utf8'));
  const cards = src.map((e, i) => {
    const form = pickForm(e);
    const tr = form.transcriptions;
    const simp = e.simplified;
    const trad = form.traditional || simp;
    const py = normPinyin(tr.numeric || tr.pinyin);
    let vi = resolveVi(simp, py, cv);
    if (!vi.length && SUPPLEMENT_VI[simp]) vi = [SUPPLEMENT_VI[simp]];
    const hvArr = hanvietPerChar(simp, trad, tr.numeric, hv);
    const sylTone = (tr.pinyin || '').trim().split(/\s+/);
    const sylNum = (tr.numeric || '').trim().split(/\s+/);
    const aligned = sylTone.length === [...simp].length;
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
      meaning_en: cleanMeanings(form.meanings || []).join('; '),
      hanviet: hvArr.join(' '),
      distractor_group: posGroup(e.pos),
      audio: `hsk${level}/hsk${level}-${String(i + 1).padStart(4, '0')}.mp3`,
    };
    if ([...simp].length > 1) {
      card.chars = [...simp].map((ch, k) => ({
        char: ch,
        reading: aligned ? sylTone[k] : '',
        hanviet: hvArr[k],
        meaning_vi: charMeaning(ch, aligned ? sylNum[k] : null, cv),
      }));
    }
    // thống kê rủi ro để rà lần 2 (chỉ ca có khả năng chọn nhầm thật sự)
    if (stillSuspicious(e, form, card.meaning_vi)) stats.suspicious.push(`${card.id} ${simp} [${tr.pinyin}] vi="${card.meaning_vi.slice(0, 35)}"`);
    return card;
  });
  fs.writeFileSync(path.join(OUT, `hsk${level}.json`), JSON.stringify({
    code: `HSK${level}`, title_vi: `HSK ${level}`, version: 1, lessonSize: 20,
    _warning: 'Sinh tu nguon mo. verified=false. meaning_vi (CVDICT, AI dich) + hanviet (chon theo pinyin) CAN ra soat. Xem CREDITS.md.',
    _sources: {
      wordlist: 'drkameleon/complete-hsk-vocabulary (MIT)',
      meaning_vi: 'CVDICT - Phong Phan (CC-BY-SA 4.0)',
      hanviet: 'ph0ngp/hanviet-pinyin-wordlist (MIT) + Unihan kVietnamese',
    },
    cards,
  }, null, 2) + '\n');
  const missVi = cards.filter(c => !c.meaning_vi).length;
  const missHv = cards.filter(c => c.hanviet.includes('?')).length;
  console.log(`HSK${level}: ${cards.length} | thiếu_vi:${missVi} thiếu_hv:${missHv}`);
}

const hv = loadHanViet();
const cv = loadCvdict();
const stats = { suspicious: [] };
console.log(`Hán Việt chars: ${hv.byChar.size} | CVDICT keys: ${cv.byKey.size}`);
for (const lv of [3, 4, 5, 6]) build(lv, hv, cv, stats);
console.log(`\nForm còn nghi ngờ (marker/pinyin hoa) sau khi sửa: ${stats.suspicious.length}`);
stats.suspicious.slice(0, 40).forEach(s => console.log('  ?', s));
console.log('Done.');

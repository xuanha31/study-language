import 'package:flutter/material.dart';

/// Giới thiệu & ghi công nguồn dữ liệu (E1-11). Bắt buộc hiển thị để tuân thủ
/// giấy phép — đặc biệt `meaning_vi` từ CVDICT (CC-BY-SA 4.0, share-alike).
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _sources = [
    ('Từ vựng, pinyin, nghĩa Anh (tham chiếu)', 'complete-hsk-vocabulary — Yanis Zafirópulos', 'MIT'),
    ('Nghĩa tiếng Việt (meaning_vi)', 'CVDICT — Phong Phan', 'CC-BY-SA 4.0'),
    ('Âm Hán Việt (hanviet)', 'hanviet-pinyin-wordlist — Phong Phan', 'MIT'),
    ('Hán Việt (dự phòng)', 'Unihan Database (kVietnamese) — Unicode, Inc.', 'Unicode License'),
    ('Nghĩa Anh gốc', 'CC-CEDICT — MDBG', 'CC-BY-SA 3.0'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu & nguồn dữ liệu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Học tiếng Trung 🀄',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Game học tiếng Trung kiểu Mario — học là chính, game là động lực.'),
          const SizedBox(height: 20),
          Text('Nguồn dữ liệu nội dung',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._sources.map((s) => Card(
                child: ListTile(
                  title: Text(s.$1),
                  subtitle: Text(s.$2),
                  trailing: Text(s.$3, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ghi chú giấy phép',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Nghĩa tiếng Việt (meaning_vi) lấy từ CVDICT (CC-BY-SA 4.0) — '
                      'giấy phép "chia sẻ tương tự": phải ghi công tác giả và chia sẻ lại '
                      'phần dữ liệu nghĩa Việt cùng giấy phép CC-BY-SA 4.0.'),
                  SizedBox(height: 6),
                  Text('• Các nguồn MIT/Unicode chỉ yêu cầu giữ thông báo bản quyền.'),
                  SizedBox(height: 6),
                  Text('[Lưu ý — không phải tư vấn pháp lý] Nếu thương mại hóa, nên hỏi '
                      'ý kiến pháp lý về ràng buộc share-alike.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '⚠️ Dữ liệu nội dung hiện CHƯA được kiểm chứng (verified:false) — '
            'pinyin/nghĩa/Hán Việt có thể có sai sót, đang chờ rà soát.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

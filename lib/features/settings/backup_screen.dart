import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/progress_repository.dart';
import '../../data/settings_repository.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../logic/sync/backup_data.dart';
import '../../logic/sync/drive_sync.dart';
import '../../logic/sync/local_backup.dart';
import '../../logic/sync/sync_service.dart';

/// Sao lưu & khôi phục (E6): snapshot local + chia sẻ/nhập file + (Drive khi cấu hình).
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final LocalBackupService _local = LocalBackupService();
  List<Snapshot> _snaps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final snaps = await _local.list();
    if (!mounted) return;
    setState(() {
      _snaps = snaps;
      _loading = false;
    });
  }

  String _encode() {
    return BackupData.encode(
      progress: context.read<ProgressRepository>(),
      settings: context.read<SettingsRepository>(),
      createdAtIso: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _createBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    await _local.create(_encode());
    await _refresh();
    messenger.showSnackBar(const SnackBar(content: Text('Đã tạo bản sao lưu')));
  }

  Future<void> _share() async {
    await _local.share(_encode());
  }

  Future<void> _importFromFile() async {
    final messenger = ScaffoldMessenger.of(context);
    final json = await _local.importFromFile();
    if (json == null) return;
    await _restoreJson(json);
    messenger.showSnackBar(const SnackBar(content: Text('Đã khôi phục từ file')));
  }

  Future<void> _restoreSnapshot(Snapshot s) async {
    final messenger = ScaffoldMessenger.of(context);
    final json = await _local.restore(s.id);
    await _restoreJson(json);
    messenger.showSnackBar(const SnackBar(content: Text('Đã khôi phục bản sao lưu')));
  }

  /// Khôi phục có cảnh báo ghi đè (design.md §8).
  Future<void> _restoreJson(String json) async {
    final ok = await _confirmOverwrite();
    if (!ok || !mounted) return;
    await BackupData.restore(
      json,
      progress: context.read<ProgressRepository>(),
      settings: context.read<SettingsCubit>(),
    );
  }

  Future<bool> _confirmOverwrite() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: const Text(
            'Toàn bộ tiến độ HIỆN TẠI sẽ bị thay bằng dữ liệu trong bản sao lưu. '
            'Hành động này không hoàn tác được.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Khôi phục')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteSnapshot(Snapshot s) async {
    await _local.delete(s.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu & khôi phục')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBackup,
        icon: const Icon(Icons.backup),
        label: const Text('Tạo bản sao lưu'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Nhập từ file'),
                  subtitle: const Text('Khôi phục từ file .json đã chia sẻ'),
                  onTap: _importFromFile,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Bản sao lưu trên máy (${_snaps.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (_snaps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chưa có bản sao lưu nào.', style: TextStyle(color: Colors.black54)),
                  ),
                ..._snaps.map((s) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(_fmt(s.createdAt)),
                      subtitle: Text('${(s.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'restore') _restoreSnapshot(s);
                          if (v == 'delete') _deleteSnapshot(s);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'restore', child: Text('Khôi phục')),
                          PopupMenuItem(value: 'delete', child: Text('Xóa')),
                        ],
                      ),
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('Chia sẻ bản sao lưu'),
                  subtitle: const Text('Gửi file ra ngoài (Drive/email/...) để lưu trữ'),
                  onTap: _share,
                ),
                const Divider(),
                const _DriveSection(),
              ],
            ),
    );
  }

  static String _fmt(DateTime t) {
    final d = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

/// Mục Google Drive — hiển thị trạng thái cấu hình (E6 cần OAuth client của bạn).
class _DriveSection extends StatelessWidget {
  const _DriveSection();

  @override
  Widget build(BuildContext context) {
    if (!kDriveConfigured) {
      return const ListTile(
        leading: Icon(Icons.cloud_off),
        title: Text('Đồng bộ Google Drive'),
        subtitle: Text('Cần cấu hình OAuth client (google-services.json + SHA-1). '
            'Bật cờ kDriveConfigured trong drive_sync.dart sau khi cấu hình.'),
        enabled: false,
      );
    }
    return ListTile(
      leading: const Icon(Icons.cloud),
      title: const Text('Đăng nhập Google Drive'),
      subtitle: const Text('Sao lưu/đồng bộ lên Drive (AppData)'),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await DriveSyncService().signIn();
        messenger.showSnackBar(
          SnackBar(content: Text(ok ? 'Đã đăng nhập Drive' : 'Đăng nhập thất bại')),
        );
      },
    );
  }
}

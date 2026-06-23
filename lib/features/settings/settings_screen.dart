import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/game_speed.dart';
import '../../data/content_repository.dart';
import '../../data/settings_repository.dart';
import '../../logic/audio_service.dart';
import '../../logic/notification_service.dart';
import '../../logic/question_type.dart';
import '../../logic/settings/settings_cubit.dart';
import 'backup_screen.dart';
import 'credits_screen.dart';

/// Màn cài đặt (E9-2): tốc độ, dạng câu hỏi (gồm chiều Việt↔Trung), âm thanh, nhắc học.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, s) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            children: [
              const _SectionTitle('Tốc độ chơi'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<GameSpeed>(
                  segments: const [
                    ButtonSegment(value: GameSpeed.slow, label: Text('Chậm')),
                    ButtonSegment(value: GameSpeed.medium, label: Text('Vừa')),
                    ButtonSegment(value: GameSpeed.fast, label: Text('Nhanh')),
                  ],
                  selected: {s.speed},
                  onSelectionChanged: (sel) => cubit.setSpeed(sel.first),
                ),
              ),
              const Divider(),
              const _SectionTitle('Dạng câu hỏi'),
              for (final t in QuestionType.values)
                SwitchListTile(
                  title: Text(t.labelVi),
                  subtitle: t.needsAudio
                      ? const Text('Cần giọng đọc (TTS) tiếng Trung')
                      : null,
                  value: s.enabledTypes.contains(t),
                  onChanged: (v) => cubit.toggleType(t, v),
                ),
              const Divider(),
              const _SectionTitle('Âm thanh'),
              SwitchListTile(
                title: const Text('Phát âm (TTS)'),
                value: s.audioEnabled,
                onChanged: (v) => cubit.setAudioEnabled(v),
              ),
              ListTile(
                leading: const Icon(Icons.record_voice_over),
                title: const Text('Chuẩn bị giọng đọc'),
                subtitle: const Text('Kiểm tra máy có giọng tiếng Trung'),
                onTap: () => _prepareVoices(context),
              ),
              const Divider(),
              const _SectionTitle('Nhắc học'),
              SwitchListTile(
                title: const Text('Nhắc học hằng ngày'),
                value: s.reminderEnabled,
                onChanged: (v) => _toggleReminder(context, v),
              ),
              ListTile(
                enabled: s.reminderEnabled,
                leading: const Icon(Icons.schedule),
                title: const Text('Giờ nhắc'),
                trailing: Text(
                  '${s.reminderHour.toString().padLeft(2, '0')}:'
                  '${s.reminderMinute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: s.reminderEnabled ? () => _pickTime(context, s) : null,
              ),
              const Divider(),
              const _SectionTitle('Dữ liệu'),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Sao lưu & khôi phục'),
                subtitle: const Text('Snapshot tiến độ, chia sẻ/nhập file, Google Drive'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('Cập nhật nội dung'),
                subtitle: const Text('Tải bản nội dung mới từ server (nếu đã cấu hình)'),
                onTap: () => _updateContent(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Giới thiệu & nguồn dữ liệu'),
                subtitle: const Text('Ghi công + giấy phép (CC-BY-SA cho nghĩa tiếng Việt)'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreditsScreen()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateContent(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<ContentRepository>();
    messenger.showSnackBar(const SnackBar(content: Text('Đang kiểm tra cập nhật...')));
    try {
      final n = await repo.checkAndUpdate();
      messenger.showSnackBar(SnackBar(
        content: Text(n > 0
            ? 'Đã cập nhật $n khóa nội dung'
            : 'Nội dung đã mới nhất (hoặc chưa cấu hình server)'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
    }
  }

  Future<void> _prepareVoices(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AudioService>().prepareVoices();
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Đã sẵn sàng giọng tiếng Trung 🔊'
          : 'Máy chưa có giọng tiếng Trung — hãy cài TTS tiếng Trung trong cài đặt hệ thống'),
    ));
  }

  Future<void> _toggleReminder(BuildContext context, bool enabled) async {
    final cubit = context.read<SettingsCubit>();
    final notif = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    if (enabled) {
      final granted = await notif.requestPermissions();
      await cubit.setReminder(enabled: true);
      if (granted) {
        await notif.scheduleDaily(cubit.state.reminderHour, cubit.state.reminderMinute);
      } else {
        messenger.showSnackBar(const SnackBar(
          content: Text('Chưa cấp quyền thông báo — bật trong cài đặt hệ thống'),
        ));
      }
    } else {
      await cubit.setReminder(enabled: false);
      await notif.cancelAll();
    }
  }

  Future<void> _pickTime(BuildContext context, AppSettings s) async {
    final cubit = context.read<SettingsCubit>();
    final notif = context.read<NotificationService>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute),
    );
    if (picked == null) return;
    await cubit.setReminder(enabled: s.reminderEnabled, hour: picked.hour, minute: picked.minute);
    if (s.reminderEnabled) await notif.scheduleDaily(picked.hour, picked.minute);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

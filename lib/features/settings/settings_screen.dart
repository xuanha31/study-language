import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const SectionLabel('Vòng chơi'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Tốc độ mặc định',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SpeedSelector(value: s.speed, onChanged: cubit.setSpeed),
                    ],
                  ),
                ),
              ),
              const SectionLabel('Dạng câu hỏi'),
              _Group(children: [
                for (final t in QuestionType.values)
                  SwitchListTile(
                    title: Text(t.labelVi, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: t.needsAudio
                        ? const Text('Cần giọng đọc (TTS) tiếng Trung')
                        : null,
                    value: s.enabledTypes.contains(t),
                    onChanged: (v) => cubit.toggleType(t, v),
                  ),
              ]),
              const SectionLabel('Âm thanh & nhắc học'),
              _Group(children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined),
                  title: const Text('Phát âm (TTS)', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: s.audioEnabled,
                  onChanged: (v) => cubit.setAudioEnabled(v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note_outlined),
                  title: const Text('Hiệu ứng âm thanh & rung',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  value: s.sfxEnabled,
                  onChanged: (v) => cubit.setSfxEnabled(v),
                ),
                ListTile(
                  leading: const Icon(Icons.mic_none_rounded),
                  title: const Text('Chuẩn bị giọng đọc',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Kiểm tra máy có giọng tiếng Trung'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                  onTap: () => _prepareVoices(context),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Nhắc học hằng ngày',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  value: s.reminderEnabled,
                  onChanged: (v) => _toggleReminder(context, v),
                ),
                ListTile(
                  enabled: s.reminderEnabled,
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Giờ nhắc', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: s.reminderEnabled ? AppColors.cinnabarSoft : AppColors.track,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${s.reminderHour.toString().padLeft(2, '0')}:'
                      '${s.reminderMinute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: s.reminderEnabled ? AppColors.cinnabarDeep : AppColors.inkMuted,
                      ),
                    ),
                  ),
                  onTap: s.reminderEnabled ? () => _pickTime(context, s) : null,
                ),
              ]),
              const SectionLabel('Dữ liệu'),
              _Group(children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Sao lưu & khôi phục',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Snapshot tiến độ, chia sẻ/nhập file, Google Drive'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Cập nhật nội dung',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Tải bản nội dung mới từ server (nếu đã cấu hình)'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                  onTap: () => _updateContent(context),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Giới thiệu & nguồn dữ liệu',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Ghi công + giấy phép (CC-BY-SA cho nghĩa tiếng Việt)'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreditsScreen()),
                  ),
                ),
              ]),
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
          ? 'Đã sẵn sàng giọng tiếng Trung'
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

/// Nhóm các dòng cài đặt trong một thẻ, có đường kẻ mảnh giữa các dòng.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

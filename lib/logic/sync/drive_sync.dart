import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'sync_service.dart';

/// CỜ cấu hình: bật `true` SAU KHI đã tạo OAuth client trên Google Cloud Console
/// (google-services.json + SHA-1 cho Android; clientId trong Info.plist cho iOS).
/// Khi `false`, UI hiển thị "cần cấu hình" và không gọi đăng nhập.
const bool kDriveConfigured = false;

/// Đồng bộ qua Google Drive AppData (E6, design.md §8). Mỗi snapshot là 1 file
/// JSON trong thư mục ẩn `appDataFolder` của ứng dụng. Cần đăng nhập Google.
///
/// Lưu ý: code đã đầy đủ nhưng chỉ chạy được khi [kDriveConfigured] = true và đã
/// cấu hình OAuth client — không thể tự cấu hình thay người dùng.
class DriveSyncService implements SyncService {
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: const [drive.DriveApi.driveAppdataScope]);

  @override
  Future<bool> isAvailable() async => kDriveConfigured;

  Future<bool> get isSignedIn async => _googleSignIn.currentUser != null;

  /// Đăng nhập tường minh (nút "Đăng nhập Google Drive").
  Future<bool> signIn() async => (await _googleSignIn.signIn()) != null;

  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _api() async {
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) throw StateError('Chưa đăng nhập Google');
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) throw StateError('Không lấy được phiên xác thực');
    return drive.DriveApi(client);
  }

  @override
  Future<List<Snapshot>> list() async {
    final api = await _api();
    final res = await api.files.list(
      spaces: 'appDataFolder',
      $fields: 'files(id,name,modifiedTime,size)',
      orderBy: 'modifiedTime desc',
    );
    return [
      for (final f in res.files ?? <drive.File>[])
        Snapshot(
          id: f.id ?? '',
          createdAt: f.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0),
          sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
        ),
    ];
  }

  @override
  Future<Snapshot> create(String json, {int keepLatest = 10}) async {
    final api = await _api();
    final bytes = utf8.encode(json);
    final meta = drive.File(
      name: 'backup-${DateTime.now().millisecondsSinceEpoch}.json',
      parents: ['appDataFolder'],
    );
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final created = await api.files.create(meta, uploadMedia: media);
    await _prune(api, keepLatest);
    return Snapshot(
      id: created.id ?? '',
      createdAt: created.modifiedTime ?? DateTime.now(),
      sizeBytes: bytes.length,
    );
  }

  @override
  Future<String> restore(String id) async {
    final api = await _api();
    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = <int>[];
    await for (final c in media.stream) {
      chunks.addAll(c);
    }
    return utf8.decode(chunks);
  }

  @override
  Future<void> delete(String id) async {
    final api = await _api();
    await api.files.delete(id);
  }

  Future<void> _prune(drive.DriveApi api, int keep) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      $fields: 'files(id,modifiedTime)',
      orderBy: 'modifiedTime desc',
    );
    for (final f in (res.files ?? <drive.File>[]).skip(keep)) {
      if (f.id != null) await api.files.delete(f.id!);
    }
  }
}

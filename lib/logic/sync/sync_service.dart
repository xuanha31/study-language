/// Một bản sao lưu (snapshot) có nhãn thời gian.
class Snapshot {
  final String id; // định danh (tên file / id trên Drive)
  final DateTime createdAt;
  final int sizeBytes;
  const Snapshot({required this.id, required this.createdAt, this.sizeBytes = 0});
}

/// Giao diện đồng bộ/sao lưu (E6). Có 2 hiện thực: local file & Google Drive.
/// Kiểu snapshot độc lập + nhãn thời gian -> né bài toán merge (xem design.md §8).
abstract class SyncService {
  /// Đã sẵn sàng dùng chưa (vd Drive cần đăng nhập/cấu hình).
  Future<bool> isAvailable();

  /// Liệt kê các bản sao lưu, mới nhất trước.
  Future<List<Snapshot>> list();

  /// Tạo bản sao lưu mới từ [json]; tự dọn để giữ tối đa [keepLatest] bản.
  Future<Snapshot> create(String json, {int keepLatest = 10});

  /// Đọc nội dung JSON của một bản.
  Future<String> restore(String id);

  /// Xóa một bản.
  Future<void> delete(String id);
}

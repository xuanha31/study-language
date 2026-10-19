/// Danh mục cửa hàng nấm (chỉ đồ trang trí — không bán lợi thế trong vòng chơi,
/// để cơ chế mạng/thua vẫn giữ nguyên). Sprite: Kenney "New Platformer Pack" (CC0).
///
/// Mỗi món kèm một từ tiếng Trung (màu sắc / địa hình) để vừa mua vừa học.
enum ShopKind { character, scene }

class ShopItem {
  final ShopKind kind;
  final String id;
  final String nameVi;
  final String hanzi;
  final String pinyin;
  final int price; // 0 = có sẵn
  final String preview; // ảnh trong cửa hàng (đường dẫn asset đầy đủ)

  const ShopItem({
    required this.kind,
    required this.id,
    required this.nameVi,
    required this.hanzi,
    required this.pinyin,
    required this.price,
    required this.preview,
  });

  /// Khóa lưu trong AppSettings.ownedItems.
  String get key => '${kind.name}:$id';
}

/// Thông số cảnh chơi theo phong cảnh: nền, địa hình, bộ quái thường.
class SceneStyle {
  final String background; // kenney/backgrounds/<id>.png
  final String terrain; // kenney/tiles/terrain_<terrain>_{top,center}.png
  final List<String> enemies; // kenney/enemies/<name>_walk_{a,b}.png
  const SceneStyle(this.background, this.terrain, this.enemies);
}

class ShopCatalog {
  static const _c = 'assets/images/kenney/characters';
  static const _b = 'assets/images/kenney/backgrounds';

  static const characters = [
    ShopItem(kind: ShopKind.character, id: 'beige', nameVi: 'Phi hành gia Cát', hanzi: '米色',
        pinyin: 'mǐsè', price: 0, preview: '$_c/beige_preview.png'),
    ShopItem(kind: ShopKind.character, id: 'green', nameVi: 'Lục Bảo', hanzi: '绿色',
        pinyin: 'lǜsè', price: 40, preview: '$_c/green_preview.png'),
    ShopItem(kind: ShopKind.character, id: 'pink', nameVi: 'Hồng Đào', hanzi: '粉色',
        pinyin: 'fěnsè', price: 80, preview: '$_c/pink_preview.png'),
    ShopItem(kind: ShopKind.character, id: 'purple', nameVi: 'Tử Tinh', hanzi: '紫色',
        pinyin: 'zǐsè', price: 120, preview: '$_c/purple_preview.png'),
    ShopItem(kind: ShopKind.character, id: 'yellow', nameVi: 'Hoàng Kim', hanzi: '黄色',
        pinyin: 'huángsè', price: 200, preview: '$_c/yellow_preview.png'),
  ];

  static const scenes = [
    ShopItem(kind: ShopKind.scene, id: 'hills', nameVi: 'Đồi xanh', hanzi: '山丘',
        pinyin: 'shānqiū', price: 0, preview: '$_b/hills.png'),
    ShopItem(kind: ShopKind.scene, id: 'trees', nameVi: 'Rừng cây', hanzi: '森林',
        pinyin: 'sēnlín', price: 60, preview: '$_b/trees.png'),
    ShopItem(kind: ShopKind.scene, id: 'mushrooms', nameVi: 'Rừng nấm', hanzi: '蘑菇',
        pinyin: 'mógu', price: 120, preview: '$_b/mushrooms.png'),
    ShopItem(kind: ShopKind.scene, id: 'desert', nameVi: 'Sa mạc', hanzi: '沙漠',
        pinyin: 'shāmò', price: 180, preview: '$_b/desert.png'),
  ];

  static const _styles = {
    'hills': SceneStyle('hills', 'grass', ['slime_normal', 'slime_spike']),
    'trees': SceneStyle('trees', 'grass', ['snail', 'ladybug']),
    'mushrooms': SceneStyle('mushrooms', 'dirt', ['mouse', 'slime_spike']),
    'desert': SceneStyle('desert', 'sand', ['slime_fire', 'snail']),
  };

  static SceneStyle styleOf(String scene) => _styles[scene] ?? _styles['hills']!;

  static String characterOf(String id) =>
      characters.any((c) => c.id == id) ? id : characters.first.id;
}

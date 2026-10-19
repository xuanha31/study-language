import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:study_language/data/settings_repository.dart';
import 'package:study_language/logic/settings/settings_cubit.dart';
import 'package:study_language/logic/shop/shop_catalog.dart';

void main() {
  late Directory dir;
  late SettingsCubit cubit;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('shop_test');
    Hive.init(dir.path);
    cubit = SettingsCubit(await SettingsRepository.open());
  });

  tearDown(() async {
    await cubit.close();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  final green = ShopCatalog.characters.firstWhere((c) => c.id == 'green');
  final beige = ShopCatalog.characters.first;

  test('Mặc định: có sẵn món miễn phí, đang dùng beige + hills', () {
    expect(cubit.owns(beige), isTrue);
    expect(cubit.isEquipped(beige), isTrue);
    expect(cubit.isEquipped(ShopCatalog.scenes.first), isTrue);
    expect(cubit.owns(green), isFalse);
  });

  test('Không đủ nấm thì không mua được', () async {
    await cubit.depositMushrooms(green.price - 1);
    expect(await cubit.buy(green), isFalse);
    expect(cubit.state.mushroomBank, green.price - 1);
    expect(cubit.owns(green), isFalse);
  });

  test('Mua: trừ nấm, sở hữu, dùng luôn; không mua lại lần 2', () async {
    await cubit.depositMushrooms(green.price + 5);
    expect(await cubit.buy(green), isTrue);
    expect(cubit.state.mushroomBank, 5);
    expect(cubit.owns(green), isTrue);
    expect(cubit.state.character, 'green');
    expect(await cubit.buy(green), isFalse);
    expect(cubit.state.mushroomBank, 5);

    await cubit.equip(beige);
    expect(cubit.state.character, 'beige');
    await cubit.equip(green);
    expect(cubit.state.character, 'green');
  });

  test('Đồ đã mua được lưu (và đi theo bản sao lưu settings)', () async {
    await cubit.depositMushrooms(500);
    final desert = ShopCatalog.scenes.last;
    await cubit.buy(desert);
    final restored = AppSettings.fromMap(cubit.state.toMap());
    expect(restored.ownedItems, contains(desert.key));
    expect(restored.scene, desert.id);
    expect(restored.mushroomBank, 500 - desert.price);
  });

  test('Không dùng được món chưa mua', () async {
    await cubit.equip(green);
    expect(cubit.state.character, 'beige');
  });

  test('Mọi món trong catalog có ảnh xem trước tồn tại', () {
    for (final it in [...ShopCatalog.characters, ...ShopCatalog.scenes]) {
      expect(File(it.preview).existsSync(), isTrue, reason: it.preview);
    }
  });

  test('Mỗi phong cảnh có đủ sprite nền, địa hình, quái', () {
    const base = 'assets/images/kenney';
    for (final sc in ShopCatalog.scenes) {
      final st = ShopCatalog.styleOf(sc.id);
      final files = [
        '$base/backgrounds/${st.background}.png',
        '$base/tiles/terrain_${st.terrain}_top.png',
        '$base/tiles/terrain_${st.terrain}_center.png',
        for (final e in st.enemies) ...['$base/enemies/${e}_walk_a.png', '$base/enemies/${e}_walk_b.png'],
      ];
      for (final f in files) {
        expect(File(f).existsSync(), isTrue, reason: f);
      }
    }
  });
}

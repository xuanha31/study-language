import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/settings_repository.dart';
import '../../logic/audio_service.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../logic/sfx_service.dart';
import '../../logic/shop/shop_catalog.dart';

/// Cửa hàng nấm: đổi nấm tích lũy lấy nhân vật / phong cảnh cho cảnh chơi.
/// Chỉ đồ trang trí — không bán mạng hay lợi thế, nên độ khó vòng chơi giữ nguyên.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa hàng'),
        actions: [
          BlocBuilder<SettingsCubit, AppSettings>(
            builder: (context, s) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _Wallet(amount: s.mushroomBank),
            ),
          ),
        ],
      ),
      body: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, s) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  MushroomIcon(size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mỗi câu đúng được 1 nấm; nấm còn lại cuối vòng vào ví. '
                      'Đồ ở đây chỉ để trang trí — không làm vòng chơi dễ hơn.',
                      style: TextStyle(fontSize: 13, color: AppColors.goldInk, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('Nhân vật'),
            _Grid(items: ShopCatalog.characters, settings: s, aspect: 0.72),
            const SectionLabel('Phong cảnh'),
            _Grid(items: ShopCatalog.scenes, settings: s, aspect: 0.82),
          ],
        ),
      ),
    );
  }
}

class _Wallet extends StatelessWidget {
  final int amount;
  const _Wallet({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ví $amount nấm',
      excludeSemantics: true,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cinnabarSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MushroomIcon(size: 18),
            const SizedBox(width: 4),
            Text(fmtNum(amount),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.cinnabarDeep)),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<ShopItem> items;
  final AppSettings settings;
  final double aspect;
  const _Grid({required this.items, required this.settings, required this.aspect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: aspect,
      children: [for (final it in items) _ItemCard(item: it)],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ShopItem item;
  const _ItemCard({required this.item});

  Future<void> _buy(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final sfx = context.read<SfxService>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mua ${item.nameVi}?'),
        content: Text('Dùng ${item.price} nấm trong ví (còn ${cubit.state.mushroomBank}). '
            'Mua xong sẽ dùng luôn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Thôi')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mua')),
        ],
      ),
    );
    if (ok != true) return;
    if (await cubit.buy(item)) {
      sfx.play(Sfx.powerup);
      messenger.showSnackBar(SnackBar(content: Text('Đã mua và đang dùng: ${item.nameVi}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final owned = cubit.owns(item);
    final equipped = cubit.isEquipped(item);
    final bank = cubit.state.mushroomBank;
    final isScene = item.kind == ShopKind.scene;

    final Widget action;
    if (equipped) {
      action = FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          disabledBackgroundColor: AppColors.jadeSoft,
          disabledForegroundColor: AppColors.jade,
        ),
        child: const FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.check_rounded, size: 18), SizedBox(width: 4), Text('Đang dùng')],
          ),
        ),
      );
    } else if (owned) {
      action = OutlinedButton(onPressed: () => cubit.equip(item), child: const Text('Dùng'));
    } else if (bank >= item.price) {
      action = FilledButton(
        onPressed: () => _buy(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // nền tròn sáng để nấm đỏ không chìm vào nút đỏ
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
              child: const MushroomIcon(size: 16),
            ),
            const SizedBox(width: 6),
            Text('${item.price}'),
          ],
        ),
      );
    } else {
      action = OutlinedButton(
        onPressed: null,
        child: FittedBox(child: Text('Thiếu ${item.price - bank} nấm')),
      );
    }

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: equipped ? AppColors.jade : AppColors.line, width: equipped ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: isScene ? null : const Color(0xFFDDEFFF),
              padding: isScene ? EdgeInsets.zero : const EdgeInsets.all(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isScene)
                    _ScenePreview(item: item)
                  else
                    Image.asset(item.preview, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                  if (!owned)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.lock_rounded, size: 18, color: AppColors.inkSoft),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(item.nameVi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.read<AudioService>().speak(item.hanzi),
                  child: Row(
                    children: [
                      Text(item.hanzi, style: AppText.hanzi(17, color: AppColors.cinnabarDeep)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(item.pinyin,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.volume_up_rounded, size: 15, color: AppColors.inkMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(height: 40, child: action),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh thu nhỏ của cảnh chơi: trời + nền + dải đất + một con quái của phong cảnh.
class _ScenePreview extends StatelessWidget {
  final ShopItem item;
  const _ScenePreview({required this.item});

  @override
  Widget build(BuildContext context) {
    const k = 'assets/images/kenney';
    final style = ShopCatalog.styleOf(item.id);
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB9DDF6), Colors.white],
            ),
          ),
        ),
        // Phần giữa ảnh nền có đặc trưng (cây, nấm, xương rồng).
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          top: 0,
          child: Image.asset(item.preview,
              fit: BoxFit.cover, alignment: const Alignment(0, 0.25), filterQuality: FilterQuality.medium),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 22,
          child: Image.asset('$k/tiles/terrain_${style.terrain}_top.png',
              repeat: ImageRepeat.repeatX, fit: BoxFit.fitHeight, filterQuality: FilterQuality.medium),
        ),
        Positioned(
          right: 12,
          bottom: 18,
          height: 30,
          child: Image.asset('$k/enemies/${style.enemies.first}_walk_a.png',
              filterQuality: FilterQuality.medium),
        ),
      ],
    );
  }
}

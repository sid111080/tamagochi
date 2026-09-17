import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/purchase.dart';
import '../../core/services/purchase_service.dart';
import '../../core/services/wallet_service.dart';

/// Вкладка «Покупки» (ТЗ §8.6): 8 товаров двух типов — обязательные
/// (питомцу нужно) и необязательные (приятности).
///
/// Перед покупкой — цена, категория и влияние на питомца; подтверждение;
/// при нехватке средств — объяснение и варианты, без отрицательного баланса.
class PurchasesTab extends StatelessWidget {
  const PurchasesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PurchaseService>();
    final wallet = context.watch<WalletService>();
    final balance = wallet.balance;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Заголовок + доступный баланс.
        Row(
          children: [
            const Text(
              'Покупки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.coin.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$balance',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Выбери заботу или подарок. Перед покупкой покажем цену, '
          'категорию и влияние на питомца.',
          style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        _Section(
          title: PurchaseCategory.required.shortLabel,
          emoji: PurchaseCategory.required.emoji,
          color: AppColors.leaf,
          items: service.required,
          balance: balance,
          onBuy: (product) => _confirmBuy(context, service, product, balance),
        ),
        const SizedBox(height: 20),
        _Section(
          title: PurchaseCategory.optional.shortLabel,
          emoji: PurchaseCategory.optional.emoji,
          color: AppColors.grape,
          items: service.optional,
          balance: balance,
          onBuy: (product) => _confirmBuy(context, service, product, balance),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Диалог-подтверждение покупки (ТЗ §8.6): цена, категория, влияние,
  /// остаток; при нехватке — объяснение и варианты.
  void _confirmBuy(
    BuildContext context,
    PurchaseService service,
    Purchase product,
    int balance,
  ) {
    final canAfford = balance >= product.price;
    final shortfall = (product.price - balance).clamp(0, 999999);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        contentPadding: const EdgeInsets.all(22),
        title: Row(
          children: [
            Text(product.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Цена', '${product.price} монеток'),
            const SizedBox(height: 6),
            _row('Категория', product.category.label),
            const SizedBox(height: 6),
            _row('Питомец', product.effectLabel),
            const SizedBox(height: 6),
            _row('Баланс', '$balance монеток'),
            if (!canAfford) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Не хватает $shortfall монеток. Сделай задание — '
                        'и вернись за покупкой!',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Отмена',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford
                  ? AppColors.primary
                  : Colors.black.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: canAfford
                ? () {
                    final result = service.buy(product.id);
                    Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                                '${result.emoji ?? ''} ${result.message}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.ink,
                            duration: const Duration(milliseconds: 2600),
                          ),
                        );
                    }
                  }
                : null,
            child: const Text(
              'Купить',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка «параметра» в диалоге: подпись + значение.
Widget _row(String label, String value) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.inkSoft,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
    ],
  );
}

/// Секция каталога: заголовок с типом + сетка товаров (2 колонки).
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emoji,
    required this.color,
    required this.items,
    required this.balance,
    required this.onBuy,
  });

  final String title;
  final String emoji;
  final Color color;
  final List<Purchase> items;
  final int balance;
  final ValueChanged<Purchase> onBuy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // На широких экранах — 4 колонки, на узких (телефон) — 2.
            final cols = constraints.maxWidth > 560 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final product in items)
                  _ProductCard(
                    product: product,
                    color: color,
                    canAfford: balance >= product.price,
                    onTap: () => onBuy(product),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Карточка товара: эмодзи, название, цена, влияние.
///
/// Доступность (ТЗ §10): цена подсвечена цветом И добавляется символ
/// «🔒», если денег не хватает — цвет не единственный сигнал.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.color,
    required this.canAfford,
    required this.onTap,
  });

  final Purchase product;
  final Color color;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(product.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppColors.leaf.withValues(alpha: 0.18)
                      : AppColors.primaryDark.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      canAfford ? '🪙' : '🔒',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.price}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: canAfford
                            ? const Color(0xFF3E8E4E)
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.effectLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft
                      .withValues(alpha: canAfford ? 1 : 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

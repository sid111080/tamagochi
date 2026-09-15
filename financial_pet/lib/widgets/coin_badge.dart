import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Компактный индикатор баланса монет.
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.balance, this.large = false});

  final int balance;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 22.0 : 15.0;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : 12, vertical: large ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🪙',
            style: TextStyle(fontSize: fontSize, height: 1),
          ),
          const SizedBox(width: 6),
          Text(
            '$balance',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

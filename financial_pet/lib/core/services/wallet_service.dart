import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallet.dart';

/// Ключ хранилища.
const String _kWallet = 'wallet_v1';

/// Управляет кошельком: балансом и историей операций.
/// Все данные хранятся локально (SharedPreferences).
class WalletService extends ChangeNotifier {
  WalletService._(this._prefs, this._wallet);

  factory WalletService(SharedPreferences prefs) =>
      WalletService._(prefs, _load(prefs));

  final SharedPreferences _prefs;
  final Wallet _wallet;

  static const int startingBalance = 50;

  static Wallet _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kWallet);
    if (raw == null) return Wallet(balance: startingBalance);
    try {
      return Wallet.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Wallet(balance: startingBalance);
    }
  }

  int get balance => _wallet.balance;
  List<CoinTransaction> get transactions => _wallet.transactions;
  bool canAfford(int amount) => _wallet.canAfford(amount);

  /// Начислить монеты.
  void earn(int amount, String reason, String emoji) {
    _wallet.earn(amount, reason, emoji);
    _save();
  }

  /// Потратить монеты; false, если недостаточно.
  bool trySpend(int amount, String reason, String emoji) {
    final ok = _wallet.trySpend(amount, reason, emoji);
    if (ok) _save();
    return ok;
  }

  /// Полный сброс кошелька: баланс к стартовому, история пуста.
  /// (сброс профиля / демо-режим, ТЗ §8.13)
  void reset() {
    _wallet
      ..balance = startingBalance
      ..transactions = [];
    _save();
  }

  void _save() {
    _prefs.setString(_kWallet, jsonEncode(_wallet.toJson()));
    notifyListeners();
  }
}

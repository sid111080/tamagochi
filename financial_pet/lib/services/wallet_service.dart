import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallet.dart';

/// Ключ хранилища.
const String _kWallet = 'wallet_v1';

/// Управляет кошельком: балансом и историей операций.
/// Все данные хранятся локально (SharedPreferences).
class WalletService extends ChangeNotifier {
  WalletService(this._prefs) : _wallet = _load();

  final SharedPreferences _prefs;
  final Wallet _wallet;

  static const int startingBalance = 50;

  Wallet _load() {
    final raw = _prefs.getString(_kWallet);
    if (raw == null) return Wallet(startingBalance: startingBalance);
    try {
      return Wallet.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Wallet(startingBalance: startingBalance);
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

  void _save() {
    _prefs.setString(_kWallet, jsonEncode(_wallet.toJson()));
    notifyListeners();
  }
}

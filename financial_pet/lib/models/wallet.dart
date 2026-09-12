/// Одна операция с виртуальной валютой (монетками).
class CoinTransaction {
  CoinTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.emoji,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final String id;

  /// Позитивное — доход, негативное — расход.
  final int amount;
  final String reason;
  final String emoji;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'reason': reason,
        'emoji': emoji,
        'at': at.toIso8601String(),
      };

  factory CoinTransaction.fromJson(Map<String, dynamic> json) =>
      CoinTransaction(
        id: json['id'] as String,
        amount: (json['amount'] as num).toInt(),
        reason: json['reason'] as String,
        emoji: json['emoji'] as String,
        at: DateTime.parse(json['at'] as String),
      );
}

/// Кошелёк виртуальной валюты приложения.
class Wallet {
  Wallet({int balance = 50}) : balance = balance;

  int balance;
  List<CoinTransaction> transactions = [];

  /// Начислить монеты (доход).
  void earn(int amount, String reason, String emoji) {
    if (amount <= 0) return;
    balance += amount;
    _log(amount, reason, emoji);
  }

  /// Потратить монеты. Возвращает false, если денег не хватает.
  bool trySpend(int amount, String reason, String emoji) {
    if (amount <= 0 || balance < amount) return false;
    balance -= amount;
    _log(-amount, reason, emoji);
    return true;
  }

  bool canAfford(int amount) => balance >= amount;

  void _log(int amount, String reason, String emoji) {
    transactions.insert(
        0,
        CoinTransaction(
            id:
                'tx_${DateTime.now().microsecondsSinceEpoch}_$reason',
            amount: amount,
            reason: reason,
            emoji: emoji));
    if (transactions.length > 40) {
      transactions.removeLast();
    }
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final w = Wallet(balance: (json['balance'] as num? ?? 50).toInt());
    w.transactions = (json['transactions'] as List?)
            ?.map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return w;
  }
}

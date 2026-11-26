enum TransactionType { deposit, withdraw }

class TransactionItem {
  final String id;
  final String? sessionId;
  final String title;
  final String subtitle;
  final int bottles;
  final int cans;
  final int amount;
  final DateTime date;
  final TransactionType type;

  const TransactionItem({
    required this.id,
    this.sessionId,
    required this.title,
    required this.subtitle,
    this.bottles = 0,
    this.cans = 0,
    required this.amount,
    required this.date,
    required this.type,
  });
}

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.amount,
    required this.category,
  });

  final String id;
  final String userId;
  final DateTime date;
  final double amount;
  final String category;

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        date: DateTime.parse(map['date'] as String),
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
      );
}

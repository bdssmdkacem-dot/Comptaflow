class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.supplierName,
    required this.description,
    required this.category,
    required this.amountHt,
    required this.taxRate,
    required this.date,
    this.notes,
  });

  final String id;
  final String userId;
  final String supplierName;
  final String description;
  final String category;
  final double amountHt;
  final double taxRate;
  final DateTime date;
  final String? notes;

  double get taxAmount => amountHt * taxRate / 100;
  double get totalTtc => amountHt + taxAmount;

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        supplierName: map['supplier_name'] as String,
        description: map['description'] as String,
        category: map['category'] as String,
        amountHt: (map['amount_ht'] as num).toDouble(),
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
        date: DateTime.parse(map['expense_date'] as String),
        notes: map['notes'] as String?,
      );
}

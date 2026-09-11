import '../../data/models/expense.dart';

class ExpenseAnalytics {
  const ExpenseAnalytics._();

  static List<ExpenseModel> filter({
    required List<ExpenseModel> expenses,
    DateTime? from,
    DateTime? to,
    String? category,
  }) {
    return expenses.where((expense) {
      final date = expense.expenseDate;
      final afterFrom = from == null || !date.isBefore(_startOfDay(from));
      final beforeTo = to == null || !date.isAfter(_endOfDay(to));
      final matchesCategory =
          category == null || category.isEmpty || category == 'Toutes' || expense.category == category;
      return afterFrom && beforeTo && matchesCategory;
    }).toList();
  }

  static double totalHt(Iterable<ExpenseModel> expenses) =>
      expenses.fold<double>(0, (sum, expense) => sum + expense.amountHt);

  static double totalTva(Iterable<ExpenseModel> expenses) =>
      expenses.fold<double>(0, (sum, expense) => sum + expense.taxAmount);

  static double totalTtc(Iterable<ExpenseModel> expenses) =>
      expenses.fold<double>(0, (sum, expense) => sum + expense.totalTtc);

  static Map<String, double> totalsByCategory(Iterable<ExpenseModel> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.totalTtc,
        ifAbsent: () => expense.totalTtc,
      );
    }
    return totals;
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

class CpuDeclaration {
  const CpuDeclaration({
    required this.id,
    required this.userId,
    required this.period,
    required this.caEncaisse,
    required this.cpuRate,
    required this.cpuAmount,
    this.declaredAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime period;
  final double caEncaisse;
  final double cpuRate;
  final double cpuAmount;
  final DateTime? declaredAt;
  final DateTime createdAt;

  bool get isDeclared => declaredAt != null;

  factory CpuDeclaration.fromMap(Map<String, dynamic> map) => CpuDeclaration(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        period: DateTime.parse(map['period'] as String),
        caEncaisse: (map['ca_encaisse'] as num).toDouble(),
        cpuRate: (map['cpu_rate'] as num).toDouble(),
        cpuAmount: (map['cpu_amount'] as num).toDouble(),
        declaredAt: map['declared_at'] == null
            ? null
            : DateTime.parse(map['declared_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

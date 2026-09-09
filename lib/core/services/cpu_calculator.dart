class CpuCalculator {
  const CpuCalculator._();

  /// Calculates the simplified professional tax (CPU) amount from collected
  /// turnover. The rate is supplied by the user's activity profile.
  static double calculate({required double caEncaisse, required double rate}) {
    if (caEncaisse < 0) throw ArgumentError.value(caEncaisse, 'caEncaisse');
    if (rate < 0 || rate > 1) throw ArgumentError.value(rate, 'rate');
    return caEncaisse * rate;
  }

  static double rateForActivity(String activityType) {
    switch (activityType.trim().toLowerCase()) {
      case 'services':
      case 'service':
        return 0.10;
      case 'commercial':
      case 'commerce':
        return 0.03;
      case 'artisanal':
      case 'artisanat':
        return 0.05;
      default:
        return 0.10;
    }
  }
}

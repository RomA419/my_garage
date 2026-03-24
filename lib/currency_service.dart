/// Handles currency conversion.
/// All amounts stored in the app are in KZT (тенге).
/// This service converts them to the currently selected display currency.
class CurrencyService {
  // KZT is the base currency for all stored values.
  // Rates: 1 KZT = N target units
  static const Map<String, double> _rates = {
    '₸': 1.0,
    '₽': 0.1786,  // 1 KZT ≈ 0.1786 RUB  (1 RUB ≈ 5.60 KZT)
    '\$': 0.002075, // 1 KZT ≈ 0.002075 USD (1 USD ≈ 482 KZT)
    '€': 0.001799,  // 1 KZT ≈ 0.001799 EUR (1 EUR ≈ 556 KZT)
  };

  /// Converts a KZT amount to the target currency.
  static double convert(double kztAmount, String targetCurrency) {
    return kztAmount * (_rates[targetCurrency] ?? 1.0);
  }

  /// Converts and formats a KZT amount with the correct symbol.
  /// For ₸ and ₽ — shows whole numbers; for $ and € — shows two decimal places.
  static String format(double kztAmount, String currency) {
    final converted = convert(kztAmount, currency);
    if (currency == '₸' || currency == '₽') {
      return '${converted.toStringAsFixed(0)} $currency';
    }
    return '$currency ${converted.toStringAsFixed(2)}';
  }
}

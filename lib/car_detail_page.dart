import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'car_preview.dart';
import 'car_types.dart';
import 'currency_service.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'models.dart';

/// Экран деталей автомобиля.
///
/// Показывает полную информацию о машине, статистику расходов
/// и историю заправок для конкретного авто.
class CarDetailPage extends StatelessWidget {
  final CarModel car;

  const CarDetailPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final garage = context.watch<GarageProvider>();
    final currency = context.watch<AuthProvider>().user?.settings['currency'] as String? ?? '₸';
    final records = garage.fuelRecords
        .where((r) => r.carNumber == car.number)
        .toList();
    final tr = LocaleService.tr;

    double totalExpenses = 0;
    for (final r in records) {
      totalExpenses += double.tryParse(r.total) ?? 0;
    }

    final lastOdometer = records.isNotEmpty
        ? records
            .firstWhere(
              (r) => (r.odometer ?? '').isNotEmpty,
              orElse: () => records.first,
            )
            .odometer
        : null;

    final carTypeIndex = car.typeIndex.clamp(0, carTypes.length - 1);
    final carSvg = carTypes[carTypeIndex]['svg'] as String?;
    final carPng = carTypes[carTypeIndex]['png'] as String?;
    final carIcon =
        carTypes[carTypeIndex]['icon'] as IconData? ?? Icons.directions_car;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          car.title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Превью машины
            Hero(
              tag: 'car_detail_${car.id}',
              child: CarPreview(
                svgAsset: carSvg,
                pngAsset: carPng,
                icon: carIcon,
                color: Color(car.color),
                size: 140,
                title: car.title,
                subtitle: car.number,
              ),
            ),
            const SizedBox(height: 24),

            // Статистика
            Row(
              children: [
                _statCard(theme, isDark, Icons.receipt_long,
                    tr('totalRefuels'), '${records.length}', Colors.blueAccent),
                const SizedBox(width: 12),
                _statCard(
                    theme,
                    isDark,
                    Icons.payments,
                    tr('totalExpenses'),
                    CurrencyService.format(totalExpenses, currency),
                    Colors.redAccent),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  theme,
                  isDark,
                  Icons.speed,
                  tr('mileage'),
                  (lastOdometer != null && lastOdometer.isNotEmpty)
                      ? '$lastOdometer ${tr('km')}'
                      : '-',
                  Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                _statCard(
                  theme,
                  isDark,
                  Icons.local_gas_station,
                  tr('lastRefuel'),
                  records.isNotEmpty ? records.first.date : '-',
                  Colors.greenAccent,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Заголовок истории
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr('history'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Список или пустое состояние
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.local_gas_station_outlined,
                        size: 48,
                        color: theme.iconTheme.color?.withOpacity(0.2)),
                    const SizedBox(height: 8),
                    Text(
                      tr('noRecords'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...records.map((r) => _recordCard(theme, isDark, r, currency)),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(ThemeData theme, bool isDark, FuelRecordModel r, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyService.format(double.tryParse(r.total) ?? 0, currency),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.station} • ${r.subType} • ${r.quantity} ${r.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            r.date,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(ThemeData theme, bool isDark, IconData icon, String label,
      String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

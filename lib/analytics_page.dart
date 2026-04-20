import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'car_compare_page.dart';
import 'car_health_page.dart';
import 'currency_service.dart';
import 'expenses_page.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'maintenance_page.dart';
import 'models.dart';

String _trAnalyticsServiceType(String type) {
  if (LocaleService.isRu) return type;
  const en = {
    'Замена масла': 'Oil change',
    'Замена фильтра': 'Filter replacement',
    'Замена тормозной жидкости': 'Brake fluid replacement',
    'Замена тормозных колодок': 'Brake pad replacement',
    'Замена свечей зажигания': 'Spark plug replacement',
    'Замена ремня ГРМ': 'Timing belt replacement',
    'Замена шин': 'Tire change',
    'Плановое ТО': 'Scheduled service',
    'Промывка инжектора': 'Injector flush',
    'Диагностика': 'Diagnostics',
    'Другое': 'Other',
  };
  return en[type] ?? type;
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const _serviceIntervalsKm = {
    'Замена масла': 10000,
    'Замена фильтра': 15000,
    'Замена тормозной жидкости': 40000,
    'Замена тормозных колодок': 20000,
    'Замена свечей зажигания': 30000,
    'Замена ремня ГРМ': 60000,
    'Замена шин': 12000,
    'Плановое ТО': 10000,
    'Промывка инжектора': 30000,
    'Диагностика': 15000,
    'Другое': 10000,
  };

  @override
  void dispose() {
    super.dispose();
  }

  Map<String, int> _serviceIntervalsFromSettings(
    Map<String, dynamic>? settings,
  ) {
    final result = Map<String, int>.from(_serviceIntervalsKm);
    final raw = settings?['maintenanceTypeIntervals'];
    if (raw is Map) {
      for (final key in result.keys) {
        final value = raw[key];
        if (value is int && value > 0) {
          result[key] = value;
        }
      }
    }
    return result;
  }

  double? _currentMileage(
    List<FuelRecordModel> fuelRecords,
    List<MaintenanceRecord> maintenanceRecords,
  ) {
    double maxMileage = 0;
    for (final record in fuelRecords) {
      final mileage = double.tryParse(record.odometer ?? '0') ?? 0;
      if (mileage > maxMileage) maxMileage = mileage;
    }
    for (final record in maintenanceRecords) {
      final mileage = double.tryParse(record.odometer) ?? 0;
      if (mileage > maxMileage) maxMileage = mileage;
    }
    return maxMileage > 0 ? maxMileage : null;
  }

  Map<String, dynamic> _buildHealthSnapshot(
    List<FuelRecordModel> fuelRecords,
    List<MaintenanceRecord> maintenanceRecords,
    String Function(String) tr,
  ) {
    final now = DateTime.now();
    double maintenanceScore = 0;
    if (maintenanceRecords.isNotEmpty) {
      final lastMaintenance = maintenanceRecords
          .map((r) => r.timestamp)
          .reduce((a, b) => a > b ? a : b);
      final daysSince = now
          .difference(DateTime.fromMillisecondsSinceEpoch(lastMaintenance))
          .inDays;
      if (daysSince <= 30) {
        maintenanceScore = 100;
      } else if (daysSince <= 90) {
        maintenanceScore = 80;
      } else if (daysSince <= 180) {
        maintenanceScore = 55;
      } else if (daysSince <= 365) {
        maintenanceScore = 30;
      } else {
        maintenanceScore = 10;
      }
    }

    double fuelScore = 0;
    if (fuelRecords.isNotEmpty) {
      final lastFuel = fuelRecords
          .map((r) => r.timestamp)
          .reduce((a, b) => a > b ? a : b);
      final daysSince = now
          .difference(DateTime.fromMillisecondsSinceEpoch(lastFuel))
          .inDays;
      if (daysSince <= 14) {
        fuelScore = 100;
      } else if (daysSince <= 30) {
        fuelScore = 80;
      } else if (daysSince <= 60) {
        fuelScore = 50;
      } else {
        fuelScore = 20;
      }
    }

    final cutoff3m = now
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;
    final recentFuel = fuelRecords.where((r) => r.timestamp >= cutoff3m).length;
    final recentMaintenance = maintenanceRecords
        .where((r) => r.timestamp >= cutoff3m)
        .length;
    final recentTotal = recentFuel + recentMaintenance;
    final activityScore = recentTotal >= 8
        ? 100.0
        : recentTotal >= 4
        ? 75.0
        : recentTotal >= 2
        ? 50.0
        : recentTotal >= 1
        ? 25.0
        : 0.0;

    final overall =
        (maintenanceScore * 0.4 + fuelScore * 0.3 + activityScore * 0.3).clamp(
          0.0,
          100.0,
        );

    if (overall >= 80) {
      return {
        'score': overall,
        'label': tr('healthExcellent'),
        'color': Colors.green,
        'icon': Icons.verified,
      };
    }
    if (overall >= 55) {
      return {
        'score': overall,
        'label': tr('healthGood'),
        'color': Colors.lightGreen,
        'icon': Icons.thumb_up,
      };
    }
    if (overall >= 30) {
      return {
        'score': overall,
        'label': tr('healthFair'),
        'color': Colors.orange,
        'icon': Icons.warning_amber_rounded,
      };
    }
    return {
      'score': overall,
      'label': tr('healthPoor'),
      'color': Colors.red,
      'icon': Icons.error_outline,
    };
  }

  List<String> _buildServiceRecommendations(
    int currentMileage,
    List<MaintenanceRecord> maintenanceRecords,
    Map<String, int> intervals,
    String Function(String) tr,
  ) {
    const trackedTypes = [
      'Замена масла',
      'Замена тормозной жидкости',
      'Замена тормозных колодок',
      'Замена фильтра',
    ];

    final lastMileageByType = <String, int>{};
    for (final record in maintenanceRecords) {
      if (lastMileageByType.containsKey(record.type)) continue;
      final mileage = int.tryParse(record.odometer);
      if (mileage != null && mileage > 0) {
        lastMileageByType[record.type] = mileage;
      }
    }

    final recommendations = <MapEntry<String, int>>[];
    for (final type in trackedTypes) {
      final interval = intervals[type] ?? 10000;
      final lastMileage = lastMileageByType[type];
      int remaining;
      if (lastMileage != null) {
        remaining = (lastMileage + interval) - currentMileage;
      } else {
        final remainder = currentMileage % interval;
        remaining = remainder == 0 ? 0 : interval - remainder;
      }
      recommendations.add(MapEntry(type, remaining));
    }
    recommendations.sort((a, b) => a.value.compareTo(b.value));

    return recommendations.take(3).map((entry) {
      if (entry.value < 0) {
        return tr('passportServiceOverdue')
            .replaceAll('{service}', _trAnalyticsServiceType(entry.key))
            .replaceAll('{km}', '${entry.value.abs()}');
      }
      if (entry.value == 0) {
        return tr(
          'passportServiceNow',
        ).replaceAll('{service}', _trAnalyticsServiceType(entry.key));
      }
      return tr('passportServiceInKm')
          .replaceAll('{service}', _trAnalyticsServiceType(entry.key))
          .replaceAll('{km}', '${entry.value}');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final garage = context.watch<GarageProvider>();
    final auth = context.watch<AuthProvider>();
    final tr = LocaleService.tr;
    final car = garage.currentCar;

    if (car == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            tr('carPassport'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor,
          iconTheme: theme.appBarTheme.iconTheme,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 72,
                  color: theme.iconTheme.color?.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('passportNoCarTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  tr('passportNoCarHint'),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fuelRecords =
        garage.fuelRecords.where((r) => r.carNumber == car.number).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final maintenanceRecords =
        garage.maintenanceRecords
            .where((r) => r.carNumber == car.number)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final currency = auth.user?.settings['currency'] as String? ?? '₸';
    final mileage = _currentMileage(fuelRecords, maintenanceRecords);
    final monthlyFuelTotal = fuelRecords.fold<double>(0, (sum, item) {
      final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month) {
        return sum + (double.tryParse(item.total) ?? 0);
      }
      return sum;
    });
    final monthlyMaintenanceTotal = maintenanceRecords.fold<double>(0, (
      sum,
      item,
    ) {
      final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month) {
        return sum + (double.tryParse(item.cost) ?? 0);
      }
      return sum;
    });
    final health = _buildHealthSnapshot(fuelRecords, maintenanceRecords, tr);
    final intervals = _serviceIntervalsFromSettings(auth.user?.settings);
    final recommendations = mileage == null
        ? <String>[tr('passportNeedMileage')]
        : _buildServiceRecommendations(
            mileage.toInt(),
            maintenanceRecords,
            intervals,
            tr,
          );
    final lastRefuel = fuelRecords.isNotEmpty ? fuelRecords.first.date : '-';
    final lastMaintenance = maintenanceRecords.isNotEmpty
        ? maintenanceRecords.first.date
        : '-';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr('carPassport'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.14),
                  theme.cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (car.number.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    car.number,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(
                        0.75,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (health['color'] as Color).withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        health['icon'] as IconData,
                        color: health['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('passportStatus'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(health['score'] as double).toInt()}% • ${health['label']}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: health['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  theme,
                  tr('odometer'),
                  mileage == null ? '-' : '${mileage.toInt()} ${tr('km')}',
                  Icons.speed,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  theme,
                  tr('monthExpenses'),
                  CurrencyService.format(
                    monthlyFuelTotal + monthlyMaintenanceTotal,
                    currency,
                  ),
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  theme,
                  tr('lastRefuel'),
                  lastRefuel,
                  Icons.local_gas_station,
                  const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  theme,
                  tr('maintenanceLog'),
                  lastMaintenance,
                  Icons.build_circle,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            theme,
            title: tr('passportServiceTitle'),
            child: Column(
              children: recommendations
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            item.contains(tr('passportServiceOverdueMarker'))
                                ? Icons.error_outline
                                : Icons.schedule,
                            size: 18,
                            color:
                                item.contains(
                                  tr('passportServiceOverdueMarker'),
                                )
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            theme,
            title: tr('passportCostsTitle'),
            child: Column(
              children: [
                _miniRow(
                  theme,
                  tr('expensesFuel'),
                  CurrencyService.format(monthlyFuelTotal, currency),
                ),
                const SizedBox(height: 8),
                _miniRow(
                  theme,
                  tr('expensesMaint'),
                  CurrencyService.format(monthlyMaintenanceTotal, currency),
                ),
                const SizedBox(height: 8),
                _miniRow(
                  theme,
                  tr('passportFuelCount'),
                  '${fuelRecords.length}',
                ),
                const SizedBox(height: 8),
                _miniRow(
                  theme,
                  tr('passportMaintCount'),
                  '${maintenanceRecords.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            theme,
            title: tr('passportActionsTitle'),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _actionChip(
                  context,
                  theme,
                  tr('expensesTitle'),
                  Icons.account_balance_wallet_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensesPage()),
                  ),
                ),
                _actionChip(
                  context,
                  theme,
                  tr('maintenanceLog'),
                  Icons.build_circle_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MaintenancePage()),
                  ),
                ),
                _actionChip(
                  context,
                  theme,
                  tr('healthTitle'),
                  Icons.favorite_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarHealthPage()),
                  ),
                ),
                _actionChip(
                  context,
                  theme,
                  tr('compareTitle'),
                  Icons.compare_arrows_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarComparePage()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    ThemeData theme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _miniRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _actionChip(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.14)),
    );
  }
}

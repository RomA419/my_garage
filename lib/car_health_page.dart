import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'models.dart';

// ──────────────────────────────────────────────
//  Car Health — Здоровье автомобиля
// ──────────────────────────────────────────────

class CarHealthPage extends StatelessWidget {
  const CarHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final garage = context.watch<GarageProvider>();
    final tr = LocaleService.tr;
    final car = garage.currentCar;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr('healthTitle'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: car == null
          ? _buildNoCar(theme, tr)
          : _buildHealth(context, theme, isDark, garage, car, tr),
    );
  }

  Widget _buildNoCar(ThemeData theme, String Function(String) tr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined, size: 72, color: theme.iconTheme.color?.withOpacity(0.18)),
          const SizedBox(height: 16),
          Text(tr('healthNoCar'), style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildHealth(BuildContext context, ThemeData theme, bool isDark,
      GarageProvider garage, CarModel car, String Function(String) tr) {
    final now = DateTime.now();

    // Fuel records for this car
    final fuelRecords = garage.fuelRecords
        .where((r) => r.carNumber == car.number)
        .toList();

    // Maintenance records for this car
    final maintRecords = garage.maintenanceRecords
        .where((r) => r.carNumber == car.number)
        .toList();

    // ── Scoring ──────────────────────────────
    // 1. Maintenance score (0-100): based on days since last maintenance
    double maintScore = 0;
    String maintTip = tr('healthTipMaint');
    if (maintRecords.isNotEmpty) {
      final lastMaint = maintRecords.map((r) => r.timestamp).reduce(max);
      final daysSince = now.difference(DateTime.fromMillisecondsSinceEpoch(lastMaint)).inDays;
      if (daysSince <= 30) {
        maintScore = 100;
      } else if (daysSince <= 90) {
        maintScore = 80;
      } else if (daysSince <= 180) {
        maintScore = 55;
      } else if (daysSince <= 365) {
        maintScore = 30;
      } else {
        maintScore = 10;
      }
    }

    // 2. Fuel score (0-100): based on regularity and recency of refueling
    double fuelScore = 0;
    String fuelTip = tr('healthTipFuel');
    if (fuelRecords.isNotEmpty) {
      final lastFuel = fuelRecords.map((r) => r.timestamp).reduce(max);
      final daysSince = now.difference(DateTime.fromMillisecondsSinceEpoch(lastFuel)).inDays;
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

    // 3. Activity score (0-100): how many records total in last 3 months
    final cutoff3m = now.subtract(const Duration(days: 90)).millisecondsSinceEpoch;
    final recentFuel = fuelRecords.where((r) => r.timestamp >= cutoff3m).length;
    final recentMaint = maintRecords.where((r) => r.timestamp >= cutoff3m).length;
    final recentTotal = recentFuel + recentMaint;
    double activityScore;
    if (recentTotal >= 8) {
      activityScore = 100;
    } else if (recentTotal >= 4) {
      activityScore = 75;
    } else if (recentTotal >= 2) {
      activityScore = 50;
    } else if (recentTotal >= 1) {
      activityScore = 25;
    } else {
      activityScore = 0;
    }

    // Overall
    final overall = (maintScore * 0.4 + fuelScore * 0.3 + activityScore * 0.3).clamp(0.0, 100.0);

    String healthLabel;
    Color healthColor;
    IconData healthIcon;
    if (overall >= 80) {
      healthLabel = tr('healthExcellent');
      healthColor = Colors.green;
      healthIcon = Icons.verified;
    } else if (overall >= 55) {
      healthLabel = tr('healthGood');
      healthColor = Colors.lightGreen;
      healthIcon = Icons.thumb_up;
    } else if (overall >= 30) {
      healthLabel = tr('healthFair');
      healthColor = Colors.orange;
      healthIcon = Icons.warning_amber_rounded;
    } else {
      healthLabel = tr('healthPoor');
      healthColor = Colors.red;
      healthIcon = Icons.error_outline;
    }

    // Tip
    String tip;
    if (overall >= 80) {
      tip = tr('healthTipGreat');
    } else if (maintScore < fuelScore) {
      tip = maintTip;
    } else {
      tip = fuelTip;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Car title
          Text(
            car.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (car.number.isNotEmpty)
            Text(car.number, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5))),
          const SizedBox(height: 24),

          // Circular progress
          SizedBox(
            width: 200,
            height: 200,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: overall / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: theme.dividerColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(healthColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(healthIcon, size: 36, color: healthColor),
                          const SizedBox(height: 6),
                          Text(
                            '${(value * 100).toInt()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: healthColor,
                            ),
                          ),
                          Text(healthLabel, style: theme.textTheme.bodySmall?.copyWith(
                              color: healthColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          // Sub-scores
          _scoreRow(theme, isDark, Icons.build, tr('healthMaintScore'), maintScore, Colors.orange),
          const SizedBox(height: 12),
          _scoreRow(theme, isDark, Icons.local_gas_station, tr('healthFuelScore'), fuelScore, Colors.blue),
          const SizedBox(height: 12),
          _scoreRow(theme, isDark, Icons.timeline, tr('healthActivityScore'), activityScore, Colors.purple),
          const SizedBox(height: 24),

          // Tip card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: healthColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: healthColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: healthColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('healthTip'), style: theme.textTheme.bodySmall?.copyWith(
                          color: healthColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(tip, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(ThemeData theme, bool isDark, IconData icon, String label, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${score.toInt()}', style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'currency_service.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'models.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _distanceController = TextEditingController();
  final _consumptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _litersController = TextEditingController();

  double? _fuelNeeded;
  double? _tripCost;
  double? _computedConsumption;

  @override
  void dispose() {
    _distanceController.dispose();
    _consumptionController.dispose();
    _priceController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  List<FuelRecordModel> get _filteredRecords {
    final garage = context.read<GarageProvider>();
    final currentCar = garage.currentCar;
    if (currentCar == null || currentCar.number.isEmpty) {
      return garage.fuelRecords.toList();
    }
    return garage.fuelRecords
        .where((r) => r.carNumber == currentCar.number)
        .toList();
  }

  List<FuelRecordModel> get _sortedRecords {
    final list = List<FuelRecordModel>.from(_filteredRecords);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Преобразует значение к double, если это строка или число.
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }

  List<_ConsumptionTrend> get _consumptionTrend {
    final records = _sortedRecords;

    final trend = <_ConsumptionTrend>[];
    for (var i = 0; i < records.length - 1; i++) {
      final current = records[i];
      final previous = records[i + 1];

      final currentOdo = _toDouble(current.odometer);
      final previousOdo = _toDouble(previous.odometer);
      final liters = _toDouble(current.quantity);

      if (currentOdo == null || previousOdo == null || liters == null) continue;
      final deltaKm = currentOdo - previousOdo;
      if (deltaKm <= 0) continue;

      final litersPer100km = liters / deltaKm * 100.0;
      trend.add(_ConsumptionTrend(
        date: current.date,
        consumption: litersPer100km,
        liters: liters,
        km: deltaKm,
      ));
    }

    return trend;
  }

  String _format(double value) {
    return value.toStringAsFixed(1);
  }

  void _recalculate() {
    final distance = double.tryParse(_distanceController.text.replaceAll(',', '.'));
    final consumption = double.tryParse(_consumptionController.text.replaceAll(',', '.'));
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    final liters = double.tryParse(_litersController.text.replaceAll(',', '.'));

    double? fuelNeeded;
    double? tripCost;
    double? computedConsumption;

    // Расчет нужного топлива
    if (distance != null && consumption != null) {
      fuelNeeded = distance * consumption / 100.0;
    }

    // Расчет расхода на 100 км по литрам и расстоянию
    if (distance != null && liters != null && distance > 0) {
      computedConsumption = liters / distance * 100.0;
    }

    // Расчет стоимости поездки
    if (price != null) {
      if (fuelNeeded != null) {
        tripCost = fuelNeeded * price;
      } else if (liters != null) {
        tripCost = liters * price;
      }
    }

    setState(() {
      _fuelNeeded = fuelNeeded;
      _tripCost = tripCost;
      _computedConsumption = computedConsumption;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final currency = context.watch<AuthProvider>().user?.settings['currency'] as String? ?? '₸';

    final trend = _consumptionTrend;
    final averageConsumption = trend.isNotEmpty
        ? trend.map((e) => e.consumption).reduce((a, b) => a + b) / trend.length
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final garage = context.watch<GarageProvider>();
            final carTitle = garage.currentCar?.title;
            return Text(
              carTitle != null && carTitle.isNotEmpty
                  ? '${LocaleService.tr('analytics')} • $carTitle'
                  : LocaleService.tr('analytics'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            );
          },
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleService.tr('fuelCalculator'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCalculatorCard(theme, isDark, currency),
            const SizedBox(height: 25),
            Text(
              LocaleService.tr('consumptionTrends'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (trend.isEmpty) ...[
              Text(
                LocaleService.tr('trendHint1'),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
              const SizedBox(height: 10),
              Text(
                LocaleService.tr('trendHint2'),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
            ] else ...[
              if (averageConsumption != null) ...[
                _buildStatCard(
                  theme,
                  title: LocaleService.tr('averageConsumption'),
                  value: _format(averageConsumption),
                  color: Colors.greenAccent,
                ),
                const SizedBox(height: 16),
              ],
              if (trend.length >= 2) ...[
                _buildConsumptionChart(theme, trend),
                const SizedBox(height: 16),
              ],
              ...trend.map((item) => _buildTrendItem(theme, item)).toList(),
            ],

            // --- Monthly bar chart ---
            if (_filteredRecords.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                LocaleService.tr('monthlyChart'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildMonthlyBarChart(theme, currency),
            ],

            // --- Fuel price dynamics ---
            if (_fuelPriceTrend.isNotEmpty) ...[              
              const SizedBox(height: 30),
              Text(
                LocaleService.tr('fuelPriceDynamics'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFuelPriceChart(theme, isDark, currency),
            ],

            // --- Pie chart: expenses by category ---
            if (_filteredRecords.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                LocaleService.tr('expensesByCategory'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildExpensesPieChart(theme, currency),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(ThemeData theme, bool isDark, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildInputField(
            theme,
            controller: _distanceController,
            label: LocaleService.tr('distanceKm'),
            icon: Icons.straighten,
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 10),
          _buildInputField(
            theme,
            controller: _consumptionController,
            label: LocaleService.tr('consumptionPer100'),
            icon: Icons.local_gas_station,
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 10),
          _buildInputField(
            theme,
            controller: _litersController,
            label: LocaleService.tr('litersRefueled'),
            icon: Icons.opacity,
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 10),
          _buildInputField(
            theme,
            controller: _priceController,
            label: LocaleService.tr('pricePerLiter'),
            icon: Icons.price_check,
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  theme,
                  title: LocaleService.tr('fuelNeeded'),
                  value: _fuelNeeded != null ? '${_format(_fuelNeeded!)} л' : '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildResultCard(
                  theme,
                  title: LocaleService.tr('tripCost'),
                  value: _tripCost != null ? CurrencyService.format(_tripCost!, currency) : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_computedConsumption != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${LocaleService.tr('consumptionResult')}: ${_format(_computedConsumption!)} л/100 км',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 22),
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
        filled: true,
        fillColor: isDark ? Colors.black : Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, {required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, {required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(ThemeData theme, List<_ConsumptionTrend> trend) {
    // Reverse so oldest is on the left
    final data = trend.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), double.parse(data[i].consumption.toStringAsFixed(1))));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.25;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: LineChart(
        LineChartData(
          minY: (minY - pad).clamp(0, double.infinity),
          maxY: maxY + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 3).clamp(1, double.infinity),
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  // Show short date
                  final parts = data[idx].date.split('.');
                  final label = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : data[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.scaffoldBackgroundColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} л/100км',
                    TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendItem(ThemeData theme, _ConsumptionTrend item) {
    final previous = _consumptionTrend;
    final idx = previous.indexOf(item);
    final nextValue = idx + 1 < previous.length ? previous[idx + 1].consumption : null;
    final diff = nextValue != null ? item.consumption - nextValue : null;

    final trendIcon = diff == null
        ? null
        : diff < 0
            ? Icons.arrow_downward
            : Icons.arrow_upward;

    final trendColor = diff == null
        ? theme.textTheme.bodySmall?.color
        : diff < 0
            ? Colors.greenAccent
            : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.date,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_format(item.consumption)} л/100 км',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_format(item.liters)} л • ${_format(item.km)} км',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          if (trendIcon != null)
            Row(
              children: [
                Icon(trendIcon, size: 20, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  diff != null ? '${diff.abs().toStringAsFixed(1)}' : '',
                  style: theme.textTheme.bodySmall?.copyWith(color: trendColor),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesPieChart(ThemeData theme, String currency) {
    final Map<String, double> categoryTotals = {};
    for (final record in _filteredRecords) {
      final cat = record.subType.isNotEmpty ? record.subType : record.category;
      final total = double.tryParse(record.total) ?? 0;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + total;
    }

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];

    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final grandTotal = entries.fold<double>(0, (s, e) => s + e.value);

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final pct = grandTotal > 0 ? (e.value / grandTotal * 100) : 0;
      sections.add(PieChartSectionData(
        value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: colors[i % colors.length],
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: List.generate(entries.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entries[i].key} (${CurrencyService.format(entries[i].value, currency)})',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Returns last 6 months totals as a map {"YYYY-MM": total}
  Map<String, double> get _monthlyTotals {
    final Map<String, double> totals = {};
    for (final r in _filteredRecords) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      final amount = double.tryParse(r.total) ?? 0;
      totals[key] = (totals[key] ?? 0) + amount;
    }
    return totals;
  }

  Widget _buildMonthlyBarChart(ThemeData theme, String currency) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i), 1);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    });
    final totals = _monthlyTotals;
    final values = months.map((m) => totals[m] ?? 0.0).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return Center(
        child: Text(
          LocaleService.tr('noRecords'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
        ),
      );
    }

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < months.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              color: theme.colorScheme.primary,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    final monthLabels = months.map((m) {
      final parts = m.split('-');
      const names = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
                     'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
      final monthIdx = int.tryParse(parts[1]) ?? 0;
      return monthIdx < names.length ? names[monthIdx] : parts[1];
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.3,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxVal / 3).clamp(1, double.infinity),
            getDrawingHorizontalLine: (v) => FlLine(
              color: theme.dividerColor.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= monthLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      monthLabels[idx],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, meta) => Text(
                  v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  CurrencyService.format(rod.toY, currency),
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Fuel price trend (price per liter computed from total/quantity) ───
  /// Groups fuel records by subType. For each record computes price/liter.
  /// Returns a map: subType → list of _FuelPricePoint, sorted by timestamp.
  Map<String, List<_FuelPricePoint>> get _fuelPriceTrend {
    final result = <String, List<_FuelPricePoint>>{};
    for (final r in _filteredRecords) {
      if (r.category != 'Топливо') continue;
      final qty = double.tryParse(r.quantity.replaceAll(',', '.'));
      final total = double.tryParse(r.total.replaceAll(',', '.'));
      if (qty == null || total == null || qty <= 0) continue;
      final pricePerLiter = total / qty;
      result.putIfAbsent(r.subType, () => []);
      result[r.subType]!.add(_FuelPricePoint(
        timestamp: r.timestamp,
        date: r.date,
        price: pricePerLiter,
      ));
    }
    for (final list in result.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return result;
  }

  Widget _buildFuelPriceChart(ThemeData theme, bool isDark, String currency) {
    final trendMap = _fuelPriceTrend;
    if (trendMap.isEmpty) return const SizedBox.shrink();

    final lineColors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
    ];

    // Flatten to find global min/max for Y axis
    double globalMin = double.infinity;
    double globalMax = 0;
    for (final entry in trendMap.values) {
      for (final p in entry) {
        final converted = CurrencyService.convert(p.price, currency);
        if (converted < globalMin) globalMin = converted;
        if (converted > globalMax) globalMax = converted;
      }
    }
    if (globalMax == 0) return const SizedBox.shrink();
    final yPad = (globalMax - globalMin) * 0.15;
    final minY = (globalMin - yPad).clamp(0.0, double.infinity);
    final maxY = globalMax + yPad;

    // Build one LineChartBarData per subType
    int colorIdx = 0;
    final lineBars = <LineChartBarData>[];
    final legendEntries = <MapEntry<String, Color>>[];

    for (final entry in trendMap.entries) {
      if (entry.value.length < 2) continue; // need at least 2 points for a line
      final color = lineColors[colorIdx % lineColors.length];
      colorIdx++;
      legendEntries.add(MapEntry(entry.key, color));

      final spots = <FlSpot>[];
      for (int i = 0; i < entry.value.length; i++) {
        final converted = CurrencyService.convert(entry.value[i].price, currency);
        spots.add(FlSpot(i.toDouble(), converted));
      }

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.25,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
            radius: 3.5,
            color: color,
            strokeWidth: 1.5,
            strokeColor: theme.scaffoldBackgroundColor,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.08),
        ),
      ));
    }

    if (lineBars.isEmpty) return const SizedBox.shrink();

    // Use the longest series for X-axis labels
    final longestSeries = trendMap.values.reduce((a, b) => a.length >= b.length ? a : b);
    final priceUnitLabel = LocaleService.tr('pricePerUnit');

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: legendEntries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(e.key, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              )).toList(),
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: theme.dividerColor.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= longestSeries.length) return const SizedBox.shrink();
                        // Show limited labels to avoid overlap
                        final step = (longestSeries.length / 5).ceil().clamp(1, 100);
                        if (i % step != 0 && i != longestSeries.length - 1) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            longestSeries[i].date,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(0),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final seriesIdx = lineBars.indexOf(spot.bar);
                        final label = seriesIdx >= 0 && seriesIdx < legendEntries.length
                            ? legendEntries[seriesIdx].key
                            : '';
                        return LineTooltipItem(
                          '$label\n${spot.y.toStringAsFixed(1)} $priceUnitLabel',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: lineBars,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumptionTrend {
  final String date;
  final double consumption;
  final double liters;
  final double km;

  _ConsumptionTrend({
    required this.date,
    required this.consumption,
    required this.liters,
    required this.km,
  });
}

class _FuelPricePoint {
  final int timestamp;
  final String date;
  final double price; // KZT per liter (base currency)

  _FuelPricePoint({
    required this.timestamp,
    required this.date,
    required this.price,
  });
}

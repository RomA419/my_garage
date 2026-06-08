import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';
import 'currency_service.dart';
import 'garage_provider.dart';
import 'locale_service.dart';

// ──────────────────────────────────────────────
//  Fine record model + storage
// ──────────────────────────────────────────────
class FineRecord {
  final String id;
  final int userId;
  final String carTitle;
  final String date;
  final int timestamp;
  final String description;
  final double amount;

  const FineRecord({
    required this.id,
    required this.userId,
    required this.carTitle,
    required this.date,
    required this.timestamp,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'carTitle': carTitle,
    'date': date,
    'timestamp': timestamp,
    'description': description,
    'amount': amount,
  };

  factory FineRecord.fromJson(Map<String, dynamic> j) => FineRecord(
    id: j['id'] as String? ?? '',
    userId: j['userId'] as int? ?? 0,
    carTitle: j['carTitle'] as String? ?? '',
    date: j['date'] as String? ?? '',
    timestamp: j['timestamp'] as int? ?? 0,
    description: j['description'] as String? ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
  );
}

class _FineStorage {
  static const _prefix = 'fines_v1_';

  static Future<List<FineRecord>> load(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => FineRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(int userId, List<FineRecord> fines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$userId',
      jsonEncode(fines.map((e) => e.toJson()).toList()),
    );
  }
}

// ──────────────────────────────────────────────
//  Unified expense entry
// ──────────────────────────────────────────────
enum _ExpType { fuel, maintenance, fine }

class _Expense {
  final _ExpType type;
  final String title;
  final String subtitle;
  final String date;
  final int timestamp;
  final double amount;
  final String? fineId; // for deletion

  const _Expense({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.timestamp,
    required this.amount,
    this.fineId,
  });
}

// ──────────────────────────────────────────────
//  Page
// ──────────────────────────────────────────────
class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<FineRecord> _fines = [];
  int _userId = 0;
  String _period = 'all';
  String _carFilter = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFines());
  }

  Future<void> _loadFines() async {
    _userId = context.read<AuthProvider>().user?.id ?? 0;
    final fines = await _FineStorage.load(_userId);
    if (mounted)
      setState(() {
        _fines = fines;
        _loading = false;
      });
  }

  Future<void> _saveFines() => _FineStorage.save(_userId, _fines);

  // ── Period cutoff ──────────────────────────
  int get _cutoff {
    final now = DateTime.now();
    switch (_period) {
      case 'month':
        return DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      case '3months':
        return now.subtract(const Duration(days: 90)).millisecondsSinceEpoch;
      case 'year':
        return DateTime(now.year, 1, 1).millisecondsSinceEpoch;
      default:
        return 0;
    }
  }

  // ── Build unified list ─────────────────────
  List<_Expense> _buildExpenses(GarageProvider garage) {
    final cutoff = _cutoff;
    final result = <_Expense>[];

    for (final r in garage.fuelRecords) {
      if (r.timestamp < cutoff) continue;
      if (_carFilter.isNotEmpty && r.carTitle != _carFilter) continue;
      final amt = double.tryParse(r.total) ?? 0.0;
      if (amt <= 0) continue;
      result.add(
        _Expense(
          type: _ExpType.fuel,
          title: r.carTitle.isNotEmpty ? r.carTitle : r.carNumber,
          subtitle: r.station.isNotEmpty
              ? r.station
              : '${r.quantity} ${r.unit}',
          date: r.date,
          timestamp: r.timestamp,
          amount: amt,
        ),
      );
    }

    for (final m in garage.maintenanceRecords) {
      if (m.timestamp < cutoff) continue;
      if (_carFilter.isNotEmpty && m.carTitle != _carFilter) continue;
      final amt = double.tryParse(m.cost) ?? 0.0;
      if (amt <= 0) continue;
      result.add(
        _Expense(
          type: _ExpType.maintenance,
          title: m.carTitle.isNotEmpty ? m.carTitle : m.carNumber,
          subtitle: m.type,
          date: m.date,
          timestamp: m.timestamp,
          amount: amt,
        ),
      );
    }

    for (final f in _fines) {
      if (f.timestamp < cutoff) continue;
      if (_carFilter.isNotEmpty && f.carTitle != _carFilter) continue;
      result.add(
        _Expense(
          type: _ExpType.fine,
          title: f.carTitle.isNotEmpty
              ? f.carTitle
              : LocaleService.tr('expensesFines'),
          subtitle: f.description,
          date: f.date,
          timestamp: f.timestamp,
          amount: f.amount,
          fineId: f.id,
        ),
      );
    }

    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final garage = context.watch<GarageProvider>();
    final currency =
        context.watch<AuthProvider>().user?.settings['currency'] as String? ??
        '₸';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(LocaleService.tr('expensesTitle'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final expenses = _buildExpenses(garage);
    final fuelTotal = expenses
        .where((e) => e.type == _ExpType.fuel)
        .fold(0.0, (s, e) => s + e.amount);
    final maintTotal = expenses
        .where((e) => e.type == _ExpType.maintenance)
        .fold(0.0, (s, e) => s + e.amount);
    final finesTotal = expenses
        .where((e) => e.type == _ExpType.fine)
        .fold(0.0, (s, e) => s + e.amount);
    final total = fuelTotal + maintTotal + finesTotal;

    // unique car titles for filter
    final carTitles = <String>{};
    for (final r in garage.fuelRecords)
      if (r.carTitle.isNotEmpty) carTitles.add(r.carTitle);
    for (final m in garage.maintenanceRecords)
      if (m.carTitle.isNotEmpty) carTitles.add(m.carTitle);
    for (final f in _fines)
      if (f.carTitle.isNotEmpty) carTitles.add(f.carTitle);

    final hasAny =
        garage.fuelRecords.isNotEmpty ||
        garage.maintenanceRecords.isNotEmpty ||
        _fines.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          LocaleService.tr('expensesTitle'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFineDialog(garage),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(LocaleService.tr('addFine')),
      ),
      body: !hasAny
          ? _buildEmpty(theme)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              children: [
                // ── Summary ──
                _buildSummaryCards(
                  theme,
                  isDark,
                  total,
                  fuelTotal,
                  maintTotal,
                  finesTotal,
                  currency,
                ),
                const SizedBox(height: 16),

                // ── Car filter ──
                if (carTitles.length > 1) ...[
                  _buildCarFilter(theme, isDark, carTitles.toList()),
                  const SizedBox(height: 12),
                ],

                // ── Period filter ──
                _buildPeriodFilter(theme),
                const SizedBox(height: 16),

                // ── Pie chart ──
                if (total > 0) ...[
                  _buildPieChart(
                    theme,
                    isDark,
                    fuelTotal,
                    maintTotal,
                    finesTotal,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Monthly bar chart ──
                if (garage.fuelRecords.isNotEmpty ||
                    garage.maintenanceRecords.isNotEmpty) ...[
                  _buildMonthlyChart(theme, isDark, garage),
                  const SizedBox(height: 20),
                ],

                // ── Timeline ──
                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        LocaleService.tr('noRecords'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.4,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  _buildTimeline(theme, isDark, expenses, currency),
              ],
            ),
    );
  }

  // ── Summary cards ──────────────────────────
  Widget _buildSummaryCards(
    ThemeData theme,
    bool isDark,
    double total,
    double fuel,
    double maint,
    double fines,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.9),
                theme.colorScheme.primary.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.tr('expensesTotal'),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyService.format(total, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _miniCard(
                theme,
                isDark,
                Icons.local_gas_station,
                LocaleService.tr('expensesFuel'),
                fuel,
                Colors.blue,
                currency,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniCard(
                theme,
                isDark,
                Icons.build_circle,
                LocaleService.tr('expensesMaint'),
                maint,
                Colors.orange,
                currency,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniCard(
                theme,
                isDark,
                Icons.receipt_long,
                LocaleService.tr('expensesFines'),
                fines,
                Colors.red,
                currency,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniCard(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String label,
    double amount,
    Color color,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyService.format(amount, currency),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Car filter ─────────────────────────────
  Widget _buildCarFilter(ThemeData theme, bool isDark, List<String> cars) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(theme, isDark, '', LocaleService.tr('all'), _carFilter == ''),
          ...cars.map((c) => _chip(theme, isDark, c, c, _carFilter == c)),
        ],
      ),
    );
  }

  // ── Period filter ──────────────────────────
  Widget _buildPeriodFilter(ThemeData theme) {
    final periods = [
      ('all', LocaleService.tr('periodAll')),
      ('month', LocaleService.tr('periodMonth')),
      ('3months', LocaleService.tr('period3Months')),
      ('year', LocaleService.tr('periodYear')),
    ];
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: periods.map((p) {
          final sel = _period == p.$1;
          return GestureDetector(
            onTap: () => setState(() => _period = p.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chip(
    ThemeData theme,
    bool isDark,
    String value,
    String label,
    bool selected,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _carFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor.withOpacity(0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            color: selected
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  // ── Pie chart ──────────────────────────────
  Widget _buildPieChart(
    ThemeData theme,
    bool isDark,
    double fuel,
    double maint,
    double fines,
  ) {
    final total = fuel + maint + fines;
    final sections = <PieChartSectionData>[];
    if (fuel > 0)
      sections.add(
        PieChartSectionData(
          value: fuel,
          color: Colors.blue,
          title: '',
          radius: 52,
        ),
      );
    if (maint > 0)
      sections.add(
        PieChartSectionData(
          value: maint,
          color: Colors.orange,
          title: '',
          radius: 52,
        ),
      );
    if (fines > 0)
      sections.add(
        PieChartSectionData(
          value: fines,
          color: Colors.red,
          title: '',
          radius: 52,
        ),
      );

    if (sections.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 28,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fuel > 0)
                  _legendRow(
                    Colors.blue,
                    LocaleService.tr('expensesFuel'),
                    fuel,
                    total,
                  ),
                if (maint > 0)
                  _legendRow(
                    Colors.orange,
                    LocaleService.tr('expensesMaint'),
                    maint,
                    total,
                  ),
                if (fines > 0)
                  _legendRow(
                    Colors.red,
                    LocaleService.tr('expensesFines'),
                    fines,
                    total,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, double amount, double total) {
    final pct = (amount / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly bar chart ──────────────────────
  Widget _buildMonthlyChart(
    ThemeData theme,
    bool isDark,
    GarageProvider garage,
  ) {
    // Build monthly totals for last 6 months
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      return d;
    });

    final monthData = <int, double>{};
    for (int i = 0; i < months.length; i++) {
      monthData[i] = 0;
    }

    void addToMonth(int ts, double amt) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      for (int i = 0; i < months.length; i++) {
        final m = months[i];
        if (dt.year == m.year && dt.month == m.month) {
          monthData[i] = (monthData[i] ?? 0) + amt;
          break;
        }
      }
    }

    for (final r in garage.fuelRecords) {
      addToMonth(r.timestamp, double.tryParse(r.total) ?? 0);
    }
    for (final m in garage.maintenanceRecords) {
      addToMonth(m.timestamp, double.tryParse(m.cost) ?? 0);
    }
    for (final f in _fines) {
      addToMonth(f.timestamp, f.amount);
    }

    final maxY = monthData.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxY == 0) return const SizedBox.shrink();

    final localeCode = LocaleService.locale.value.languageCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleService.tr('expensesMonthly'),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.2,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: theme.dividerColor.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length)
                          return const SizedBox.shrink();
                        final monthLabel = DateFormat(
                          'MMM',
                          localeCode,
                        ).format(months[i]);
                        return Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.5),
                          ),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                ),
                barGroups: List.generate(
                  months.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthData[i] ?? 0,
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ───────────────────────────────
  Widget _buildTimeline(
    ThemeData theme,
    bool isDark,
    List<_Expense> expenses,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleService.tr('expensesHistory'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.55),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...expenses.map((e) => _buildItem(theme, isDark, e, currency)),
      ],
    );
  }

  Widget _buildItem(ThemeData theme, bool isDark, _Expense e, String currency) {
    final (icon, color) = switch (e.type) {
      _ExpType.fuel => (Icons.local_gas_station, Colors.blue),
      _ExpType.maintenance => (Icons.build_circle, Colors.orange),
      _ExpType.fine => (Icons.receipt_long, Colors.red),
    };
    final typeLabel = switch (e.type) {
      _ExpType.fuel => LocaleService.tr('expensesFuel'),
      _ExpType.maintenance => LocaleService.tr('expensesMaint'),
      _ExpType.fine => LocaleService.tr('expensesFines'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        e.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (e.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    e.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyService.format(e.amount, currency),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              Text(
                e.date,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                ),
              ),
            ],
          ),
          if (e.type == _ExpType.fine && e.fineId != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _deleteFine(e.fineId!),
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Empty ──────────────────────────────────
  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 70,
            color: theme.colorScheme.primary.withOpacity(0.25),
          ),
          const SizedBox(height: 14),
          Text(
            LocaleService.tr('expensesEmpty'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            LocaleService.tr('expensesEmptyHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Add fine dialog ────────────────────────
  Future<void> _showAddFineDialog(GarageProvider garage) async {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedCar = garage.cars.isNotEmpty
        ? garage.currentCar?.title ?? garage.cars.first.title
        : null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDia) {
          final theme = Theme.of(ctx2);
          return AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              LocaleService.tr('addFine'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (garage.cars.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedCar,
                    decoration: InputDecoration(
                      labelText: LocaleService.tr('carLabel'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: garage.cars
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.title,
                            child: Text(c.title),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDia(() => selectedCar = v),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: LocaleService.tr('fineAmount'),
                    suffixText:
                        context.read<AuthProvider>().user?.settings['currency']
                            as String? ??
                        '₸',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: LocaleService.tr('fineDescription'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocaleService.tr('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final amt = double.tryParse(
                    amtCtrl.text.trim().replaceAll(',', '.'),
                  );
                  if (amt == null || amt <= 0) return;
                  final now = DateTime.now();
                  final fine = FineRecord(
                    id: now.millisecondsSinceEpoch.toString(),
                    userId: _userId,
                    carTitle: selectedCar ?? '',
                    date:
                        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
                    timestamp: now.millisecondsSinceEpoch,
                    description: descCtrl.text.trim(),
                    amount: amt,
                  );
                  setState(() => _fines.add(fine));
                  _saveFines();
                  Navigator.pop(ctx);
                },
                child: Text(LocaleService.tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteFine(String fineId) {
    setState(() => _fines.removeWhere((f) => f.id == fineId));
    _saveFines();
  }
}

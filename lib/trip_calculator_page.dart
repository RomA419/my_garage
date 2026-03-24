import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'currency_service.dart';
import 'garage_provider.dart';
import 'locale_service.dart';

// ──────────────────────────────────────────────
//  Trip Calculator — Калькулятор поездки (v2)
// ──────────────────────────────────────────────

class TripCalculatorPage extends StatefulWidget {
  const TripCalculatorPage({super.key});

  @override
  State<TripCalculatorPage> createState() => _TripCalculatorPageState();
}

class _TripCalculatorPageState extends State<TripCalculatorPage>
    with SingleTickerProviderStateMixin {
  final _distCtrl = TextEditingController();
  final _consCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _speedCtrl = TextEditingController(text: '90');

  double? _fuelNeeded;
  double? _totalCost;
  Duration? _duration;
  bool _roundTrip = false;
  bool _calculated = false;

  int _selectedFuel = 0; // index into _fuelTypes
  static const _fuelTypes = ['АИ-92', 'АИ-95', 'АИ-98', 'ДТ', 'Газ'];
  static const _fuelPrices = [237, 312, 349, 335, 112]; // avg KZ tenges/liter 2026

  late AnimationController _resultAnim;
  late Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _resultFade = CurvedAnimation(parent: _resultAnim, curve: Curves.easeOut);
    _priceCtrl.text = _fuelPrices[_selectedFuel].toString();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  void _prefill() {
    final garage = context.read<GarageProvider>();
    final records = garage.currentCarRecords;
    // Try to compute average consumption from odometer+quantity pairs
    if (records.length >= 2) {
      double totalLiters = 0, totalKm = 0;
      for (int i = 0; i < records.length - 1; i++) {
        final odo1 = double.tryParse(records[i].odometer ?? '');
        final odo2 = double.tryParse(records[i + 1].odometer ?? '');
        final liters = double.tryParse(records[i].quantity.replaceAll(',', '.'));
        if (odo1 != null && odo2 != null && liters != null) {
          final delta = (odo1 - odo2).abs();
          if (delta > 0 && delta < 5000) {
            totalLiters += liters;
            totalKm += delta;
          }
        }
      }
      if (totalKm > 0) {
        _consCtrl.text = (totalLiters / totalKm * 100).toStringAsFixed(1);
      }
    }
  }

  void _selectFuel(int index) {
    setState(() {
      _selectedFuel = index;
      _priceCtrl.text = _fuelPrices[index].toString();
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final dist = double.tryParse(_distCtrl.text.replaceAll(',', '.'));
    final cons = double.tryParse(_consCtrl.text.replaceAll(',', '.'));
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    final speed = double.tryParse(_speedCtrl.text.replaceAll(',', '.'));

    if (dist == null || cons == null || dist <= 0 || cons <= 0) return;

    final effectiveDist = _roundTrip ? dist * 2 : dist;
    final fuel = effectiveDist * cons / 100;
    final cost = price != null && price > 0 ? fuel * price : null;
    final dur = speed != null && speed > 0
        ? Duration(minutes: (effectiveDist / speed * 60).round())
        : null;

    setState(() {
      _fuelNeeded = fuel;
      _totalCost = cost;
      _duration = dur;
      _calculated = true;
    });
    _resultAnim.forward(from: 0);
  }

  void _applyRoute(_Route route) {
    _distCtrl.text = route.km.toString();
    _calculate();
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    _distCtrl.dispose();
    _consCtrl.dispose();
    _priceCtrl.dispose();
    _speedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = LocaleService.tr;
    final currency =
        context.watch<AuthProvider>().user?.settings['currency'] as String? ??
            '₸';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ──
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: Colors.indigoAccent,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(tr('tripTitle'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF536DFE), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 30, bottom: 10),
                    child: Icon(Icons.route_rounded,
                        size: 72, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Fuel type chips ──
                  Text(tr('tripFuelType'),
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.5),
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fuelTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final sel = i == _selectedFuel;
                        return GestureDetector(
                          onTap: () => _selectFuel(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? Colors.indigoAccent
                                  : (isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel
                                      ? Colors.indigoAccent
                                      : theme.dividerColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              '${_fuelTypes[i]}  ${_fuelPrices[i]}₸',
                              style: TextStyle(
                                color: sel ? Colors.white : theme.textTheme.bodyMedium?.color,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Input card ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: theme.dividerColor.withOpacity(0.12)),
                    ),
                    child: Column(
                      children: [
                        _field(theme, isDark, _distCtrl,
                            tr('tripDistanceKm'), Icons.straighten),
                        const SizedBox(height: 12),
                        _field(theme, isDark, _consCtrl,
                            tr('tripConsumption'), Icons.local_gas_station),
                        const SizedBox(height: 12),
                        _field(theme, isDark, _priceCtrl,
                            tr('tripFuelPrice'), Icons.price_check),
                        const SizedBox(height: 12),
                        _field(theme, isDark, _speedCtrl,
                            tr('tripAvgSpeed'), Icons.speed),
                        const SizedBox(height: 16),

                        // Round trip toggle
                        GestureDetector(
                          onTap: () =>
                              setState(() => _roundTrip = !_roundTrip),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _roundTrip
                                  ? Colors.indigoAccent.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _roundTrip
                                      ? Colors.indigoAccent
                                      : theme.dividerColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _roundTrip
                                      ? Icons.swap_horiz
                                      : Icons.arrow_forward,
                                  color: _roundTrip
                                      ? Colors.indigoAccent
                                      : theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.4),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _roundTrip
                                      ? tr('tripRoundTrip')
                                      : tr('tripOneWay'),
                                  style: TextStyle(
                                    color: _roundTrip
                                        ? Colors.indigoAccent
                                        : theme.textTheme.bodyMedium?.color,
                                    fontWeight: _roundTrip
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _roundTrip
                                      ? const Icon(Icons.check_circle,
                                          key: ValueKey(true),
                                          color: Colors.indigoAccent,
                                          size: 22)
                                      : Icon(Icons.circle_outlined,
                                          key: const ValueKey(false),
                                          color: theme
                                              .textTheme.bodySmall?.color
                                              ?.withOpacity(0.25),
                                          size: 22),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Calculate button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _calculate,
                            icon: const Icon(Icons.calculate_rounded),
                            label: Text(tr('tripCalculate'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Results ──
                  const SizedBox(height: 22),
                  if (_calculated && _fuelNeeded != null)
                    FadeTransition(
                      opacity: _resultFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('tripResults'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _resultTile(
                                  theme,
                                  isDark,
                                  Icons.opacity_rounded,
                                  tr('tripFuelNeeded'),
                                  '${_fuelNeeded!.toStringAsFixed(1)} ${tr('tripLiters')}',
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_totalCost != null)
                                Expanded(
                                  child: _resultTile(
                                    theme,
                                    isDark,
                                    Icons.payments_rounded,
                                    tr('tripTotalCost'),
                                    CurrencyService.format(
                                        _totalCost!, currency),
                                    Colors.redAccent,
                                  ),
                                ),
                            ],
                          ),
                          if (_duration != null) ...[
                            const SizedBox(height: 12),
                            _resultTile(
                              theme,
                              isDark,
                              Icons.timer_rounded,
                              tr('tripDuration'),
                              '${_duration!.inHours} ${tr('tripHours')} ${_duration!.inMinutes % 60} ${tr('tripMin')}',
                              Colors.orange,
                            ),
                          ],
                        ],
                      ),
                    )
                  else if (!_calculated)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.calculate_outlined,
                              size: 40,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.15)),
                          const SizedBox(height: 8),
                          Text(tr('tripNoData'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.4))),
                        ],
                      ),
                    ),

                  // ── Popular routes ──
                  const SizedBox(height: 28),
                  Text(tr('tripPopularRoutes'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._routes.map((r) => _routeTile(theme, isDark, r)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────

  Widget _field(ThemeData theme, bool isDark, TextEditingController ctrl,
      String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.indigoAccent, size: 21),
        labelText: label,
        labelStyle: TextStyle(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            fontSize: 14),
        filled: true,
        fillColor:
            isDark ? const Color(0xFF2A2A2A) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: theme.dividerColor.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.indigoAccent, width: 1.5)),
      ),
    );
  }

  Widget _resultTile(ThemeData theme, bool isDark, IconData icon, String label,
      String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
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
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _routeTile(ThemeData theme, bool isDark, _Route route) {
    return GestureDetector(
      onTap: () => _applyRoute(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.route_rounded,
                  size: 18, color: Colors.indigoAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${route.from} → ${route.to}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${route.km} км',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.4),
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color:
                    theme.textTheme.bodySmall?.color?.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────

class _Route {
  final String from;
  final String to;
  final int km;
  const _Route(this.from, this.to, this.km);
}

const _routes = [
  _Route('Караганда', 'Астана', 230),
  _Route('Алматы', 'Астана', 1240),
  _Route('Караганда', 'Алматы', 1050),
  _Route('Астана', 'Бурабай (Щучинск)', 260),
  _Route('Караганда', 'Балхаш', 410),
  _Route('Алматы', 'Бишкек', 245),
  _Route('Астана', 'Павлодар', 440),
  _Route('Караганда', 'Темиртау', 35),
  _Route('Алматы', 'Капшагай', 80),
  _Route('Астана', 'Костанай', 790),
];

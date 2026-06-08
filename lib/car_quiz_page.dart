import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_service.dart';

// ──────────────────────────────────────────────
//  Car Quiz — Угадай автомобиль
// ──────────────────────────────────────────────

class CarQuizPage extends StatefulWidget {
  const CarQuizPage({super.key});

  @override
  State<CarQuizPage> createState() => _CarQuizPageState();
}

class _CarQuizPageState extends State<CarQuizPage> with SingleTickerProviderStateMixin {
  static const _bestKey = 'car_quiz_best';

  final _rng = Random();
  late List<_QuizCar> _pool;
  late List<_QuizCar> _questions;
  late List<String> _currentOptions;
  int _current = 0;
  int _score = 0;
  int _best = 0;
  int? _selectedIdx;
  bool _answered = false;
  bool _isFinished = false;
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pool = List.of(_allCars)..shuffle(_rng);
    _questions = _pool.take(10).toList();
    _currentOptions = _buildOptions(_questions[_current]);
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _best = prefs.getInt(_bestKey) ?? 0);
  }

  Future<void> _saveBest() async {
    if (_score > _best) {
      _best = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, _best);
    }
  }

  List<String> _buildOptions(_QuizCar correct) {
    final options = <String>{correct.title};
    final others = _allCars.where((c) => c.title != correct.title).toList()..shuffle(_rng);
    for (final o in others) {
      if (options.length >= 4) break;
      options.add(o.title);
    }
    final list = options.toList()..shuffle(_rng);
    return list;
  }

  void _answer(int idx, String selected, String correct) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedIdx = idx;
      if (selected == correct) {
        _score++;
      } else {
        _shakeCtrl.forward(from: 0);
      }
    });
  }

  void _next() {
    if (_current + 1 >= _questions.length) {
      _saveBest();
      setState(() {
        _isFinished = true;
      });
      return;
    }
    setState(() {
      _current++;
      _currentOptions = _buildOptions(_questions[_current]);
      _answered = false;
      _selectedIdx = null;
    });
  }

  void _restart() {
    setState(() {
      _pool.shuffle(_rng);
      _questions = _pool.take(10).toList();
      _current = 0;
      _currentOptions = _buildOptions(_questions[_current]);
      _score = 0;
      _answered = false;
      _isFinished = false;
      _selectedIdx = null;
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = LocaleService.tr;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr('quizTitle'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('$_best', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isFinished
          ? _buildFinish(theme, isDark, tr)
          : _buildQuestion(theme, isDark, tr),
    );
  }

  Widget _buildQuestion(ThemeData theme, bool isDark, String Function(String) tr) {
    final q = _questions[_current];
    final options = _currentOptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Score bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_current + 1} / ${_questions.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5))),
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('$_score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Clue card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.85),
                  theme.colorScheme.primary.withOpacity(0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.help_outline_rounded, size: 48, color: Colors.white70),
                const SizedBox(height: 12),
                Text(tr('quizHint'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _clueChip(tr('quizClueBody'), q.body),
                    _clueChip(tr('quizClueEngine'), '${q.engine}L ${q.fuel}'),
                    _clueChip(tr('quizClueHP'), '${q.hp} л.с.'),
                    _clueChip(tr('quizCluePrice'), q.price),
                    _clueChip(tr('quizClueYears'), q.years),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...List.generate(options.length, (i) {
            final isCorrect = options[i] == q.title;
            final isSelected = _selectedIdx == i;
            Color? bgColor;
            Color? borderColor;

            if (_answered) {
              if (isCorrect) {
                bgColor = Colors.green.withOpacity(0.15);
                borderColor = Colors.green;
              } else if (isSelected) {
                bgColor = Colors.red.withOpacity(0.15);
                borderColor = Colors.red;
              }
            }

            Widget card = GestureDetector(
              onTap: () => _answer(i, options[i], q.title),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: bgColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor ?? theme.dividerColor.withOpacity(0.2),
                    width: borderColor != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(_answered && isCorrect ? 0.3 : 0.1),
                      ),
                      child: Center(
                        child: _answered
                            ? Icon(
                                isCorrect ? Icons.check : (isSelected ? Icons.close : null),
                                size: 18,
                                color: isCorrect ? Colors.green : Colors.red,
                              )
                            : Text(
                                String.fromCharCode(65 + i), // A, B, C, D
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        options[i],
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );

            // Shake animation on wrong answer
            if (_answered && isSelected && !isCorrect) {
              card = AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (_, child) {
                  final offset = sin(_shakeCtrl.value * pi * 4) * 8;
                  return Transform.translate(offset: Offset(offset, 0), child: child);
                },
                child: card,
              );
            }

            return card;
          }),

          if (_answered) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _current + 1 >= _questions.length ? tr('quizFinished') : tr('quizNext'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinish(ThemeData theme, bool isDark, String Function(String) tr) {
    final pct = (_score / _questions.length * 100).toInt();
    final color = pct >= 70 ? Colors.green : pct >= 40 ? Colors.orange : Colors.red;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pct >= 70 ? Icons.emoji_events : pct >= 40 ? Icons.sentiment_satisfied : Icons.sentiment_dissatisfied,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 20),
            Text(tr('quizFinished'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              '$_score / ${_questions.length}',
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text('$pct%', style: theme.textTheme.titleLarge?.copyWith(color: color.withOpacity(0.7))),
            if (_score >= _best) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text('${tr('quizBest')}: $_score', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700])),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay),
              label: Text(tr('quizRestart'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clueChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Quiz car database
// ──────────────────────────────────────────────
class _QuizCar {
  final String brand;
  final String model;
  final String body;
  final double engine;
  final String fuel;
  final int hp;
  final String years;
  final String price;

  const _QuizCar({
    required this.brand,
    required this.model,
    required this.body,
    required this.engine,
    required this.fuel,
    required this.hp,
    required this.years,
    required this.price,
  });

  String get title => '$brand $model';
}

const _allCars = <_QuizCar>[
  _QuizCar(brand: 'Toyota', model: 'Camry', body: 'Sedan', engine: 2.5, fuel: 'бензин', hp: 200, years: '2017-2024', price: '12-18 млн'),
  _QuizCar(brand: 'Toyota', model: 'Land Cruiser 300', body: 'SUV', engine: 3.5, fuel: 'бензин', hp: 415, years: '2021-2024', price: '40-55 млн'),
  _QuizCar(brand: 'Toyota', model: 'RAV4', body: 'Crossover', engine: 2.0, fuel: 'бензин', hp: 150, years: '2019-2024', price: '14-20 млн'),
  _QuizCar(brand: 'Kia', model: 'K5', body: 'Sedan', engine: 2.5, fuel: 'бензин', hp: 194, years: '2020-2024', price: '12-16 млн'),
  _QuizCar(brand: 'Kia', model: 'Sportage', body: 'Crossover', engine: 2.0, fuel: 'бензин', hp: 150, years: '2021-2024', price: '13-19 млн'),
  _QuizCar(brand: 'Hyundai', model: 'Tucson', body: 'Crossover', engine: 2.0, fuel: 'бензин', hp: 150, years: '2021-2024', price: '13-18 млн'),
  _QuizCar(brand: 'Hyundai', model: 'Sonata', body: 'Sedan', engine: 2.5, fuel: 'бензин', hp: 194, years: '2019-2024', price: '12-17 млн'),
  _QuizCar(brand: 'BMW', model: 'X5', body: 'SUV', engine: 3.0, fuel: 'бензин', hp: 340, years: '2018-2024', price: '30-50 млн'),
  _QuizCar(brand: 'BMW', model: '320i', body: 'Sedan', engine: 2.0, fuel: 'бензин', hp: 184, years: '2019-2024', price: '18-25 млн'),
  _QuizCar(brand: 'Mercedes', model: 'E-Class', body: 'Sedan', engine: 2.0, fuel: 'бензин', hp: 197, years: '2020-2024', price: '25-38 млн'),
  _QuizCar(brand: 'Mercedes', model: 'GLE', body: 'SUV', engine: 3.0, fuel: 'дизель', hp: 272, years: '2019-2024', price: '35-50 млн'),
  _QuizCar(brand: 'Volkswagen', model: 'Tiguan', body: 'Crossover', engine: 2.0, fuel: 'бензин', hp: 150, years: '2020-2024', price: '14-20 млн'),
  _QuizCar(brand: 'Volkswagen', model: 'Polo', body: 'Sedan', engine: 1.6, fuel: 'бензин', hp: 110, years: '2020-2024', price: '7-10 млн'),
  _QuizCar(brand: 'Chevrolet', model: 'Cobalt', body: 'Sedan', engine: 1.5, fuel: 'бензин', hp: 106, years: '2020-2024', price: '5-8 млн'),
  _QuizCar(brand: 'Chevrolet', model: 'Tracker', body: 'Crossover', engine: 1.0, fuel: 'бензин', hp: 116, years: '2020-2024', price: '8-12 млн'),
  _QuizCar(brand: 'Lexus', model: 'RX 350', body: 'Crossover', engine: 3.5, fuel: 'бензин', hp: 295, years: '2019-2024', price: '28-40 млн'),
  _QuizCar(brand: 'Lexus', model: 'LX 600', body: 'SUV', engine: 3.5, fuel: 'бензин', hp: 409, years: '2021-2024', price: '50-70 млн'),
  _QuizCar(brand: 'Subaru', model: 'Outback', body: 'Crossover', engine: 2.5, fuel: 'бензин', hp: 175, years: '2019-2024', price: '15-22 млн'),
  _QuizCar(brand: 'Honda', model: 'CR-V', body: 'Crossover', engine: 1.5, fuel: 'бензин', hp: 193, years: '2017-2024', price: '12-18 млн'),
  _QuizCar(brand: 'Nissan', model: 'Qashqai', body: 'Crossover', engine: 1.3, fuel: 'бензин', hp: 150, years: '2021-2024', price: '12-17 млн'),
  _QuizCar(brand: 'Mitsubishi', model: 'Outlander', body: 'Crossover', engine: 2.5, fuel: 'бензин', hp: 181, years: '2021-2024', price: '16-22 млн'),
  _QuizCar(brand: 'Lada', model: 'Vesta', body: 'Sedan', engine: 1.6, fuel: 'бензин', hp: 113, years: '2015-2024', price: '4-7 млн'),
  _QuizCar(brand: 'Lada', model: 'Granta', body: 'Sedan', engine: 1.6, fuel: 'бензин', hp: 87, years: '2011-2024', price: '3-5 млн'),
  _QuizCar(brand: 'Audi', model: 'Q7', body: 'SUV', engine: 3.0, fuel: 'дизель', hp: 249, years: '2019-2024', price: '30-45 млн'),
  _QuizCar(brand: 'Audi', model: 'A4', body: 'Sedan', engine: 2.0, fuel: 'бензин', hp: 190, years: '2019-2024', price: '18-25 млн'),
  _QuizCar(brand: 'Porsche', model: 'Cayenne', body: 'SUV', engine: 3.0, fuel: 'бензин', hp: 340, years: '2018-2024', price: '40-60 млн'),
  _QuizCar(brand: 'Tesla', model: 'Model 3', body: 'Sedan', engine: 0.0, fuel: 'электро', hp: 283, years: '2019-2024', price: '20-30 млн'),
  _QuizCar(brand: 'Mazda', model: 'CX-5', body: 'Crossover', engine: 2.5, fuel: 'бензин', hp: 194, years: '2017-2024', price: '13-20 млн'),
  _QuizCar(brand: 'Skoda', model: 'Octavia', body: 'Sedan', engine: 1.4, fuel: 'бензин', hp: 150, years: '2020-2024', price: '10-15 млн'),
  _QuizCar(brand: 'Geely', model: 'Coolray', body: 'Crossover', engine: 1.5, fuel: 'бензин', hp: 150, years: '2020-2024', price: '8-12 млн'),
];

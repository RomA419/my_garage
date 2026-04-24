import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'currency_service.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'models.dart';

String _trType(String type) {
  if (LocaleService.isRu) return type;
  const _en = {
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
  return _en[type] ?? type;
}

class _MileageRecommendation {
  const _MileageRecommendation({
    required this.type,
    required this.remainingKm,
    required this.startMileage,
    required this.dueMileage,
    required this.intervalKm,
  });

  final String type;
  final int remainingKm;
  final int startMileage;
  final int dueMileage;
  final int intervalKm;
}

class _ScopedMaintenanceStatus {
  const _ScopedMaintenanceStatus({
    required this.carTitle,
    required this.mileage,
    required this.lastRecord,
    required this.nearestRecommendation,
    required this.nextServices,
  });

  final String carTitle;
  final double mileage;
  final MaintenanceRecord? lastRecord;
  final _MileageRecommendation nearestRecommendation;
  final List<String> nextServices;
}

class _RecommendationDisplayItem {
  const _RecommendationDisplayItem({
    required this.recommendation,
    required this.serviceLabel,
  });

  final _MileageRecommendation recommendation;
  final String serviceLabel;
}

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  static const _showAllCarsSettingsKey = 'maintenanceShowAllCars';

  bool _showAllCars = false;
  bool _scopeLoadedFromSettings = false;

  static const _types = [
    'Замена масла',
    'Замена фильтра',
    'Замена тормозной жидкости',
    'Замена тормозных колодок',
    'Замена свечей зажигания',
    'Замена ремня ГРМ',
    'Замена шин',
    'Плановое ТО',
    'Промывка инжектора',
    'Диагностика',
    'Другое',
  ];

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scopeLoadedFromSettings) return;

    final settings = context.read<AuthProvider>().user?.settings;
    final savedScope = settings?[_showAllCarsSettingsKey];
    _showAllCars = savedScope is bool ? savedScope : false;
    _scopeLoadedFromSettings = true;
  }

  Future<void> _setShowAllCars(bool value) async {
    if (_showAllCars == value) return;

    setState(() => _showAllCars = value);
    await context.read<AuthProvider>().updateSettings({
      _showAllCarsSettingsKey: value,
    });
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

  List<_MileageRecommendation> _buildMileageRecommendations(
    int mileageKm,
    Map<String, int> typeIntervals,
    List<MaintenanceRecord> carRecords,
  ) {
    final recommendationIntervals = Map<String, int>.fromEntries(
      typeIntervals.entries.where(
        (entry) => entry.key.trim().isNotEmpty && entry.value > 0,
      ),
    );

    final lastMileageByType = <String, int>{};
    for (final record in carRecords) {
      final value = int.tryParse(record.odometer);
      if (value != null && value > 0) {
        final previousValue = lastMileageByType[record.type];
        if (previousValue == null || value > previousValue) {
          lastMileageByType[record.type] = value;
        }
      }
    }

    final result = <_MileageRecommendation>[];
    for (final entry in recommendationIntervals.entries) {
      final interval = entry.value;
      if (interval <= 0) continue;
      final lastMileage = lastMileageByType[entry.key];
      late final int remainingKm;
      late final int startMileage;
      late final int dueMileage;
      if (lastMileage != null) {
        dueMileage = lastMileage + interval;
        startMileage = lastMileage;
        remainingKm = dueMileage - mileageKm;
      } else {
        final remainder = mileageKm % interval;
        startMileage = (mileageKm ~/ interval) * interval;
        dueMileage = remainder == 0 ? mileageKm : startMileage + interval;
        remainingKm = dueMileage - mileageKm;
      }
      result.add(
        _MileageRecommendation(
          type: entry.key,
          remainingKm: remainingKm,
          startMileage: startMileage,
          dueMileage: dueMileage,
          intervalKm: interval,
        ),
      );
    }

    result.sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
    return result;
  }

  // Регламент ТО с правильными интервалами
  static const _maintenanceSchedule = {
    'ТО-1 (10,000 км)': {
      'km': 10000,
      'services': [
        'Замена масла',
        'Замена масляного фильтра',
        'Проверка уровней жидкостей',
        'Проверка тормозной системы',
      ],
    },
    'ТО-2 (20,000 км)': {
      'km': 20000,
      'services': [
        'Замена масла',
        'Замена масляного фильтра',
        'Замена воздушного фильтра',
        'Замена свечей зажигания',
        'Проверка подвески',
        'Проверка системы охлаждения',
      ],
    },
    'ТО-3 (30,000 км)': {
      'km': 30000,
      'services': [
        'Замена масла',
        'Замена масляного фильтра',
        'Замена топливного фильтра',
        'Замена тормозных колодок',
        'Проверка электрооборудования',
      ],
    },
    'ТО-4 (40,000 км)': {
      'km': 40000,
      'services': [
        'Замена масла',
        'Замена масляного фильтра',
        'Замена ремня ГРМ',
        'Замена шин',
        'Диагностика двигателя',
      ],
    },
    'ТО-5 (50,000 км)': {
      'km': 50000,
      'services': [
        'Замена масла',
        'Замена масляного фильтра',
        'Замена антифриза',
        'Замена тормозной жидкости',
        'Полная диагностика',
      ],
    },
  };

  List<MaintenanceRecord> _getScopedMaintenanceRecords(
    GarageProvider garage, {
    String? carNumber,
  }) {
    final targetCarNumber = carNumber ?? garage.currentCar?.number;
    final records = (_showAllCars && carNumber == null)
        ? List<MaintenanceRecord>.from(garage.maintenanceRecords)
        : garage.maintenanceRecords
              .where((record) => record.carNumber == targetCarNumber)
              .toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  List<FuelRecordModel> _getScopedFuelRecords(
    GarageProvider garage, {
    String? carNumber,
  }) {
    final targetCarNumber = carNumber ?? garage.currentCar?.number;
    if (_showAllCars && carNumber == null) {
      return List<FuelRecordModel>.from(garage.fuelRecords);
    }
    return garage.fuelRecords
        .where((record) => record.carNumber == targetCarNumber)
        .toList();
  }

  double? _getMileageForScope(GarageProvider garage, {String? carNumber}) {
    final fuelRecords = _getScopedFuelRecords(garage, carNumber: carNumber);
    final maintenanceRecords = _getScopedMaintenanceRecords(
      garage,
      carNumber: carNumber,
    );

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

  _ScopedMaintenanceStatus? _buildStatusForCar(
    GarageProvider garage,
    Map<String, int> typeIntervals,
    CarModel car,
  ) {
    final carRecords = _getScopedMaintenanceRecords(
      garage,
      carNumber: car.number,
    );
    final mileage = _getMileageForScope(garage, carNumber: car.number);
    if (mileage == null) return null;

    final mileageRecommendations = _buildMileageRecommendations(
      mileage.toInt(),
      typeIntervals,
      carRecords,
    );
    if (mileageRecommendations.isEmpty) return null;

    var nextServices = const <String>[];
    for (final entry in _maintenanceSchedule.entries) {
      final km = entry.value['km'] as int;
      if (mileage <= km) {
        nextServices = List<String>.from(entry.value['services'] as List);
        break;
      }
    }

    return _ScopedMaintenanceStatus(
      carTitle: car.title.isNotEmpty ? car.title : car.number,
      mileage: mileage,
      lastRecord: carRecords.isNotEmpty ? carRecords.first : null,
      nearestRecommendation: mileageRecommendations.first,
      nextServices: nextServices,
    );
  }

  Widget _buildScopeToggle(ThemeData theme) {
    final tr = LocaleService.tr;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: Text(tr('maintenanceScopeCurrentCar')),
            selected: !_showAllCars,
            onSelected: (_) => _setShowAllCars(false),
          ),
          ChoiceChip(
            label: Text(tr('maintenanceScopeAllCars')),
            selected: _showAllCars,
            onSelected: (_) => _setShowAllCars(true),
          ),
        ],
      ),
    );
  }

  List<_RecommendationDisplayItem> _buildRecommendationDisplayItems(
    List<_MileageRecommendation> recommendations,
  ) {
    return recommendations
        .take(4)
        .map(
          (item) => _RecommendationDisplayItem(
            recommendation: item,
            serviceLabel: _trType(item.type),
          ),
        )
        .toList();
  }

  List<_RecommendationDisplayItem> _buildScopedRecommendationDisplayItems(
    List<_ScopedMaintenanceStatus> statuses,
  ) {
    final tr = LocaleService.tr;
    return statuses
        .take(4)
        .map(
          (item) => _RecommendationDisplayItem(
            recommendation: item.nearestRecommendation,
            serviceLabel: tr('maintenanceRecommendForCar')
                .replaceAll(
                  '{service}',
                  _trType(item.nearestRecommendation.type),
                )
                .replaceAll('{car}', item.carTitle),
          ),
        )
        .toList();
  }

  String _planStatusKey(_MileageRecommendation recommendation) {
    if (recommendation.remainingKm < 0) return 'maintenancePlanOverdue';
    if (recommendation.remainingKm == 0) return 'maintenancePlanNow';
    if (recommendation.remainingKm <= 2000) return 'maintenancePlanSoon';
    return 'maintenancePlanPlanned';
  }

  Color _planStatusColor(
    ThemeData theme,
    _MileageRecommendation recommendation,
  ) {
    if (recommendation.remainingKm < 0) return Colors.red;
    if (recommendation.remainingKm == 0) return Colors.deepOrange;
    if (recommendation.remainingKm <= 2000) return Colors.orange;
    return theme.colorScheme.primary;
  }

  String _planStatusHint(_RecommendationDisplayItem item) {
    final tr = LocaleService.tr;
    final remainingKm = item.recommendation.remainingKm;
    if (remainingKm < 0) {
      return tr(
        'maintenancePlanOverdueByKmShort',
      ).replaceAll('{km}', '${remainingKm.abs()}');
    }
    if (remainingKm == 0) {
      return tr('maintenancePlanNowHint');
    }
    return tr('maintenancePlanInKm').replaceAll('{km}', '$remainingKm');
  }

  Widget _buildPlanRow(
    ThemeData theme,
    _RecommendationDisplayItem item, {
    IconData icon = Icons.check_circle_outline,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: _planStatusColor(theme, item.recommendation),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.serviceLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _planStatusHint(item),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(MaintenanceRecord existingRecord) {
    final costCtrl = TextEditingController(text: existingRecord.cost);
    final odometerCtrl = TextEditingController(text: existingRecord.odometer);
    final notesCtrl = TextEditingController(text: existingRecord.notes);
    String selectedType = existingRecord.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LocaleService.tr('editMaintenanceRecord'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? Colors.grey.shade900
                              : Colors.white,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                          ),
                          items: _types
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_trType(t)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() => selectedType = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      theme,
                      costCtrl,
                      LocaleService.tr('maintenanceCost'),
                      Icons.payments_outlined,
                      isNumber: true,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      theme,
                      odometerCtrl,
                      LocaleService.tr('odometerKm'),
                      Icons.speed,
                      isNumber: true,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      theme,
                      notesCtrl,
                      LocaleService.tr('maintenanceNotes'),
                      Icons.notes,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final garage = context.read<GarageProvider>();
                          final updatedRecord = existingRecord.copyWith(
                            type: selectedType,
                            cost: costCtrl.text.trim().isEmpty
                                ? '0'
                                : costCtrl.text.trim(),
                            odometer: odometerCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                          );
                          await garage.updateMaintenanceRecord(updatedRecord);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleService.tr('maintenanceUpdated'),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          LocaleService.tr('save'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDialog() {
    final costCtrl = TextEditingController();
    final odometerCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedType = _types.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LocaleService.tr('addMaintenanceRecord'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Тип работ — dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? Colors.grey.shade900
                              : Colors.white,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                          ),
                          items: _types
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_trType(t)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() => selectedType = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _field(
                      theme,
                      costCtrl,
                      LocaleService.tr('maintenanceCost'),
                      Icons.payments_outlined,
                      isNumber: true,
                    ),
                    const SizedBox(height: 14),

                    _field(
                      theme,
                      odometerCtrl,
                      LocaleService.tr('odometerKm'),
                      Icons.speed,
                      isNumber: true,
                    ),
                    const SizedBox(height: 14),

                    _field(
                      theme,
                      notesCtrl,
                      LocaleService.tr('maintenanceNotes'),
                      Icons.notes,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final garage = context.read<GarageProvider>();
                          final auth = context.read<AuthProvider>();
                          final currentCar = garage.currentCar;
                          final now = DateTime.now();
                          final record = MaintenanceRecord(
                            userId: auth.userId!,
                            carId: currentCar?.id,
                            carTitle: currentCar?.title ?? '',
                            carNumber: currentCar?.number ?? '',
                            type: selectedType,
                            date:
                                '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
                            timestamp: now.millisecondsSinceEpoch,
                            cost: costCtrl.text.trim().isEmpty
                                ? '0'
                                : costCtrl.text.trim(),
                            odometer: odometerCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                          );
                          await garage.addMaintenanceRecord(record);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LocaleService.tr('maintenanceAdded'),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          LocaleService.tr('save'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMaintenanceStatusCard(ThemeData theme) {
    final garage = context.watch<GarageProvider>();
    final auth = context.watch<AuthProvider>();
    final tr = LocaleService.tr;
    final typeIntervals = _serviceIntervalsFromSettings(auth.user?.settings);
    final carRecords = _getScopedMaintenanceRecords(garage);
    final lastRecord = carRecords.isNotEmpty ? carRecords.first : null;
    final fallbackMileage = _getMileageForScope(garage);
    final fallbackRecommendations = fallbackMileage == null
        ? const <_MileageRecommendation>[]
        : _buildMileageRecommendations(
            fallbackMileage.toInt(),
            typeIntervals,
            carRecords,
          );
    final status = _showAllCars
        ? (garage.cars
              .map((car) => _buildStatusForCar(garage, typeIntervals, car))
              .whereType<_ScopedMaintenanceStatus>()
              .toList()
            ..sort(
              (a, b) => a.nearestRecommendation.remainingKm.compareTo(
                b.nearestRecommendation.remainingKm,
              ),
            ))
        : [
            if (garage.currentCar != null)
              _buildStatusForCar(garage, typeIntervals, garage.currentCar!),
          ].whereType<_ScopedMaintenanceStatus>().toList();

    final activeStatus = status.isNotEmpty ? status.first : null;
    final mileage = activeStatus?.mileage ?? fallbackMileage;
    final nearestRecommendation =
        activeStatus?.nearestRecommendation ??
        (fallbackRecommendations.isNotEmpty
            ? fallbackRecommendations.first
            : null);
    final nextServices = activeStatus?.nextServices ?? const <String>[];
    final statusCarTitle = activeStatus?.carTitle;
    final displayedLastRecord = _showAllCars
        ? activeStatus?.lastRecord ?? lastRecord
        : lastRecord;
    final recommendationItems = _showAllCars
        ? _buildScopedRecommendationDisplayItems(status)
        : _buildRecommendationDisplayItems(fallbackRecommendations);

    int? distanceToService;
    int? overdueBy;
    final serviceIntervalKm = nearestRecommendation?.intervalKm ?? 10000;
    if (nearestRecommendation != null) {
      if (nearestRecommendation.remainingKm >= 0) {
        distanceToService = nearestRecommendation.remainingKm;
      } else {
        overdueBy = nearestRecommendation.remainingKm.abs();
      }
    }

    final progress = () {
      if (mileage == null || nearestRecommendation == null) return 0.0;
      final span =
          nearestRecommendation.dueMileage - nearestRecommendation.startMileage;
      if (span <= 0) return 0.0;
      final value = (mileage - nearestRecommendation.startMileage) / span;
      return value.clamp(0.0, 1.0);
    }();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('maintenanceNearestTitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_showAllCars && statusCarTitle != null) ...[
            const SizedBox(height: 6),
            Text(
              tr('maintenanceForCar').replaceAll('{car}', statusCarTitle),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (mileage == null) ...[
            Text(
              tr('maintenanceNeedMileageForProgress'),
              style: theme.textTheme.bodyMedium,
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  overdueBy != null ? Icons.warning_amber_rounded : Icons.flag,
                  color: overdueBy != null ? Colors.red : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    overdueBy != null
                        ? tr(
                            'maintenanceOverdueByKm',
                          ).replaceAll('{km}', '$overdueBy')
                        : tr(
                            'maintenanceDueInKm',
                          ).replaceAll('{km}', '${distanceToService ?? 0}'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: overdueBy != null ? Colors.red : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 6),
            Text(
              nearestRecommendation != null
                  ? tr('maintenanceRegulationProgress')
                        .replaceAll(
                          '{label}',
                          _trType(nearestRecommendation.type),
                        )
                        .replaceAll('{current}', '${mileage.toInt()}')
                        .replaceAll(
                          '{target}',
                          '${nearestRecommendation.dueMileage}',
                        )
                  : tr('maintenanceRegulationFallback'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'maintenanceByLastTypeInterval',
              ).replaceAll('{km}', '$serviceIntervalKm'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('maintenanceServicePlanTitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (recommendationItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final primaryItem = recommendationItems.first;
                  final secondaryItems = recommendationItems.skip(1).toList();
                  final combineItems = secondaryItems
                      .where((item) => item.recommendation.remainingKm <= 3000)
                      .take(2)
                      .toList();
                  final laterItems = secondaryItems
                      .where((item) => !combineItems.contains(item))
                      .take(2)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('maintenancePrimaryActionTitle'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.75),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _planStatusColor(
                                      theme,
                                      primaryItem.recommendation,
                                    ).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tr(
                                      _planStatusKey(
                                        primaryItem.recommendation,
                                      ),
                                    ),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: _planStatusColor(
                                        theme,
                                        primaryItem.recommendation,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    primaryItem.serviceLabel,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _planStatusHint(primaryItem),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (combineItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          tr('maintenanceCombineWithTitle'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...combineItems.map(
                          (item) => _buildPlanRow(
                            theme,
                            item,
                            icon: Icons.merge_type,
                          ),
                        ),
                      ],
                      if (laterItems.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tr('maintenanceLaterTitle'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...laterItems.map(
                          (item) =>
                              _buildPlanRow(theme, item, icon: Icons.schedule),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: 14),
          if (displayedLastRecord != null)
            Text(
              (_showAllCars && displayedLastRecord.carTitle.isNotEmpty
                      ? '${tr('maintenanceForCar').replaceAll('{car}', displayedLastRecord.carTitle)}\n'
                      : '') +
                  tr('maintenanceLastService')
                      .replaceAll('{type}', _trType(displayedLastRecord.type))
                      .replaceAll(
                        '{odometer}',
                        displayedLastRecord.odometer.isEmpty
                            ? tr('maintenanceNoOdometerMark')
                            : '${displayedLastRecord.odometer} ${tr('km')}',
                      )
                      .replaceAll('{date}', displayedLastRecord.date),
              style: theme.textTheme.bodySmall,
            )
          else
            Text(
              _showAllCars
                  ? tr('noMaintenance')
                  : tr('maintenanceNoCarRecords'),
              style: theme.textTheme.bodySmall,
            ),
          if (nextServices.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...nextServices
                .take(3)
                .map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.playlist_add),
              label: Text(tr('maintenanceWriteNow')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    ThemeData theme,
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 22),
        labelText: label,
        labelStyle: TextStyle(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
        filled: true,
        fillColor: isDark ? Colors.black : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final garage = context.watch<GarageProvider>();
    final currency =
        context.watch<AuthProvider>().user?.settings['currency'] as String? ??
        '₸';
    final records = _getScopedMaintenanceRecords(garage);
    final tr = LocaleService.tr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr('maintenanceLog'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _buildScopeToggle(theme),
            const SizedBox(height: 12),
            _buildMaintenanceStatusCard(theme),
            const SizedBox(height: 16),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.build_circle_outlined,
                            size: 72,
                            color: theme.iconTheme.color?.withOpacity(0.18),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showAllCars
                                ? tr('noMaintenance')
                                : tr('maintenanceNoCarRecords'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _showAllCars
                                ? tr('noMaintenanceHint')
                                : tr('maintenanceCurrentCarHint'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      itemCount: records.length,
                      itemBuilder: (ctx, i) {
                        final item = records[i];
                        return Dismissible(
                          key: ValueKey('maint_${item.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) =>
                              garage.deleteMaintenanceRecord(item.id!),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.build,
                                    size: 22,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _trType(item.type),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.5),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.date,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withOpacity(0.6),
                                                  fontSize: 11,
                                                ),
                                          ),
                                          if (item.odometer.isNotEmpty) ...[
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.speed,
                                              size: 12,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.5),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item.odometer} ${tr('km')}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color
                                                        ?.withOpacity(0.6),
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (item.carTitle.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.directions_car,
                                              size: 12,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.4),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.carTitle,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color
                                                        ?.withOpacity(0.5),
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (item.notes.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          item.notes,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color
                                                    ?.withOpacity(0.65),
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(item),
                                      color: theme.colorScheme.primary,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyService.format(
                                        double.tryParse(item.cost) ?? 0,
                                        currency,
                                      ),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

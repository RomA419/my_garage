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

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
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

  List<MapEntry<String, int>> _buildMileageRecommendations(
    int mileageKm,
    Map<String, int> typeIntervals,
    List<MaintenanceRecord> carRecords,
  ) {
    final recommendationIntervals = <String, int>{
      'Замена масла': typeIntervals['Замена масла'] ?? 10000,
      'Замена тормозной жидкости':
          typeIntervals['Замена тормозной жидкости'] ?? 40000,
      'Замена тормозных колодок':
          typeIntervals['Замена тормозных колодок'] ?? 20000,
      'Замена фильтра': typeIntervals['Замена фильтра'] ?? 15000,
    };

    final lastMileageByType = <String, int>{};
    for (final record in carRecords) {
      if (lastMileageByType.containsKey(record.type)) continue;
      final value = int.tryParse(record.odometer);
      if (value != null && value > 0) {
        lastMileageByType[record.type] = value;
      }
    }

    final result = <MapEntry<String, int>>[];
    for (final entry in recommendationIntervals.entries) {
      final interval = entry.value;
      if (interval <= 0) continue;
      final lastMileage = lastMileageByType[entry.key];
      int remainingKm;
      if (lastMileage != null) {
        final delta = (lastMileage + interval) - mileageKm;
        remainingKm = delta;
      } else {
        final remainder = mileageKm % interval;
        remainingKm = remainder == 0 ? 0 : interval - remainder;
      }
      result.add(MapEntry(entry.key, remainingKm));
    }

    result.sort((a, b) => a.value.compareTo(b.value));
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

  // Получить текущий пробег автомобиля
  double? _getCurrentMileage(GarageProvider garage) {
    final currentCar = garage.currentCar;
    if (currentCar == null) return null;
    // Собираем все odometer из fuel records и maintenance records
    final fuelRecords = garage.fuelRecords
        .where((r) => r.carNumber == currentCar.number)
        .toList();
    final maintenanceRecords = garage.maintenanceRecords
        .where((r) => r.carNumber == currentCar.number)
        .toList();

    double maxMileage = 0;

    // Из fuel records
    for (final record in fuelRecords) {
      final mileage = double.tryParse(record.odometer ?? '0') ?? 0;
      if (mileage > maxMileage) maxMileage = mileage;
    }

    // Из maintenance records
    for (final record in maintenanceRecords) {
      final mileage = double.tryParse(record.odometer ?? '0') ?? 0;
      if (mileage > maxMileage) maxMileage = mileage;
    }

    return maxMileage > 0 ? maxMileage : null;
  }

  // Получить рекомендации
  List<String> _getRecommendations(GarageProvider garage) {
    final mileage = _getCurrentMileage(garage);
    if (mileage == null)
      return ['Добавьте записи о заправках для расчета пробега'];

    final recommendations = <String>[];
    String? nextTO;
    int? nextKm;

    for (final entry in _maintenanceSchedule.entries) {
      final km = entry.value['km'] as int;
      if (mileage >= km) {
        // Уже пора было делать это ТО
        nextTO = entry.key;
        nextKm = km;
      } else {
        // Следующее ТО
        if (nextTO == null) {
          nextTO = entry.key;
          nextKm = km;
        }
        break;
      }
    }

    if (nextTO != null && nextKm != null) {
      final remainingKm = nextKm - mileage.toInt();
      recommendations.add('Следующее $nextTO через $remainingKm км');
      final services =
          _maintenanceSchedule[nextTO]!['services'] as List<String>;
      recommendations.addAll(services);
    } else {
      recommendations.add('Все регламентные ТО пройдены');
    }

    return recommendations;
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
                          final now = DateTime.now();
                          final updatedRecord = existingRecord.copyWith(
                            type: selectedType,
                            cost: costCtrl.text.trim().isEmpty
                                ? '0'
                                : costCtrl.text.trim(),
                            odometer: odometerCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                            timestamp: now.millisecondsSinceEpoch,
                            date:
                                '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
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
    final mileage = _getCurrentMileage(garage);
    final currentCar = garage.currentCar;
    final carRecords =
        garage.maintenanceRecords
            .where((r) => r.carNumber == currentCar?.number)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final lastRecord = carRecords.isNotEmpty ? carRecords.first : null;

    int previousKm = 0;
    String? nextLabel;
    int? nextKm;
    List<String> nextServices = const [];

    if (mileage != null) {
      for (final entry in _maintenanceSchedule.entries) {
        final km = entry.value['km'] as int;
        if (mileage <= km) {
          nextLabel = entry.key;
          nextKm = km;
          nextServices = List<String>.from(entry.value['services'] as List);
          break;
        }
        previousKm = km;
      }
    }

    int? distanceToService;
    int? overdueBy;
    final serviceIntervalKm = typeIntervals[lastRecord?.type] ?? 10000;
    if (mileage != null) {
      final lastMaintenanceMileage = lastRecord != null
          ? double.tryParse(lastRecord.odometer)
          : null;
      final baseMileage =
          lastMaintenanceMileage != null && lastMaintenanceMileage > 0
          ? lastMaintenanceMileage
          : 0;
      final dueMileage = baseMileage + serviceIntervalKm;
      final delta = (dueMileage - mileage).round();
      if (delta >= 0) {
        distanceToService = delta;
      } else {
        overdueBy = delta.abs();
      }
    }

    final progress = () {
      if (mileage == null || nextKm == null || nextKm == previousKm) return 0.0;
      final value = (mileage - previousKm) / (nextKm - previousKm);
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
                          ).replaceAll('{km}', '${overdueBy ?? 0}')
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
              nextLabel != null
                  ? tr('maintenanceRegulationProgress')
                        .replaceAll('{label}', nextLabel)
                        .replaceAll('{current}', '${mileage.toInt()}')
                        .replaceAll('{target}', '${nextKm ?? 0}')
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
              tr('maintenanceMileageRecommendationsTitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildMileageRecommendations(
                  mileage.toInt(),
                  typeIntervals,
                  carRecords,
                )
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          item.value <= 0
                              ? Icons.notification_important
                              : Icons.schedule,
                          size: 15,
                          color: item.value <= 0
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.value < 0
                                ? tr('maintenanceRecommendOverdueByKm')
                                      .replaceAll(
                                        '{service}',
                                        _trType(item.key),
                                      )
                                      .replaceAll('{km}', '${item.value.abs()}')
                                : item.value == 0
                                ? tr(
                                    'maintenanceRecommendNow',
                                  ).replaceAll('{service}', _trType(item.key))
                                : tr('maintenanceRecommendInKm')
                                      .replaceAll(
                                        '{service}',
                                        _trType(item.key),
                                      )
                                      .replaceAll('{km}', '${item.value}'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 14),
          if (lastRecord != null)
            Text(
              tr('maintenanceLastService')
                  .replaceAll('{type}', _trType(lastRecord.type))
                  .replaceAll(
                    '{odometer}',
                    lastRecord.odometer.isEmpty
                        ? tr('maintenanceNoOdometerMark')
                        : '${lastRecord.odometer} ${tr('km')}',
                  )
                  .replaceAll('{date}', lastRecord.date),
              style: theme.textTheme.bodySmall,
            )
          else
            Text(
              tr('maintenanceNoCarRecords'),
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
    final records = garage.maintenanceRecords;
    final tr = LocaleService.tr;

    // Считаем общие расходы на ТО
    final totalCost = records.fold<double>(
      0,
      (s, r) => s + (double.tryParse(r.cost) ?? 0),
    );

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
        actions: [
          if (records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  CurrencyService.format(totalCost, currency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
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
                            tr('noMaintenance'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('noMaintenanceHint'),
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

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
    'Замена тормозных колодок',
    'Замена свечей зажигания',
    'Замена ремня ГРМ',
    'Замена шин',
    'Плановое ТО',
    'Промывка инжектора',
    'Диагностика',
    'Другое',
  ];

  static const _engineTypes = [
    '1.2L',
    '1.6L',
    '2.0L',
    '2.4L',
    '3.0L',
    'Другое',
  ];

  static const _smartChecklistItems = [
    'Замена масла',
    'Замена масляного фильтра',
    'Замена воздушного фильтра',
    'Замена салонного фильтра',
    'Замена свечей зажигания',
    'Проверка тормозной системы',
    'Проверка жидкостей и утечек',
    'Осмотр ремня ГРМ и приводных ремней',
    'Проверка шин и давления',
  ];

  void _showSmartMaintenanceDialog() {
    final garage = context.read<GarageProvider>();
    final auth = context.read<AuthProvider>();
    final cars = garage.cars;
    if (cars.isEmpty) return;

    int selectedCarIndex = garage.currentCarIndex.clamp(0, cars.length - 1);
    String selectedEngine = _engineTypes.first;
    final odometerCtrl = TextEditingController();
    final checklist = List<bool>.filled(_smartChecklistItems.length, false);

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
                      LocaleService.tr('smartMaintenance'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocaleService.tr('smartMaintenanceHint'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Авто
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedCarIndex,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? Colors.grey.shade900
                              : Colors.white,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                          ),
                          items: List.generate(
                            cars.length,
                            (index) => DropdownMenuItem(
                              value: index,
                              child: Text(cars[index].title),
                            ),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => selectedCarIndex = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Двигатель
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedEngine,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? Colors.grey.shade900
                              : Colors.white,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                          ),
                          items: _engineTypes
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => selectedEngine = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _field(
                      theme,
                      odometerCtrl,
                      LocaleService.tr('odometerKm'),
                      Icons.speed,
                      isNumber: true,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      LocaleService.tr('checklistTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _smartChecklistItems.length,
                      (index) => CheckboxListTile(
                        value: checklist[index],
                        contentPadding: EdgeInsets.zero,
                        title: Text(_smartChecklistItems[index]),
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          setModalState(() {
                            checklist[index] = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          final selectedItems = _smartChecklistItems
                              .asMap()
                              .entries
                              .where((entry) => checklist[entry.key])
                              .map((entry) => entry.value)
                              .toList();
                          if (selectedItems.isEmpty) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  LocaleService.tr('selectChecklistItems'),
                                ),
                              ),
                            );
                            return;
                          }

                          final car = cars[selectedCarIndex];
                          final now = DateTime.now();
                          final record = MaintenanceRecord(
                            userId: auth.userId!,
                            carId: car.id,
                            carTitle: car.title,
                            carNumber: car.number,
                            type: 'Плановое ТО',
                            date:
                                '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
                            timestamp: now.millisecondsSinceEpoch,
                            cost: '0',
                            odometer: odometerCtrl.text.trim(),
                            notes:
                                'Двигатель: $selectedEngine\nЧеклист:\n• ${selectedItems.join('\n• ')}',
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
                          LocaleService.tr('createServiceRecord'),
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
    final typeCtrl = TextEditingController(text: _types.first);
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
                              typeCtrl.text = v;
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: Text(tr('smartMaintenance')),
                onPressed: garage.hasCars ? _showSmartMaintenanceDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
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
                                Text(
                                  CurrencyService.format(
                                    double.tryParse(item.cost) ?? 0,
                                    currency,
                                  ),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
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

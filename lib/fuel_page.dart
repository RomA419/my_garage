import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'currency_service.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'models.dart';

String _trFuel(String type) {
  if (LocaleService.isRu) return type;
  const _en = {
    'АИ-92': 'AI-92',
    'АИ-95': 'AI-95',
    'АИ-98': 'AI-98',
    'Дизель': 'Diesel',
    'Газ': 'LPG',
    'Моторное масло 5W-30': 'Motor oil 5W-30',
    'Трансмиссионное масло': 'Transmission oil',
    'Масло для коробки': 'Gearbox oil',
    'Летние шины': 'Summer tires',
    'Зимние шины': 'Winter tires',
    'Всесезонные шины': 'All-season tires',
    'Базовая мойка': 'Basic wash',
    'Комплексная мойка': 'Full wash',
    'Химчистка салона': 'Interior cleaning',
  };
  return _en[type] ?? type;
}

class FuelPage extends StatefulWidget {
  const FuelPage({super.key});

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  final _stationController = TextEditingController(); // Название заправки
  final _quantityController =
      TextEditingController(); // Кол-во (литры, кг, шт и т.д.)
  final _customPriceController = TextEditingController(); // Цена для "Другое"
  final _odometerController = TextEditingController();

  // Категории услуг
  final List<String> categories = [
    'Топливо',
    'Масло',
    'Шины',
    'Мойка',
    'Другое',
  ];

  // Виды топлива и их средние цены
  final Map<String, double> fuelPrices = {
    'АИ-92': 235.0,
    'АИ-95': 305.0,
    'АИ-98': 355.0,
    'Дизель': 333.0,
    'Газ': 112.0,
  };

  // Виды масла и цены
  final Map<String, double> oilPrices = {
    'Моторное масло 5W-30': 1500.0,
    'Трансмиссионное масло': 1200.0,
    'Масло для коробки': 1000.0,
  };

  // Виды шин и цены
  final Map<String, double> tirePrices = {
    'Летние шины': 5000.0,
    'Зимние шины': 6000.0,
    'Всесезонные шины': 5500.0,
  };

  // Виды мойки и цены
  final Map<String, double> washPrices = {
    'Базовая мойка': 500.0,
    'Комплексная мойка': 1000.0,
    'Химчистка салона': 1500.0,
  };

  final String _selectedCategory = 'Топливо';
  String _selectedSubType = 'АИ-92';
  String _searchQuery = '';
  String _filterType = '';
  String _selectedPeriod = 'all'; // all | month | 3months | year

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addRecord() async {
    final garage = context.read<GarageProvider>();
    final auth = context.read<AuthProvider>();
    final currentCar = garage.currentCar;

    final String station = _stationController.text.trim();
    final String quantityText = _quantityController.text.trim();
    final String customPriceText = _customPriceController.text.trim();
    final String odometerText = _odometerController.text.trim();

    if (station.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LocaleService.tr('fillStation'))));
      return;
    }
    if (quantityText.isEmpty || double.tryParse(quantityText) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LocaleService.tr('fillLiters'))));
      return;
    }

    {
      double quantity = double.tryParse(quantityText) ?? 1;
      double pricePerUnit = 0;
      String unit = '';

      if (_selectedCategory == 'Другое') {
        pricePerUnit = double.tryParse(customPriceText) ?? 0;
        unit = 'шт';
      } else {
        switch (_selectedCategory) {
          case 'Топливо':
            pricePerUnit = fuelPrices[_selectedSubType]!;
            unit = 'л';
            break;
          case 'Масло':
            pricePerUnit = oilPrices[_selectedSubType]!;
            unit = 'л';
            break;
          case 'Шины':
            pricePerUnit = tirePrices[_selectedSubType]!;
            unit = 'шт';
            break;
          case 'Мойка':
            pricePerUnit = washPrices[_selectedSubType]!;
            unit = 'услуга';
            quantity = 1; // Для мойки всегда 1 услуга
            break;
        }
      }

      double totalAmount = quantity * pricePerUnit;

      final now = DateTime.now();
      final record = FuelRecordModel(
        userId: auth.userId!,
        date: "${now.day}.${now.month}.${now.year}",
        timestamp: now.millisecondsSinceEpoch,
        station: station,
        carNumber: currentCar?.number ?? '',
        carTitle: currentCar?.title ?? '',
        odometer: odometerText,
        category: _selectedCategory,
        subType: _selectedSubType,
        quantity: quantity.toStringAsFixed(
          _selectedCategory == 'Топливо' || _selectedCategory == 'Масло'
              ? 1
              : 0,
        ),
        unit: unit,
        total: totalAmount.toStringAsFixed(0),
      );

      await garage.addFuelRecord(record);

      _stationController.clear();
      _quantityController.clear();
      _customPriceController.clear();
      _odometerController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _deleteRecord(FuelRecordModel record) {
    final garage = context.read<GarageProvider>();
    garage.deleteFuelRecord(record.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleService.tr('recordDeleted')),
        action: SnackBarAction(
          label: LocaleService.tr('undo'),
          onPressed: () => garage.undoDeleteFuelRecord(record),
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final garage = context.read<GarageProvider>();
    if (garage.fuelRecords.isEmpty) return;
    final buf = StringBuffer();
    buf.writeln('Date,Station,Type,Quantity,Unit,Total,Odometer,Car');
    for (final r in garage.fuelRecords) {
      buf.writeln(
        '${r.date},${r.station},${r.subType},${r.quantity},${r.unit},${r.total},${r.odometer ?? ''},${r.carTitle}',
      );
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/fuel_history.csv');
    await file.writeAsString(buf.toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${LocaleService.tr('exported')}: ${file.path}')),
    );
  }

  List<FuelRecordModel> get _filteredHistory {
    final garage = context.read<GarageProvider>();
    var list = garage.fuelRecords.toList();
    if (_filterType.isNotEmpty) {
      list = list.where((r) => r.subType == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) => r.station.toLowerCase().contains(q)).toList();
    }
    if (_selectedPeriod != 'all') {
      final now = DateTime.now();
      final cutoff = _selectedPeriod == 'month'
          ? DateTime(now.year, now.month - 1, now.day)
          : _selectedPeriod == '3months'
          ? DateTime(now.year, now.month - 3, now.day)
          : DateTime(now.year - 1, now.month, now.day);
      list = list
          .where((r) => r.timestamp >= cutoff.millisecondsSinceEpoch)
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final currency =
        context.watch<AuthProvider>().user?.settings['currency'] as String? ??
        '₸';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          LocaleService.tr('refueling'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: LocaleService.tr('exportCsv'),
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final garage = context.watch<GarageProvider>();
                      final car = garage.currentCar;
                      if (car == null) return const SizedBox.shrink();
                      final label = car.title.isNotEmpty
                          ? car.title
                          : car.number;
                      if (label.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${LocaleService.tr('carLabel')}: $label',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ВЫБОР ТИПА ТОПЛИВА
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubType,
                        dropdownColor: isDark ? Colors.black : Colors.white,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                        ),
                        isExpanded: true,
                        items: fuelPrices.keys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(
                              "${_trFuel(key)} — ${CurrencyService.format(fuelPrices[key]!, currency)}/${LocaleService.tr('tripLiters')}",
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSubType = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildInput(
                    theme,
                    _stationController,
                    LocaleService.tr('stationName'),
                    Icons.edit_location_alt,
                  ),
                  const SizedBox(height: 15),

                  _buildInput(
                    theme,
                    _quantityController,
                    LocaleService.tr('howManyLiters'),
                    Icons.local_gas_station,
                    isNumber: true,
                  ),
                  const SizedBox(height: 15),
                  _buildInput(
                    theme,
                    _odometerController,
                    LocaleService.tr('odometerKm'),
                    Icons.speed,
                    isNumber: true,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _addRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      LocaleService.tr('calculateAndSave'),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                Text(
                  LocaleService.tr('history'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterType,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                    isDense: true,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(LocaleService.tr('all')),
                      ),
                      ...fuelPrices.keys.map(
                        (k) =>
                            DropdownMenuItem(value: k, child: Text(_trFuel(k))),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filterType = v ?? ''),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in [
                    ('all', LocaleService.tr('periodAll')),
                    ('month', LocaleService.tr('periodMonth')),
                    ('3months', LocaleService.tr('period3Months')),
                    ('year', LocaleService.tr('periodYear')),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          entry.$2,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: _selectedPeriod == entry.$1,
                        onSelected: (_) =>
                            setState(() => _selectedPeriod = entry.$1),
                        selectedColor: theme.colorScheme.primary.withOpacity(
                          0.2,
                        ),
                        labelStyle: TextStyle(
                          color: _selectedPeriod == entry.$1
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: LocaleService.tr('searchHint'),
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: _filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_gas_station_outlined,
                          size: 64,
                          color: theme.iconTheme.color?.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          LocaleService.tr('noRecords'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleService.tr('noRecordsHint'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = _filteredHistory[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(item.timestamp),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 400 + (80 * index).clamp(0, 400),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Dismissible(
                          key: ValueKey('dismiss_${item.timestamp}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteRecord(item),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      CurrencyService.format(
                                        double.tryParse(item.total) ?? 0,
                                        currency,
                                      ),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.date,
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
                                const SizedBox(height: 6),
                                Text(
                                  "${item.station} • ${_trFuel(item.subType)} • ${item.quantity} ${item.unit}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                                if ((item.odometer ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed,
                                        size: 14,
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withOpacity(0.4),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.odometer} ${LocaleService.tr('km')}',
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
                                if (item.carTitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_car,
                                        size: 14,
                                        color: theme.textTheme.bodySmall?.color
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
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    ThemeData theme,
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    final bool isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: controller,
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
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

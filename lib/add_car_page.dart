import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'car_preview.dart';
import 'car_types.dart';
import 'locale_service.dart';

class AddCarPage extends StatefulWidget {
  final Map<String, dynamic>? initialCar;

  const AddCarPage({super.key, this.initialCar});

  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  // Список типов машины (берётся из car_types.dart)
  static const types = carTypes;

  int _selectedTypeIndex = 0; // Индекс выбранного кузова
  late final PageController _typePageController;
  Color _selectedColor = Colors.white;
  final _numberController = TextEditingController();
  final _brandController = TextEditingController();

  final List<Color> colors = [
    Colors.white, Colors.grey, Colors.black, Colors.blue, Colors.purple,
    Colors.red, Colors.green, Colors.orange, Colors.yellow, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialCar != null) {
      final car = widget.initialCar!;
      _selectedTypeIndex = car['typeIndex'] as int? ?? 0;
      _selectedColor = Color(car['color'] as int? ?? Colors.white.value);
      _numberController.text = car['number'] as String? ?? '';
      _brandController.text = car['brand'] as String? ?? '';
    }

    _typePageController = PageController(
      initialPage: _selectedTypeIndex,
      viewportFraction: 0.28,
    );
  }

  @override
  void dispose() {
    _typePageController.dispose();
    _numberController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. ПРЕВЬЮ (силуэт) машины
          const SizedBox(height: 12),
          CarPreview(
            svgAsset: types[_selectedTypeIndex]['svg'] as String?,
            pngAsset: types[_selectedTypeIndex]['png'] as String?,
            icon: types[_selectedTypeIndex]['icon'] as IconData?,
            color: _selectedColor,
            size: 110,
            title: _brandController.text.isNotEmpty
                ? _brandController.text
                : types[_selectedTypeIndex]['name'] as String,
            subtitle: _numberController.text.isNotEmpty ? _numberController.text : null,
          ),
          const SizedBox(height: 15),

          // 2. Марка (бренд)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: _brandController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: LocaleService.tr('brand'),
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 3. ГОРИЗОНТАЛЬНЫЙ ВЫБОР КУЗОВА (свайп)
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _typePageController,
              onPageChanged: (index) => setState(() => _selectedTypeIndex = index),
              itemCount: carTypes.length,
              itemBuilder: (context, index) {
                bool isTypeSelected = _selectedTypeIndex == index;
                final pngPath = types[index]['png'] as String?;
                final svgPath = types[index]['svg'] as String?;
                final iconColor = isTypeSelected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color?.withOpacity(0.7) ?? Colors.grey;
                return GestureDetector(
                  onTap: () {
                    _typePageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedScale(
                    scale: isTypeSelected ? 1.0 : 0.85,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isTypeSelected
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTypeSelected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor.withOpacity(0.3),
                              width: isTypeSelected ? 2 : 1,
                            ),
                          ),
                          child: pngPath != null
                              ? Image.asset(
                                  pngPath,
                                  color: iconColor,
                                  colorBlendMode: BlendMode.srcATop,
                                  fit: BoxFit.contain,
                                )
                              : svgPath != null
                                  ? SvgPicture.asset(
                                      svgPath,
                                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcATop),
                                      fit: BoxFit.contain,
                                    )
                                  : Icon(
                                      types[index]['icon'] as IconData,
                                      color: iconColor,
                                      size: 28,
                                    ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          types[index]['name'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isTypeSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                            fontWeight: isTypeSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 3. НОМЕР МАШИНЫ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: _numberController,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: LocaleService.tr('autoNumber'),
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            carTypes[_selectedTypeIndex]['name'],
            style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
          ),
          
          const SizedBox(height: 30),

          // 4. СЕТКА ЦВЕТОВ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                bool isColorSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isColorSelected ? Colors.orangeAccent : Colors.white10,
                        width: isColorSelected ? 3 : 1,
                      ),
                    ),
                    child: isColorSelected ? Icon(
                      Icons.check, 
                      size: 18,
                      color: color == Colors.white ? Colors.blue : Colors.white,
                    ) : null,
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          // 5. КНОПКА "СОХРАНИТЬ"
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                // ТЕПЕРЬ ВОЗВРАЩАЕМ: ТИП, БРЕНД, НОМЕР, ЦВЕТ, ИКОНКУ
                Navigator.pop(context, {
                  'type': types[_selectedTypeIndex]['name'],
                  'brand': _brandController.text.trim(),
                  'number': _numberController.text.trim(),
                  'color': _selectedColor.value,
                  'typeIndex': _selectedTypeIndex,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text(
                LocaleService.tr('saveAuto'),
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
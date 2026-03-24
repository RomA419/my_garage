import 'package:flutter/material.dart';
import 'locale_service.dart';

// ──────────────────────────────────────────────
//  Модель автомобиля для каталога
// ──────────────────────────────────────────────
class _Car {
  final String brand;
  final String model;
  final String years;
  final String body;        // sedan / crossover / suv / hatchback / minivan / pickup
  final double engine;      // объём, л
  final String fuel;        // бензин / дизель / гибрид / электро
  final int hp;
  final String transmission;// АКПП / МКПП / вариатор
  final String drive;       // передний / полный / задний
  final double priceFrom;   // млн ₸
  final double priceTo;
  final Color color;
  final String description;
  final List<String> pros;

  const _Car({
    required this.brand,
    required this.model,
    required this.years,
    required this.body,
    required this.engine,
    required this.fuel,
    required this.hp,
    required this.transmission,
    required this.drive,
    required this.priceFrom,
    required this.priceTo,
    required this.color,
    required this.description,
    required this.pros,
  });

  String get title => '$brand $model';

  String get priceLabel {
    if (priceFrom == priceTo) {
      return 'от ${priceFrom.toStringAsFixed(1)} млн ₸';
    }
    return '${priceFrom.toStringAsFixed(1)}–${priceTo.toStringAsFixed(1)} млн ₸';
  }

  String get bodyLabel {
    switch (body) {
      case 'sedan': return 'Седан';
      case 'crossover': return 'Кроссовер';
      case 'suv': return 'Внедорожник';
      case 'hatchback': return 'Хэтчбек';
      case 'minivan': return 'Минивэн';
      case 'pickup': return 'Пикап';
      default: return body;
    }
  }
}

// ──────────────────────────────────────────────
//  Данные: ~25 популярных авто рынка Казахстана
// ──────────────────────────────────────────────
const _catalog = <_Car>[
  _Car(
    brand: 'Toyota', model: 'Camry',
    years: '2018–2024', body: 'sedan',
    engine: 2.5, fuel: 'бензин', hp: 181,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 12.5, priceTo: 19.0,
    color: Color(0xFFE53935),
    description: 'Самый популярный бизнес-седан в СНГ. Комфортный, надёжный, с отличной репутацией на вторичном рынке.',
    pros: ['Высокий ресурс двигателя', 'Просторный салон', 'Хорошая ликвидность при продаже'],
  ),
  _Car(
    brand: 'Toyota', model: 'RAV4',
    years: '2019–2024', body: 'crossover',
    engine: 2.0, fuel: 'бензин', hp: 149,
    transmission: 'вариатор', drive: 'полный',
    priceFrom: 14.0, priceTo: 21.0,
    color: Color(0xFF1E88E5),
    description: 'Надёжный кроссовер с полным приводом и вместительным багажником. Один из лидеров продаж в классе.',
    pros: ['Полный привод', 'Экономичный расход', 'Большой багажник'],
  ),
  _Car(
    brand: 'Toyota', model: 'Land Cruiser 200',
    years: '2015–2021', body: 'suv',
    engine: 4.5, fuel: 'дизель', hp: 235,
    transmission: 'АКПП', drive: 'полный',
    priceFrom: 28.0, priceTo: 55.0,
    color: Color(0xFF37474F),
    description: 'Легендарный внедорожник с безупречной репутацией. Незаменим на бездорожье и в суровых условиях.',
    pros: ['Рамная конструкция', 'Мощный дизель', 'Высокая надёжность', 'Статусный автомобиль'],
  ),
  _Car(
    brand: 'Toyota', model: 'Land Cruiser Prado',
    years: '2017–2024', body: 'suv',
    engine: 2.7, fuel: 'бензин', hp: 163,
    transmission: 'АКПП', drive: 'полный',
    priceFrom: 20.0, priceTo: 35.0,
    color: Color(0xFF6D4C41),
    description: 'Комфортный рамный внедорожник. Баланс между городским использованием и серьёзным бездорожьем.',
    pros: ['Рамный кузов', 'Блокировки дифференциалов', 'Высокий клиренс'],
  ),
  _Car(
    brand: 'Kia', model: 'K5',
    years: '2020–2024', body: 'sedan',
    engine: 2.0, fuel: 'бензин', hp: 150,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 10.5, priceTo: 15.0,
    color: Color(0xFF8E24AA),
    description: 'Стильный корейский седан с отличным оснащением. Конкурент Camry по соотношению цена/качество.',
    pros: ['Современный дизайн', 'Богатое оснащение', 'Просторный салон'],
  ),
  _Car(
    brand: 'Kia', model: 'Sportage',
    years: '2021–2024', body: 'crossover',
    engine: 2.0, fuel: 'бензин', hp: 150,
    transmission: 'АКПП', drive: 'полный',
    priceFrom: 12.0, priceTo: 18.0,
    color: Color(0xFF00ACC1),
    description: 'Популярный городской кроссовер с современным интерьером и богатым набором технологий.',
    pros: ['Широкий выбор комплектаций', 'Современные ассистенты', 'Полный привод в базе'],
  ),
  _Car(
    brand: 'Hyundai', model: 'Tucson',
    years: '2021–2024', body: 'crossover',
    engine: 2.0, fuel: 'бензин', hp: 150,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 11.5, priceTo: 17.0,
    color: Color(0xFF43A047),
    description: 'Семейный кроссовер с агрессивным дизайном. Конкурирует с Sportage — они построены на одной платформе.',
    pros: ['Дерзкий внешний вид', 'Хорошая шумоизоляция', 'Большой экран мультимедиа'],
  ),
  _Car(
    brand: 'Hyundai', model: 'Sonata',
    years: '2019–2024', body: 'sedan',
    engine: 2.0, fuel: 'бензин', hp: 150,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 10.0, priceTo: 14.5,
    color: Color(0xFF039BE5),
    description: 'Корейский бизнес-седан с авангардным дизайном и хорошим оснащением по цене ниже японских аналогов.',
    pros: ['Динамичный дизайн', 'Просторный салон', 'Доступная цена обслуживания'],
  ),
  _Car(
    brand: 'Chevrolet', model: 'Onix',
    years: '2022–2024', body: 'sedan',
    engine: 1.5, fuel: 'бензин', hp: 113,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 6.5, priceTo: 9.0,
    color: Color(0xFFFDD835),
    description: 'Доступный бюджетный седан производства Узбекистана. Самый популярный автомобиль в ценовой категории до 10 млн ₸.',
    pros: ['Низкая цена', 'Дешёвое обслуживание', 'Запчасти в наличии'],
  ),
  _Car(
    brand: 'Chevrolet', model: 'Cobalt',
    years: '2020–2024', body: 'sedan',
    engine: 1.5, fuel: 'бензин', hp: 106,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 5.5, priceTo: 7.5,
    color: Color(0xFFF4511E),
    description: 'Самый доступный новый автомобиль на рынке Казахстана. Идеален для первой машины.',
    pros: ['Очень доступная цена', 'Простота в обслуживании', 'Хороший дорожный просвет'],
  ),
  _Car(
    brand: 'Lada', model: 'Vesta',
    years: '2018–2024', body: 'sedan',
    engine: 1.6, fuel: 'бензин', hp: 106,
    transmission: 'МКПП', drive: 'передний',
    priceFrom: 4.5, priceTo: 7.0,
    color: Color(0xFFFFB300),
    description: 'Российский бюджетный седан. Современный дизайн, высокий клиренс и доступное обслуживание.',
    pros: ['Низкая стоимость', 'Высокий клиренс для седана', 'Доступные запчасти'],
  ),
  _Car(
    brand: 'BMW', model: '3 Series',
    years: '2019–2024', body: 'sedan',
    engine: 2.0, fuel: 'бензин', hp: 184,
    transmission: 'АКПП', drive: 'задний',
    priceFrom: 22.0, priceTo: 35.0,
    color: Color(0xFF1565C0),
    description: 'Эталонный спортивный седан с задним приводом. Непревзойдённая управляемость в своём классе.',
    pros: ['Спортивная управляемость', 'Мощные двигатели', 'Премиальный интерьер'],
  ),
  _Car(
    brand: 'Mercedes-Benz', model: 'C-Class',
    years: '2019–2024', body: 'sedan',
    engine: 2.0, fuel: 'бензин', hp: 204,
    transmission: 'АКПП', drive: 'задний',
    priceFrom: 25.0, priceTo: 40.0,
    color: Color(0xFF212121),
    description: 'Флагманский представительский седан среднего класса. Роскошь, технологии и статус в одном автомобиле.',
    pros: ['Роскошный салон', 'Передовые технологии', 'Высокий статус'],
  ),
  _Car(
    brand: 'Lexus', model: 'RX 350',
    years: '2016–2023', body: 'crossover',
    engine: 3.5, fuel: 'бензин', hp: 249,
    transmission: 'АКПП', drive: 'полный',
    priceFrom: 22.0, priceTo: 40.0,
    color: Color(0xFFC62828),
    description: 'Премиальный японский кроссовер. Сочетает надёжность Toyota с роскошью Lexus.',
    pros: ['Высочайшая надёжность', 'Роскошный интерьер', 'Тихий и плавный ход'],
  ),
  _Car(
    brand: 'Nissan', model: 'Qashqai',
    years: '2019–2024', body: 'crossover',
    engine: 2.0, fuel: 'бензин', hp: 144,
    transmission: 'вариатор', drive: 'передний',
    priceFrom: 9.5, priceTo: 14.0,
    color: Color(0xFF00897B),
    description: 'Компактный городской кроссовер — родоначальник класса. Манёвренный, экономичный, практичный.',
    pros: ['Компактные габариты', 'Экономичный расход', 'Удобен в городе'],
  ),
  _Car(
    brand: 'Honda', model: 'CR-V',
    years: '2017–2023', body: 'crossover',
    engine: 1.5, fuel: 'бензин', hp: 190,
    transmission: 'АКПП', drive: 'полный',
    priceFrom: 13.0, priceTo: 20.0,
    color: Color(0xFF6A1B9A),
    description: 'Практичный семейный кроссовер с турбомотором. Просторный, надёжный, с отличной экономичностью.',
    pros: ['Вместительный салон', 'Турбодвигатель 1.5', 'Экономичный расход'],
  ),
  _Car(
    brand: 'Volkswagen', model: 'Polo',
    years: '2020–2024', body: 'sedan',
    engine: 1.6, fuel: 'бензин', hp: 110,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 7.5, priceTo: 11.0,
    color: Color(0xFF1976D2),
    description: 'Немецкий бюджетный седан с отличной управляемостью и качественной сборкой.',
    pros: ['Немецкое качество', 'Отличная управляемость', 'Экономичный мотор'],
  ),
  _Car(
    brand: 'Škoda', model: 'Octavia',
    years: '2020–2024', body: 'sedan',
    engine: 1.6, fuel: 'бензин', hp: 110,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 9.0, priceTo: 14.5,
    color: Color(0xFF388E3C),
    description: 'Практичный чешский седан — один из лучших в классе по объёму салона и багажника.',
    pros: ['Огромный багажник', 'Качественная сборка', 'Богатое оснащение'],
  ),
  _Car(
    brand: 'Mitsubishi', model: 'Outlander',
    years: '2018–2023', body: 'crossover',
    engine: 2.0, fuel: 'бензин', hp: 146,
    transmission: 'вариатор', drive: 'полный',
    priceFrom: 11.0, priceTo: 17.0,
    color: Color(0xFFD84315),
    description: 'Семейный кроссовер с третьим рядом сидений. Отличный вариант для большой семьи.',
    pros: ['7 мест', 'Надёжная трансмиссия 4WD', 'Низкая стоимость обслуживания'],
  ),
  _Car(
    brand: 'Subaru', model: 'Forester',
    years: '2018–2024', body: 'crossover',
    engine: 2.0, fuel: 'бензин', hp: 150,
    transmission: 'вариатор', drive: 'полный',
    priceFrom: 14.0, priceTo: 20.0,
    color: Color(0xFF004D40),
    description: 'Японский кроссовер с симметричным полным приводом AWD. Высокий клиренс и отличная проходимость.',
    pros: ['Постоянный AWD', 'Высокий клиренс', 'Боксёрский двигатель'],
  ),
  _Car(
    brand: 'Ford', model: 'Explorer',
    years: '2019–2024', body: 'suv',
    engine: 2.3, fuel: 'бензин', hp: 300,
    transmission: 'АКПП', drive: 'полный',
    priceFrom: 24.0, priceTo: 38.0,
    color: Color(0xFF0277BD),
    description: 'Американский среднеразмерный внедорожник с мощным турбодвигателем на 7 мест.',
    pros: ['Мощный мотор 300 л.с.', '7 мест', 'Харизматичный дизайн'],
  ),
  _Car(
    brand: 'Kia', model: 'Carnival',
    years: '2021–2024', body: 'minivan',
    engine: 2.2, fuel: 'дизель', hp: 199,
    transmission: 'АКПП', drive: 'передний',
    priceFrom: 18.0, priceTo: 26.0,
    color: Color(0xFF5C6BC0),
    description: 'Самый популярный минивэн в СНГ на 8 мест. Уровень комфорта как в бизнес-авто.',
    pros: ['8 пассажирских мест', 'Дизельный экономичный мотор', 'VIP-комфорт'],
  ),
  _Car(
    brand: 'Toyota', model: 'Hilux',
    years: '2018–2024', body: 'pickup',
    engine: 2.8, fuel: 'дизель', hp: 204,
    transmission: 'АКПП', drive: 'полный',
    priceFrom: 18.0, priceTo: 30.0,
    color: Color(0xFF558B2F),
    description: 'Легендарный пикап — символ надёжности. Используется в сельском хозяйстве, охоте и путешествиях.',
    pros: ['Непревзойдённая надёжность', 'Высокая грузоподъёмность', 'Рамная конструкция'],
  ),
  _Car(
    brand: 'Hyundai', model: 'IONIQ 6',
    years: '2023–2024', body: 'sedan',
    engine: 0.0, fuel: 'электро', hp: 229,
    transmission: 'авто', drive: 'задний',
    priceFrom: 22.0, priceTo: 30.0,
    color: Color(0xFF00838F),
    description: 'Флагманский электрический седан с запасом хода 600+ км. Победитель World Car of the Year 2023.',
    pros: ['Запас хода 614 км', 'Быстрая зарядка 800V', 'Нулевые расходы на топливо'],
  ),
  _Car(
    brand: 'BYD', model: 'Seal',
    years: '2023–2024', body: 'sedan',
    engine: 0.0, fuel: 'электро', hp: 313,
    transmission: 'авто', drive: 'полный',
    priceFrom: 18.0, priceTo: 25.0,
    color: Color(0xFF37474F),
    description: 'Китайский спортивный электрический седан. Набирает 0-100 км/ч за 3.8 сек, запас хода 570 км.',
    pros: ['0-100 за 3.8 с', 'Запас хода 570 км', 'Богатая комплектация в базе'],
  ),
];

// ──────────────────────────────────────────────
//  Страница каталога
// ──────────────────────────────────────────────
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _search = '';
  String _bodyFilter = 'all';
  String _sortMode = 'price_asc'; // price_asc | price_desc | name

  static const _bodyChips = [
    ('all', 'Все'),
    ('sedan', 'Седан'),
    ('crossover', 'Кроссовер'),
    ('suv', 'Внедорожник'),
    ('hatchback', 'Хэтчбек'),
    ('minivan', 'Минивэн'),
    ('pickup', 'Пикап'),
  ];

  static IconData _bodyIconFor(String body) {
    switch (body) {
      case 'all': return Icons.apps;
      case 'sedan': return Icons.directions_car;
      case 'crossover': return Icons.directions_car_filled;
      case 'suv': return Icons.terrain;
      case 'hatchback': return Icons.electric_car;
      case 'minivan': return Icons.airport_shuttle;
      case 'pickup': return Icons.local_shipping;
      default: return Icons.apps;
    }
  }

  List<_Car> get _filtered {
    var list = _catalog.toList();
    if (_bodyFilter != 'all') {
      list = list.where((c) => c.body == _bodyFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) =>
        c.brand.toLowerCase().contains(q) ||
        c.model.toLowerCase().contains(q) ||
        c.bodyLabel.toLowerCase().contains(q),
      ).toList();
    }
    switch (_sortMode) {
      case 'price_asc':
        list.sort((a, b) => a.priceFrom.compareTo(b.priceFrom));
        break;
      case 'price_desc':
        list.sort((a, b) => b.priceTo.compareTo(a.priceTo));
        break;
      case 'name':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return list;
  }

  void _openDetail(_Car car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CarDetailSheet(car: car),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cars = _filtered;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          LocaleService.tr('catalogTitle'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Сортировка',
            onSelected: (v) => setState(() => _sortMode = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'price_asc', child: Text(LocaleService.tr('sortPriceAsc'))),
              PopupMenuItem(value: 'price_desc', child: Text(LocaleService.tr('sortPriceDesc'))),
              PopupMenuItem(value: 'name', child: Text(LocaleService.tr('sortName'))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Поиск ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: LocaleService.tr('catalogSearch'),
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
                prefixIcon: Icon(Icons.search, size: 20,
                    color: theme.iconTheme.color?.withOpacity(0.5)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // ── Фильтр по кузову ──
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              children: _bodyChips.map((entry) {
                final selected = _bodyFilter == entry.$1;
                return GestureDetector(
                  onTap: () => setState(() => _bodyFilter = entry.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 70,
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withOpacity(0.25),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _bodyIconFor(entry.$1),
                          size: 24,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Счётчик ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${cars.length} ${LocaleService.tr('carsFound')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ),

          // ── Список ──
          Expanded(
            child: cars.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64,
                            color: theme.iconTheme.color?.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(LocaleService.tr('noCarsFound'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                            )),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: cars.length,
                    itemBuilder: (_, i) => _CarCard(
                      car: cars[i],
                      onTap: () => _openDetail(cars[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Карточка автомобиля
// ──────────────────────────────────────────────
class _CarCard extends StatelessWidget {
  final _Car car;
  final VoidCallback onTap;

  const _CarCard({required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo area ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            car.color.withOpacity(0.85),
                            car.color.withOpacity(0.35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20, top: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -10, bottom: -30,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        _bodyIcon(car.body),
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          car.bodyLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          car.priceLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info area ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${car.years} • ${_engineLabel(car)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _bodyIcon(String body) {
    switch (body) {
      case 'suv': return Icons.terrain;
      case 'crossover': return Icons.directions_car_filled;
      case 'hatchback': return Icons.electric_car;
      case 'minivan': return Icons.airport_shuttle;
      case 'pickup': return Icons.local_shipping;
      default: return Icons.directions_car_filled;
    }
  }

  static String _engineLabel(_Car car) {
    if (car.fuel == 'электро') return '${car.hp} л.с. • электро';
    return '${car.engine} л • ${car.hp} л.с. • ${car.fuel}';
  }
}

// ──────────────────────────────────────────────
//  Детальный экран (BottomSheet)
// ──────────────────────────────────────────────
class _CarDetailSheet extends StatelessWidget {
  final _Car car;

  const _CarDetailSheet({required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Ручка
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Photo header ──
          SizedBox(
            height: 165,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [car.color, car.color.withOpacity(0.4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  right: -30, top: -30,
                  child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -20, bottom: -40,
                  child: Container(
                    width: 170, height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    _CarCard._bodyIcon(car.body),
                    size: 110,
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                Positioned(
                  bottom: 14, left: 20, right: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        car.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                        ),
                      ),
                      Text(
                        '${car.bodyLabel} • ${car.years}',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      car.priceLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Описание
                  Text(
                    car.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Характеристики
                  Text(
                    LocaleService.tr('catalogSpecs'),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildSpecsGrid(theme, isDark),

                  const SizedBox(height: 20),

                  // Плюсы
                  Text(
                    LocaleService.tr('catalogPros'),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...car.pros.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),

                  // Кнопка закрыть
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(LocaleService.tr('close')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid(ThemeData theme, bool isDark) {
    final specs = [
      (Icons.speed, LocaleService.tr('catalogHp'), '${car.hp} л.с.'),
      (Icons.local_gas_station, LocaleService.tr('catalogFuel'), car.fuel),
      (Icons.settings, LocaleService.tr('catalogTransmission'), car.transmission),
      (Icons.swap_horiz, LocaleService.tr('catalogDrive'), car.drive),
      if (car.fuel != 'электро')
        (Icons.opacity, LocaleService.tr('catalogEngine'), '${car.engine} л'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: specs.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(s.$1, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$2,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                        fontSize: 9,
                      )),
                  Text(s.$3,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      )),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

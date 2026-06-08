import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_car_page.dart';
import 'auth_provider.dart';
import 'car_detail_page.dart';
import 'car_preview.dart';
import 'car_types.dart';
import 'car_assistant_page.dart';
import 'expenses_page.dart';
import 'car_health_page.dart';
import 'car_quiz_page.dart';
import 'catalog_page.dart';
import 'garage_provider.dart';
import 'trip_calculator_page.dart';
import 'currency_service.dart';
import 'locale_service.dart';
import 'models.dart';
import 'page_route.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onTabSwitch;

  const HomePage({super.key, required this.onTabSwitch});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _staggerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Ошибка при открытии ссылки: $urlString");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final auth = context.watch<AuthProvider>();
    final garage = context.watch<GarageProvider>();
    final currentCar = garage.currentCar;
    final hasCars = garage.hasCars;

    final carType = currentCar?.type ?? LocaleService.tr('noCar');
    final carBrand = currentCar?.brand ?? '';
    final carNumber = currentCar?.number ?? '';
    final carColor = currentCar != null
        ? Color(currentCar.color)
        : theme.colorScheme.primary;

    final carTypeIndex = currentCar?.typeIndex ?? 0;
    final carSvg = carTypes.length > carTypeIndex ? carTypes[carTypeIndex]['svg'] as String? : null;
    final carPng = carTypes.length > carTypeIndex ? carTypes[carTypeIndex]['png'] as String? : null;
    final carIcon = carTypes.length > carTypeIndex ? carTypes[carTypeIndex]['icon'] as IconData? : Icons.directions_car_filled;

    final carTitle = carBrand.isNotEmpty ? '$carBrand $carType' : carType;
    final carSubTitle = carNumber.isNotEmpty ? carNumber : LocaleService.tr('addCar');
    final tr = LocaleService.tr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('myGarage'),
              style: TextStyle(
                color: theme.colorScheme.primary.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
              ),
            ),
            Text(
              (auth.user?.login ?? '').toUpperCase(),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildShimmerBody(theme, isDark)
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // ГЛАВНЫЙ БЛОК АВТОМОБИЛЯ
              GestureDetector(
                onTap: currentCar != null ? () {
                  Navigator.push(context, AppPageRoute.slide(CarDetailPage(car: currentCar)));
                } : null,
                child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [Colors.white, const Color(0xFFF0EEFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(isDark ? 0.08 : 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    Hero(
                      tag: 'car_icon',
                      child: CarPreview(
                        svgAsset: carSvg,
                        pngAsset: carPng,
                        icon: carIcon,
                        color: carColor,
                        size: 110,
                        title: carTitle,
                        subtitle: carSubTitle,
                      ),
                    ),
                    if (hasCars) ...[
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: garage.cars.length,
                          itemBuilder: (context, index) {
                            final car = garage.cars[index];
                            final isSelected = index == garage.currentCarIndex;
                            return GestureDetector(
                              onTap: () => garage.selectCar(index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withOpacity(0.2)
                                      : theme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.dividerColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  car.number.isNotEmpty ? car.number : '---',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push<Map<String, dynamic>>(
                                  context,
                                  AppPageRoute.scaleUp(const AddCarPage()),
                                );

                                if (result != null && mounted) {
                                  final car = CarModel.fromJson(result, userId: auth.userId!);
                                  garage.addCar(car);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                tr('addAuto'), 
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (hasCars) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: tr('editAuto'),
                              icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                              onPressed: () async {
                                final result = await Navigator.push<Map<String, dynamic>>(
                                  context,
                                  AppPageRoute.slide(AddCarPage(initialCar: currentCar?.toJson())),
                                );
                                if (result != null && mounted && currentCar != null) {
                                  final updated = CarModel.fromJson(result, userId: auth.userId!, id: currentCar.id);
                                  garage.updateCar(updated);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: tr('deleteAuto'),
                              icon: Icon(Icons.delete, color: theme.colorScheme.error),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(tr('deleteCar')),
                                    content: Text(tr('deleteCarConfirm')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(tr('cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(tr('delete')),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && currentCar != null) {
                                  garage.deleteCar(currentCar.id!);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
              ),
              
              const SizedBox(height: 20),
              _buildSummaryCards(theme, isDark),
              if (hasCars && garage.maintenanceRecords.isEmpty) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => widget.onTabSwitch(3),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('maintenanceBanner'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                              Text(
                                tr('maintenanceBannerSub'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.orange[400]),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 25),
              Text(
                tr('servicesTitle'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 15),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 1.1,
                children: [
                  _staggeredItem(
                    index: 0,
                    child: _buildMenuCard(
                      icon: Icons.receipt_long_rounded,
                      title: tr('fuelStation'),
                      subtitle: tr('fuelAccounting'),
                      color: const Color(0xFFFF6B6B),
                      onTap: () => _launchUrl("https://egov.kz/cms/ru/articles/traffic_fines"),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 1,
                    child: _buildMenuCard(
                      icon: Icons.map_rounded,
                      title: tr('parking'),
                      subtitle: tr('parkingSubtitle'),
                      color: const Color(0xFF74B9FF),
                      onTap: () => _launchUrl("https://2gis.kz/karaganda/search/Парковки"),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 2,
                    child: _buildMenuCard(
                      icon: Icons.build_circle_rounded,
                      title: tr('service'),
                      subtitle: tr('serviceSubtitle'),
                      color: const Color(0xFFFDAA5E),
                      onTap: () => _launchUrl("https://2gis.kz/karaganda/search/Шиномонтаж"),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 3,
                    child: _buildMenuCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: tr('expensesCard'),
                      subtitle: tr('expensesCardSub'),
                      color: const Color(0xFF00CEC9),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute.slide(const ExpensesPage()),
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 4,
                    child: _buildMenuCard(
                      icon: Icons.car_rental_rounded,
                      title: tr('catalogCard'),
                      subtitle: tr('catalogCardSub'),
                      color: const Color(0xFFA29BFE),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute.slide(const CatalogPage()),
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 5,
                    child: _buildMenuCard(
                      icon: Icons.support_agent_rounded,
                      title: tr('assistantCard'),
                      subtitle: tr('assistantCardSub'),
                      color: const Color(0xFF55EFC4),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute.slide(const CarAssistantPage()),
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 6,
                    child: _buildMenuCard(
                      icon: Icons.quiz_rounded,
                      title: tr('quizCard'),
                      subtitle: tr('quizCardSub'),
                      color: const Color(0xFF0984E3),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute.slide(const CarQuizPage()),
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 7,
                    child: _buildMenuCard(
                      icon: Icons.route_rounded,
                      title: tr('tripCard'),
                      subtitle: tr('tripCardSub'),
                      color: const Color(0xFF6C5CE7),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute.slide(const TripCalculatorPage()),
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                  _staggeredItem(
                    index: 8,
                    child: _buildMenuCard(
                      icon: Icons.favorite_rounded,
                      title: tr('healthCard'),
                      subtitle: tr('healthCardSub'),
                      color: const Color(0xFFE84393),
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute.slide(const CarHealthPage()),
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBody(ThemeData theme, bool isDark) {
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: List.generate(3, (_) => Expanded(
                child: Container(
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 25),
            Container(width: 100, height: 12, color: Colors.white),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 1.1,
              children: List.generate(4, (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
              )),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, bool isDark) {
    final garage = context.watch<GarageProvider>();
    final currency = context.watch<AuthProvider>().user?.settings['currency'] as String? ?? '₸';
    final tr = LocaleService.tr;

    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            theme, isDark,
            icon: Icons.calendar_month,
            color: const Color(0xFFFF6B6B),
            label: tr('monthExpenses'),
            value: CurrencyService.format(garage.monthlyExpenses, currency),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            theme, isDark,
            icon: Icons.local_gas_station,
            color: const Color(0xFF6C5CE7),
            label: tr('totalRefuels'),
            value: '${garage.fuelRecords.length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            theme, isDark,
            icon: Icons.access_time,
            color: const Color(0xFFFDAA5E),
            label: tr('lastRefuel'),
            value: garage.lastRefuelDate,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(ThemeData theme, bool isDark, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDark ? 0.08 : 0.06),
            color.withOpacity(isDark ? 0.03 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _staggeredItem({required int index, required Widget child}) {
    final begin = (index * 0.15).clamp(0.0, 1.0);
    final end = (begin + 0.5).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, ch) {
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - curve.value)),
            child: ch,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(isDark ? 0.10 : 0.07),
                color.withOpacity(isDark ? 0.04 : 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.15), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
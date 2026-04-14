import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'analytics_page.dart';
import 'auth_provider.dart';
import 'fuel_page.dart';
import 'garage_provider.dart';
import 'home_page.dart';
import 'locale_service.dart';
import 'maintenance_page.dart';
import 'profile_page.dart';

/// Главный экран с нижней навигацией (4 вкладки).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    // Загружаем данные гаража при первом открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        context.read<GarageProvider>().loadData(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onTabSwitch: switchTab),
          const FuelPage(),
          const AnalyticsPage(),
          const MaintenancePage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.garage_outlined, color: theme.textTheme.bodySmall?.color?.withOpacity(0.45)),
              selectedIcon: Icon(Icons.garage, color: theme.colorScheme.primary),
              label: LocaleService.tr('garage'),
            ),
            NavigationDestination(
              icon: Icon(Icons.local_gas_station_outlined, color: theme.textTheme.bodySmall?.color?.withOpacity(0.45)),
              selectedIcon: Icon(Icons.local_gas_station, color: theme.colorScheme.primary),
              label: LocaleService.tr('fuel'),
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, color: theme.textTheme.bodySmall?.color?.withOpacity(0.45)),
              selectedIcon: Icon(Icons.analytics, color: theme.colorScheme.primary),
              label: LocaleService.tr('analytics'),
            ),
            NavigationDestination(
              icon: Icon(Icons.build_circle_outlined, color: theme.textTheme.bodySmall?.color?.withOpacity(0.45)),
              selectedIcon: Icon(Icons.build_circle, color: theme.colorScheme.primary),
              label: LocaleService.tr('maintenanceLog'),
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined, color: theme.textTheme.bodySmall?.color?.withOpacity(0.45)),
              selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
              label: LocaleService.tr('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

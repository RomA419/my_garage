import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'database_service.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'login_page.dart';
import 'main_screen.dart';
import 'onboarding_page.dart';
import 'theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const MyGarageApp());
}

class MyGarageApp extends StatelessWidget {
  const MyGarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => GarageProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.themeMode,
        builder: (context, mode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: LocaleService.locale,
            builder: (context, locale, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                locale: locale,
                theme: ThemeData(
                  brightness: Brightness.light,
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6C5CE7),
                    brightness: Brightness.light,
                  ).copyWith(
                    surface: const Color(0xFFF8F7FC),
                    primary: const Color(0xFF6C5CE7),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFFF8F7FC),
                    foregroundColor: Color(0xFF2D3436),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                  ),
                  scaffoldBackgroundColor: const Color(0xFFF8F7FC),
                  cardColor: Colors.white,
                  dividerColor: const Color(0xFFE8E6F0),
                  fontFamily: 'Segoe UI',
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6C5CE7),
                    brightness: Brightness.dark,
                  ).copyWith(
                    surface: const Color(0xFF0D0D12),
                    primary: const Color(0xFFA29BFE),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF0D0D12),
                    foregroundColor: Color(0xFFF0F0F5),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF0D0D12),
                  cardColor: const Color(0xFF1A1A24),
                  dividerColor: const Color(0xFF2A2A38),
                  fontFamily: 'Segoe UI',
                ),
                home: const _AppGate(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Контролирует навигацию: Splash → Onboarding → Login/MainScreen.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _showSplash = true;
  bool? _showOnboarding;
  int? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final shouldOnboard = await OnboardingPage.shouldShow();
    // Ждём 2 секунды для splash-анимации
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showOnboarding = shouldOnboard;
        _showSplash = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final garage = context.read<GarageProvider>();
    // Загружаем данные гаража при смене пользователя (вне build)
    if (auth.isLoggedIn && auth.userId != _lastLoadedUserId) {
      _lastLoadedUserId = auth.userId;
      garage.loadData(auth.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_showSplash) {
      return const _SplashView();
    }

    if (_showOnboarding == true) {
      return OnboardingPage(
        nextPage: auth.isLoggedIn ? const MainScreen() : const LoginPage(),
      );
    }

    return auth.isLoggedIn ? const MainScreen() : const LoginPage();
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/icon.png', width: 120, height: 120),
              const SizedBox(height: 16),
              Text(
                LocaleService.tr('appName'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

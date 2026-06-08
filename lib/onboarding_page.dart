import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_service.dart';

class OnboardingPage extends StatefulWidget {
  final Widget nextPage;

  const OnboardingPage({super.key, required this.nextPage});

  static const _onboardingKey = 'onboarding_seen';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingPage._onboardingKey, true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      _fadeRoute(widget.nextPage),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_OnboardData> _buildPages() {
    final tr = LocaleService.tr;
    return [
      _OnboardData(
        icon: Icons.directions_car_rounded,
        gradient: const [Color(0xFFE65100), Color(0xFFFF7043)],
        title: tr('onboard1Title'),
        body: tr('onboard1Body'),
      ),
      _OnboardData(
        icon: Icons.account_balance_wallet_rounded,
        gradient: const [Color(0xFF1565C0), Color(0xFF1E88E5)],
        title: tr('onboard2Title'),
        body: tr('onboard2Body'),
      ),
      _OnboardData(
        icon: Icons.bar_chart_rounded,
        gradient: const [Color(0xFF2E7D32), Color(0xFF43A047)],
        title: tr('onboard3Title'),
        body: tr('onboard3Body'),
      ),
      _OnboardData(
        icon: Icons.auto_awesome_rounded,
        gradient: const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        title: tr('onboard4Title'),
        body: tr('onboard4Body'),
      ),
      _OnboardData(
        icon: Icons.rocket_launch_rounded,
        gradient: const [Color(0xFF00695C), Color(0xFF26A69A)],
        title: tr('onboard5Title'),
        body: tr('onboard5Body'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final tr = LocaleService.tr;
    final pages = _buildPages();
    final isLast = _currentPage == pages.length - 1;
    final currentGradient = pages[_currentPage].gradient;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Animated gradient top section ──────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            height: size.height * 0.52,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: currentGradient,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
          ),

          // ── Foreground content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _complete,
                        child: Text(
                          tr('skip'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: pages.length,
                    itemBuilder: (_, i) {
                      final page = pages[i];
                      return Column(
                        children: [
                          // Icon in gradient area
                          SizedBox(
                            height: size.height * 0.32,
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(i),
                                duration: const Duration(milliseconds: 700),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.elasticOut,
                                builder: (_, v, child) =>
                                    Transform.scale(scale: v, child: child),
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.45),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.18),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    page.icon,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Text in white/dark area
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(36, 28, 36, 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    page.body,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                                      height: 1.55,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ── Dots + button ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: Row(
                    children: [
                      Row(
                        children: List.generate(pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 7),
                            width: _currentPage == i ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? currentGradient.first
                                  : theme.dividerColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isLast
                            ? ElevatedButton(
                                key: const ValueKey('start'),
                                onPressed: _complete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentGradient.first,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(148, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  tr('getStarted'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              )
                            : ElevatedButton(
                                key: const ValueKey('next'),
                                onPressed: () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentGradient.first,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(108, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  tr('next'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Route _fadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _OnboardData {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String body;

  const _OnboardData({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
  });
}



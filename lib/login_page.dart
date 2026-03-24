import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'locale_service.dart';
import 'main_screen.dart';
import 'page_route.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _loginController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String login = _loginController.text.trim();
    final String pass = _passController.text.trim();

    if (login.isEmpty || pass.isEmpty) {
      setState(() => _errorText = LocaleService.tr('enterLoginPassword'));
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.login(login, pass);

    if (!mounted) return;

    if (success) {
      // Явная навигация — не зависимся от _AppGate
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      setState(() {
        _loading = false;
        _errorText = LocaleService.tr(auth.error ?? 'wrongPassword');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = LocaleService.tr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon.png', width: 120, height: 120),
                const SizedBox(height: 40),

                // Поле Логин
                TextField(
                  controller: _loginController,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: tr('login'),
                    labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                  ),
                ),
                const SizedBox(height: 20),

                // Поле Пароль
                TextField(
                  controller: _passController,
                  obscureText: true,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: tr('password'),
                    labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                  ),
                ),
                const SizedBox(height: 16),

                // Текст ошибки (вместо SnackBar)
                if (_errorText != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),

                const SizedBox(height: 24),

                // Кнопка ВОЙТИ
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          tr('signIn'),
                          style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 20),

                // Кнопка перехода на регистрацию
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, String>>(
                      context,
                      AppPageRoute.slide(const RegisterPage()),
                    );
                    if (result != null && mounted) {
                      _loginController.text = result['login'] ?? '';
                      _passController.text = result['password'] ?? '';
                      setState(() => _errorText = null);
                    }
                  },
                  child: Text(
                    tr('noAccount'),
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
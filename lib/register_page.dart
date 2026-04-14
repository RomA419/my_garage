import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'locale_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

 void register() async {
  final String login = _loginController.text.trim();
  final String pass = _passController.text.trim();
  final String email = _emailController.text.trim();

  if (login.isEmpty || pass.isEmpty) return;

  final auth = context.read<AuthProvider>();
  final success = await auth.register(login, email, pass);

  if (!mounted) return;
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocaleService.tr('accountCreated'))),
    );
    Navigator.pop(context, {
      'login': login,
      'password': pass,
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleService.tr(auth.error ?? 'userExists')),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Icon(Icons.directions_car, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 40),
            TextField(
              controller: _loginController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: LocaleService.tr('login'),
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: LocaleService.tr('email'),
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passController,
              obscureText: true,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: LocaleService.tr('password'),
                labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: register,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                LocaleService.tr('createAccount'),
                style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
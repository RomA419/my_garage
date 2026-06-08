import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'locale_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _infoFuture = PackageInfo.fromPlatform();

  Future<void> _launchSupportMail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {
        'subject': 'Поддержка: вопросы по приложению',
      },
    );

    if (!await launchUrl(uri)) {
      debugPrint('Не удалось открыть почтовый клиент: $uri');
    }
  }

  Future<void> _launchWebsite() async {
    final uri = Uri.parse('https://example.com');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Не удалось открыть сайт: $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleService.tr('aboutApp')),
      ),
      body: FutureBuilder<PackageInfo>(
        future: _infoFuture,
        builder: (context, snapshot) {
          final info = snapshot.data;
          final appName = info?.appName ?? 'Моё приложение';
          final version = info != null ? '${info.version}+${info.buildNumber}' : '---';
          final packageName = info?.packageName ?? '';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Icon(
                    Icons.info_outline,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    appName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${LocaleService.tr('versionLabel')} $version',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  LocaleService.tr('aboutDescription'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  LocaleService.tr('technicalInfo'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Package: ', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(packageName, style: theme.textTheme.bodyLarge)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Build: ', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(version, style: theme.textTheme.bodyLarge),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  LocaleService.tr('supportSection'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.mail_outline, color: theme.colorScheme.primary),
                  title: Text(LocaleService.tr('contactSupport')),
                  subtitle: const Text('support@example.com'),
                  onTap: _launchSupportMail,
                  trailing: Icon(Icons.open_in_new, color: theme.iconTheme.color?.withOpacity(0.6)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.language, color: theme.colorScheme.primary),
                  title: Text(LocaleService.tr('developerWebsite')),
                  subtitle: const Text('example.com'),
                  onTap: _launchWebsite,
                  trailing: Icon(Icons.open_in_new, color: theme.iconTheme.color?.withOpacity(0.6)),
                ),

                const SizedBox(height: 24),
                Text(
                  LocaleService.tr('usedLibraries'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  '• cupertino_icons: ^1.0.8\n'
                  '• intl: ^0.20.2\n'
                  '• url_launcher: ^6.3.2\n'
                  '• shared_preferences: ^2.2.2\n'
                  '• package_info_plus: ^9.0.0',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

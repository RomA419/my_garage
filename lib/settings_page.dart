import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- Единицы измерения ---
  late String _distanceUnit; // 'km' | 'mi'
  late String _volumeUnit;   // 'l' | 'gal'
  late String _currency;     // '₸' | '$' | '€' | '₽'

  // --- Напоминания ---
  late bool _maintenanceReminder;
  late int _maintenanceIntervalKm;

  final List<String> _currencies = ['₸', '₽', '\$', '€'];
  final List<int> _intervalOptions = [5000, 10000, 15000, 20000, 30000];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final settings = auth.user?.settings ?? {};
    _distanceUnit = settings['distanceUnit'] as String? ?? 'km';
    _volumeUnit = settings['volumeUnit'] as String? ?? 'l';
    _currency = settings['currency'] as String? ?? '₸';
    _maintenanceReminder = settings['maintenanceReminder'] as bool? ?? false;
    _maintenanceIntervalKm = settings['maintenanceIntervalKm'] as int? ?? 10000;
  }

  Future<void> _saveSettings() async {
    final settings = {
      'distanceUnit': _distanceUnit,
      'volumeUnit': _volumeUnit,
      'currency': _currency,
      'maintenanceReminder': _maintenanceReminder,
      'maintenanceIntervalKm': _maintenanceIntervalKm,
    };
    context.read<AuthProvider>().updateSettings(settings);
  }

  // --- Удаление аккаунта ---
  void _confirmDeleteAccount() {
    final tr = LocaleService.tr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('deleteAccountQuestion')),
        content: Text(tr('deleteAccountConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthProvider>();
    final garage = context.read<GarageProvider>();
    garage.clear();
    await auth.deleteAccount();
    // _AppGate автоматически покажет LoginPage
  }

  // --- Сброс данных ---
  void _confirmResetData() {
    final tr = LocaleService.tr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('resetDataQuestion')),
        content: Text(tr('resetDataConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final garage = context.read<GarageProvider>();
              await garage.resetData();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('dataReset'))),
              );
            },
            child: Text(tr('reset'), style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final tr = LocaleService.tr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('settings'),
          style: TextStyle(color: theme.appBarTheme.foregroundColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // ========== ЯЗЫК ==========
          _sectionHeader(tr('language'), Icons.language, Colors.teal, theme),
          const SizedBox(height: 8),
          _buildCard(
            theme,
            isDark,
            children: [
              ValueListenableBuilder<Locale>(
                valueListenable: LocaleService.locale,
                builder: (context, locale, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('language'),
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'ru', label: Text(tr('russian'))),
                          ButtonSegment(value: 'en', label: Text(tr('english'))),
                        ],
                        selected: {locale.languageCode},
                        onSelectionChanged: (s) {
                          LocaleService.setLocale(s.first);
                          setState(() {});
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ========== ЕДИНИЦЫ ИЗМЕРЕНИЯ ==========
          _sectionHeader(tr('units'), Icons.straighten, Colors.blue, theme),
          const SizedBox(height: 8),
          _buildCard(
            theme,
            isDark,
            children: [
              _buildSegmentedRow(
                theme: theme,
                label: tr('distance'),
                value: _distanceUnit,
                options: {'km': tr('kilometers'), 'mi': tr('miles')},
                onChanged: (v) {
                  setState(() => _distanceUnit = v);
                  _saveSettings();
                },
              ),
              Divider(color: theme.dividerColor.withOpacity(0.2)),
              _buildSegmentedRow(
                theme: theme,
                label: tr('volume'),
                value: _volumeUnit,
                options: {'l': tr('liters'), 'gal': tr('gallons')},
                onChanged: (v) {
                  setState(() => _volumeUnit = v);
                  _saveSettings();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ========== ВАЛЮТА ==========
          _sectionHeader(tr('currency'), Icons.attach_money, Colors.green, theme),
          const SizedBox(height: 8),
          _buildCard(
            theme,
            isDark,
            children: [
              Wrap(
                spacing: 10,
                children: _currencies.map((c) {
                  final selected = _currency == c;
                  return ChoiceChip(
                    label: Text(
                      c,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    selected: selected,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                    onSelected: (_) {
                      setState(() => _currency = c);
                      _saveSettings();
                    },
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ========== НАПОМИНАНИЯ О ТО ==========
          _sectionHeader(tr('maintenanceReminders'), Icons.notifications_active, Colors.orange, theme),
          const SizedBox(height: 8),
          _buildCard(
            theme,
            isDark,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  tr('remindMaintenance'),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                subtitle: Text(
                  _maintenanceReminder
                      ? '${tr('every')} $_maintenanceIntervalKm ${tr('km')}'
                      : tr('off'),
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
                value: _maintenanceReminder,
                onChanged: (v) {
                  setState(() => _maintenanceReminder = v);
                  _saveSettings();
                },
              ),
              if (_maintenanceReminder) ...[
                Divider(color: theme.dividerColor.withOpacity(0.2)),
                const SizedBox(height: 4),
                Text(
                  tr('interval'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _intervalOptions.map((km) {
                    final selected = _maintenanceIntervalKm == km;
                    return ChoiceChip(
                      label: Text(
                        '${km ~/ 1000}к',
                        style: TextStyle(
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      selected: selected,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                      onSelected: (_) {
                        setState(() => _maintenanceIntervalKm = km);
                        _saveSettings();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // ========== ТЕМА ==========
          _sectionHeader(tr('appearance'), Icons.palette, Colors.purple, theme),
          const SizedBox(height: 8),
          _buildCard(
            theme,
            isDark,
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.themeMode,
                builder: (context, mode, _) {
                  final isDarkMode = mode == ThemeMode.dark;
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDarkMode,
                    onChanged: (_) => ThemeService.toggleTheme(),
                    title: Text(
                      isDarkMode ? tr('darkTheme') : tr('lightTheme'),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    secondary: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ========== ОПАСНАЯ ЗОНА ==========
          _sectionHeader(tr('dataSection'), Icons.warning_amber_rounded, Colors.red, theme),
          const SizedBox(height: 8),
          _buildCard(
            theme,
            isDark,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restart_alt, color: Colors.orange),
                title: Text(
                  tr('resetData'),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                subtitle: Text(
                  tr('resetDataSubtitle'),
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                onTap: _confirmResetData,
              ),
              Divider(color: theme.dividerColor.withOpacity(0.2)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  tr('deleteAccount'),
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: Text(
                  tr('deleteAccountSubtitle'),
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                onTap: _confirmDeleteAccount,
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Заголовок секции ---
  Widget _sectionHeader(String title, IconData icon, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // --- Карточка ---
  Widget _buildCard(ThemeData theme, bool isDark, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // --- Строка с сегментированным выбором ---
  Widget _buildSegmentedRow({
    required ThemeData theme,
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
        ),
        SegmentedButton<String>(
          segments: options.entries
              .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
              .toList(),
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

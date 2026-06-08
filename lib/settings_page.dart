import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'login_page.dart';
import 'theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- Единицы измерения ---
  late String _distanceUnit; // 'km' | 'mi'
  late String _volumeUnit; // 'l' | 'gal'
  late String _currency; // '₸' | '$' | '€' | '₽'

  // --- Напоминания ---
  late bool _maintenanceReminder;
  late int _maintenanceIntervalKm;
  late Map<String, int> _maintenanceTypeIntervals;

  final List<String> _currencies = ['₸', '₽', '\$', '€'];
  final List<int> _intervalOptions = [5000, 10000, 15000, 20000, 30000];
  static const Map<String, int> _defaultMaintenanceTypeIntervals = {
    'Замена масла': 10000,
    'Замена фильтра': 15000,
    'Замена тормозной жидкости': 40000,
    'Замена тормозных колодок': 20000,
    'Замена свечей зажигания': 30000,
    'Замена ремня ГРМ': 60000,
    'Замена шин': 12000,
    'Плановое ТО': 10000,
    'Промывка инжектора': 30000,
    'Диагностика': 15000,
    'Другое': 10000,
  };

  static const Map<String, String> _maintenanceTypeEn = {
    'Замена масла': 'Oil change',
    'Замена фильтра': 'Filter replacement',
    'Замена тормозной жидкости': 'Brake fluid replacement',
    'Замена тормозных колодок': 'Brake pad replacement',
    'Замена свечей зажигания': 'Spark plug replacement',
    'Замена ремня ГРМ': 'Timing belt replacement',
    'Замена шин': 'Tire change',
    'Плановое ТО': 'Scheduled service',
    'Промывка инжектора': 'Injector flush',
    'Диагностика': 'Diagnostics',
    'Другое': 'Other',
  };

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
    _maintenanceTypeIntervals = _resolveMaintenanceTypeIntervals(settings);
  }

  Future<void> _saveSettings() async {
    final settings = {
      'distanceUnit': _distanceUnit,
      'volumeUnit': _volumeUnit,
      'currency': _currency,
      'maintenanceReminder': _maintenanceReminder,
      'maintenanceIntervalKm': _maintenanceIntervalKm,
      'maintenanceTypeIntervals': _maintenanceTypeIntervals,
    };
    context.read<AuthProvider>().updateSettings(settings);
  }

  Map<String, int> _resolveMaintenanceTypeIntervals(
    Map<String, dynamic> settings,
  ) {
    final result = Map<String, int>.from(_defaultMaintenanceTypeIntervals);
    final raw = settings['maintenanceTypeIntervals'];
    if (raw is Map) {
      for (final key in result.keys) {
        final value = raw[key];
        if (value is int && value > 0) {
          result[key] = value;
        }
      }
    }
    return result;
  }

  String _trMaintenanceType(String type) {
    if (LocaleService.isRu) return type;
    return _maintenanceTypeEn[type] ?? type;
  }

  Future<void> _showMaintenanceTypeIntervalsDialog() async {
    final tr = LocaleService.tr;
    final draft = Map<String, int>.from(_maintenanceTypeIntervals);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('maintenanceTypeIntervalsTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('maintenanceTypeIntervalsHint'),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _defaultMaintenanceTypeIntervals.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: theme.dividerColor.withOpacity(0.2)),
                        itemBuilder: (_, index) {
                          final type = _defaultMaintenanceTypeIntervals.keys
                              .elementAt(index);
                          final selectedKm =
                              draft[type] ??
                              _defaultMaintenanceTypeIntervals[type]!;

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _trMaintenanceType(type),
                                  style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final newValue =
                                      await _showIntervalInputDialog(
                                        title: tr('maintenanceTypeIntervalFor')
                                            .replaceAll(
                                              '{type}',
                                              _trMaintenanceType(type),
                                            ),
                                        initialValue: selectedKm,
                                      );
                                  if (newValue == null) return;
                                  setModalState(() => draft[type] = newValue);
                                },
                                icon: const Icon(Icons.edit_road, size: 18),
                                label: Text('$selectedKm ${tr('km')}'),
                                style: TextButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _maintenanceTypeIntervals = draft;
                          });
                          _saveSettings();
                          Navigator.pop(ctx2);
                        },
                        child: Text(tr('save')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _showIntervalInputDialog({
    required String title,
    required int initialValue,
  }) async {
    final tr = LocaleService.tr;
    final controller = TextEditingController(text: '$initialValue');
    String? errorText;

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: tr('interval'),
                  hintText: tr('maintenanceCustomIntervalHint'),
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx2),
                  child: Text(tr('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text.trim());
                    if (value == null || value <= 0) {
                      setDialogState(
                        () => errorText = tr('maintenanceIntervalInvalid'),
                      );
                      return;
                    }
                    Navigator.pop(ctx2, value);
                  },
                  child: Text(tr('save')),
                ),
              ],
            );
          },
        );
      },
    );
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
            child: Text(
              tr('delete'),
              style: const TextStyle(color: Colors.red),
            ),
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
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(tr('dataReset'))));
            },
            child: Text(
              tr('reset'),
              style: const TextStyle(color: Colors.orange),
            ),
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
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor,
          ),
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
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'ru',
                            label: Text(tr('russian')),
                          ),
                          ButtonSegment(
                            value: 'en',
                            label: Text(tr('english')),
                          ),
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
          _sectionHeader(
            tr('currency'),
            Icons.attach_money,
            Colors.green,
            theme,
          ),
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
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    selected: selected,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade200,
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
          _sectionHeader(
            tr('maintenanceReminders'),
            Icons.notifications_active,
            Colors.orange,
            theme,
          ),
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
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade200,
                      onSelected: (_) {
                        setState(() => _maintenanceIntervalKm = km);
                        _saveSettings();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
              ],
              Divider(color: theme.dividerColor.withOpacity(0.2)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  tr('maintenanceTypeIntervalsTitle'),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                subtitle: Text(
                  tr('maintenanceTypeIntervalsHint'),
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.tune),
                onTap: _showMaintenanceTypeIntervalsDialog,
              ),
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
          _sectionHeader(
            tr('dataSection'),
            Icons.warning_amber_rounded,
            Colors.red,
            theme,
          ),
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
  Widget _sectionHeader(
    String title,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
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
  Widget _buildCard(
    ThemeData theme,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
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
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

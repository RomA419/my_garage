import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'about_page.dart';
import 'auth_provider.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
import 'login_page.dart';
import 'main_screen.dart';
import 'page_route.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isExporting = false;

  // ---------- Фото профиля ----------
  Future<void> _pickPhoto(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    final auth = context.read<AuthProvider>();
    final dir = await getApplicationDocumentsDirectory();
    final savedPath = '${dir.path}/profile_${auth.user!.login}.jpg';
    await File(image.path).copy(savedPath);

    auth.updateProfile(photoPath: savedPath);
  }

  void _showPhotoOptions() {
    final auth = context.read<AuthProvider>();
    final tr = LocaleService.tr;
    final hasPhoto =
        auth.user?.photoPath != null &&
        File(auth.user!.photoPath!).existsSync();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(tr('profileChooseFromGallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(tr('profileTakePhoto')),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  tr('profileDeletePhoto'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  auth.updateProfile(photoPath: '');
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Редактирование имени ----------
  void _editName() {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(text: auth.user?.login ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleService.tr('editName')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: LocaleService.tr('nameLogin'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                auth.updateProfile(login: newName);
              }
              Navigator.pop(ctx);
            },
            child: Text(LocaleService.tr('save')),
          ),
        ],
      ),
    );
  }

  // ---------- Редактирование email ----------
  void _editEmail() {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(text: auth.user?.email ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleService.tr('editEmail')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: LocaleService.tr('email'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              auth.updateProfile(email: controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(LocaleService.tr('save')),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return LocaleService.tr('unknown');
    try {
      final date = DateTime.parse(iso);
      final localeCode = LocaleService.locale.value.languageCode;
      return DateFormat('d MMM yyyy', localeCode).format(date);
    } catch (_) {
      return iso.split('T').first;
    }
  }

  Future<void> _exportData() async {
    final tr = LocaleService.tr;
    final auth = context.read<AuthProvider>();
    final garage = context.read<GarageProvider>();
    final user = auth.user;

    if (user == null || _isExporting) return;

    setState(() => _isExporting = true);
    try {
      final exportMap = <String, dynamic>{
        'meta': {
          'app': 'my_garage',
          'exportedAt': DateTime.now().toIso8601String(),
          'version': '1',
        },
        'user': {
          'id': user.id,
          'login': user.login,
          'email': user.email,
          'photoPath': user.photoPath,
          'registeredAt': user.registeredAt,
          'settings': user.settings,
        },
        'cars': garage.cars.map((c) => c.toMap()).toList(),
        'fuelRecords': garage.fuelRecords.map((r) => r.toMap()).toList(),
        'maintenanceRecords': garage.maintenanceRecords
            .map((r) => r.toMap())
            .toList(),
      };

      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/my_garage_export_$stamp.json');
      final content = jsonEncode(exportMap);
      await file.writeAsString(content);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('exported')}: ${file.path}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('exportFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final login = user?.login ?? '';
    final email = user?.email ?? '';
    final photoPath = user?.photoPath;
    final registeredAt = user?.registeredAt;
    final hasPhoto =
        photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync();
    final tr = LocaleService.tr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          tr('profile'),
          style: TextStyle(color: theme.appBarTheme.foregroundColor),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // ---------- Аватар с кнопкой камеры ----------
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade200,
                  backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
                  child: hasPhoto
                      ? null
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: theme.colorScheme.primary,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------- Имя + кнопка редактирования ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                login.toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _editName,
                child: Icon(
                  Icons.edit,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ---------- Email ----------
          GestureDetector(
            onTap: _editEmail,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  email.isNotEmpty ? email : tr('addEmail'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: email.isNotEmpty
                        ? theme.textTheme.bodySmall?.color
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ---------- Дата регистрации ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                '${tr('since')} ${_formatDate(registeredAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---------- Статистика гаража ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer<GarageProvider>(
              builder: (context, garage, _) {
                final totalFuel = garage.fuelRecords.length;
                final totalMaintenance = garage.maintenanceRecords.length;
                final carsCount = garage.cars.length;
                
                double totalMileage = 0;
                for (final record in garage.fuelRecords) {
                  final mileage = double.tryParse(record.odometer ?? '0') ?? 0;
                  if (mileage > totalMileage) totalMileage = mileage;
                }
                for (final record in garage.maintenanceRecords) {
                  final mileage = double.tryParse(record.odometer) ?? 0;
                  if (mileage > totalMileage) totalMileage = mileage;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(theme, Icons.directions_car, carsCount.toString(), tr('cars')),
                      _statItem(theme, Icons.speed, totalMileage.toInt().toString(), tr('km')),
                      _statItem(theme, Icons.local_gas_station, totalFuel.toString(), tr('fills')),
                      _statItem(theme, Icons.build_circle, totalMaintenance.toString(), tr('services')),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ---------- Список меню ----------
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111111) : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                children: [
                  _buildListTile(
                    Icons.settings,
                    tr('settings'),
                    Colors.blue,
                    theme,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute.slide(const SettingsPage()),
                    ),
                  ),
                  _buildListTile(
                    Icons.history,
                    tr('fuelHistory'),
                    Colors.green,
                    theme,
                    onTap: () {
                      final mainState = context
                          .findAncestorStateOfType<MainScreenState>();
                      mainState?.switchTab(1);
                    },
                  ),

                  _buildListTile(
                    Icons.download_rounded,
                    tr('exportData'),
                    Colors.teal,
                    theme,
                    trailing: _isExporting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                    onTap: _isExporting ? null : _exportData,
                  ),

                  _buildListTile(
                    Icons.info_outline,
                    tr('about'),
                    Colors.purpleAccent,
                    theme,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute.slide(const AboutPage()),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Divider(height: 40),
                  ),

                  // Кнопка выхода
                  ListTile(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(LocaleService.tr('logoutQuestion')),
                          content: Text(LocaleService.tr('logoutConfirm')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(LocaleService.tr('cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                LocaleService.tr('logout'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true || !mounted) return;
                      final authProv = context.read<AuthProvider>();
                      context.read<GarageProvider>().clear();
                      await authProv.logout();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (_) => false,
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tr('logout'),
                      style: const TextStyle(color: Colors.redAccent),
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

  Widget _buildListTile(
    IconData icon,
    String title,
    Color color,
    ThemeData theme, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios,
            color: theme.iconTheme.color?.withOpacity(0.6),
            size: 14,
          ),
      onTap: onTap,
    );
  }

  Widget _statItem(ThemeData theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

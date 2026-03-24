import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'about_page.dart';
import 'auth_provider.dart';
import 'garage_provider.dart';
import 'locale_service.dart';
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
    final hasPhoto = auth.user?.photoPath != null && File(auth.user!.photoPath!).existsSync();
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
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
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
    if (iso == null || iso.isEmpty) return 'Неизвестно';
    try {
      final date = DateTime.parse(iso);
      const months = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
                       'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
      return '${date.day} ${months[date.month]} ${date.year}';
    } catch (_) {
      return iso.split('T').first;
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
    final hasPhoto = photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync();
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
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                  backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
                  child: hasPhoto
                      ? null
                      : Icon(Icons.person, size: 60, color: theme.colorScheme.primary),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, size: 18, color: theme.colorScheme.onPrimary),
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
                child: Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
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
                Icon(Icons.email_outlined, size: 16, color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
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
              Icon(Icons.calendar_today, size: 14, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                '${tr('since')} ${_formatDate(registeredAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

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
                  _buildListTile(Icons.settings, tr('settings'), Colors.blue, theme,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute.slide(const SettingsPage()),
                    ),
                  ),
                  _buildListTile(Icons.history, tr('fuelHistory'), Colors.green, theme,
                    onTap: () {
                      final mainState = context.findAncestorStateOfType<MainScreenState>();
                      mainState?.switchTab(1);
                    },
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
                              child: Text(LocaleService.tr('logout'), style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true || !mounted) return;
                      final authProv = context.read<AuthProvider>();
                      context.read<GarageProvider>().clear();
                      await authProv.logout();
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red, size: 20),
                    ),
                    title: Text(tr('logout'), style: const TextStyle(color: Colors.redAccent)),
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
      title: Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color?.withOpacity(0.6), size: 14),
      onTap: onTap,
    );
  }
}
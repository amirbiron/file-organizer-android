import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoOrganize = false;
  bool _notifications = true;
  bool _createBackups = true;
  bool _compressImages = false;
  double _compressionQuality = 85.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppearanceSection(),
            const SizedBox(height: 24),
            _buildOrganizationSection(),
            const SizedBox(height: 24),
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            _buildStorageSection(),
            const SizedBox(height: 24),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSection(
      title: 'מראה',
      icon: Icons.palette_outlined,
      children: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('עיצוב'),
              subtitle: Text(
                themeProvider.themeMode == ThemeMode.system
                    ? 'לפי מערכת'
                    : themeProvider.isDarkMode
                        ? 'כהה'
                        : 'בהיר',
              ),
              trailing: DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                underline: Container(),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('לפי מערכת'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('בהיר'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('כהה'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                  }
                },
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.language, color: Theme.of(context).primaryColor),
          title: const Text('שפה'),
          subtitle: const Text('עברית'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showLanguageDialog(),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildOrganizationSection() {
    return _buildSection(
      title: 'סידור קבצים',
      icon: Icons.auto_fix_high,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.schedule, color: Theme.of(context).primaryColor),
          title: const Text('סידור אוטומטי'),
          subtitle: const Text('סדר קבצים אוטומטית כל יום'),
          value: _autoOrganize,
          onChanged: (value) {
            setState(() {
              _autoOrganize = value;
            });
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.backup, color: Theme.of(context).primaryColor),
          title: const Text('יצירת גיבויים'),
          subtitle: const Text('גבה קבצים לפני שינוי'),
          value: _createBackups,
          onChanged: (value) {
            setState(() {
              _createBackups = value;
            });
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.compress, color: Theme.of(context).primaryColor),
          title: const Text('דחיסת תמונות'),
          subtitle: const Text('דחס תמונות אוטומטית'),
          value: _compressImages,
          onChanged: (value) {
            setState(() {
              _compressImages = value;
            });
          },
        ),
        if (_compressImages) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'איכות דחיסה: ${_compressionQuality.round()}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _compressionQuality,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  onChanged: (value) {
                    setState(() {
                      _compressionQuality = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.3);
  }

  Widget _buildNotificationsSection() {
    return _buildSection(
      title: 'התראות',
      icon: Icons.notifications_outlined,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
          title: const Text('התראות'),
          subtitle: const Text('קבל עדכונים על סידור קבצים'),
          value: _notifications,
          onChanged: (value) {
            setState(() {
              _notifications = value;
            });
          },
        ),
        ListTile(
          leading: Icon(Icons.schedule, color: Theme.of(context).primaryColor),
          title: const Text('זמן סידור יומי'),
          subtitle: const Text('20:00'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          enabled: _autoOrganize,
          onTap: _autoOrganize ? () => _showTimePickerDialog() : null,
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.3);
  }

  Widget _buildStorageSection() {
    return _buildSection(
      title: 'אחסון',
      icon: Icons.storage_outlined,
      children: [
        ListTile(
          leading: Icon(Icons.cleaning_services, color: Theme.of(context).primaryColor),
          title: const Text('נקה זמנים'),
          subtitle: const Text('מחק קבצים זמניים'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showCleanTempDialog(),
        ),
        ListTile(
          leading: Icon(Icons.analytics, color: Theme.of(context).primaryColor),
          title: const Text('ניתוח שימוש'),
          subtitle: const Text('צפה בסטטיסטיקות מפורטות'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showUsageAnalytics(),
        ),
        ListTile(
          leading: Icon(Icons.folder_outlined, color: Theme.of(context).primaryColor),
          title: const Text('תיקיות מוחרגות'),
          subtitle: const Text('תיקיות שלא יסודרו'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showExcludedFolders(),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'אודות',
      icon: Icons.info_outline,
      children: [
        ListTile(
          leading: Icon(Icons.info, color: Theme.of(context).primaryColor),
          title: const Text('גרסה'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: Icon(Icons.help, color: Theme.of(context).primaryColor),
          title: const Text('עזרה ותמיכה'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showHelpDialog(),
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip, color: Theme.of(context).primaryColor),
          title: const Text('מדיניות פרטיות'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showPrivacyPolicy(),
        ),
        ListTile(
          leading: Icon(Icons.star, color: Theme.of(context).primaryColor),
          title: const Text('דרג את האפליקציה'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _rateApp(),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 800.ms).slideY(begin: 0.3);
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר שפה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇮🇱'),
              title: const Text('עברית'),
              trailing: const Icon(Icons.check, color: Colors.green),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePickerDialog() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (time != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('זמן סידור עודכן ל-${time.format(context)}')),
      );
    }
  }

  void _showCleanTempDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ניקוי קבצים זמניים'),
        content: const Text('פעולה זו תמחק את כל הקבצים הזמניים. האם להמשיך?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('קבצים זמניים נמחקו בהצלחה')),
              );
            },
            child: const Text('נקה'),
          ),
        ],
      ),
    );
  }

  void _showUsageAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ניתוח שימוש'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsItem('קבצים שסודרו השבוע', '247'),
            _buildAnalyticsItem('מקום שנחסך', '1.2 GB'),
            _buildAnalyticsItem('כפילויות שנמחקו', '34'),
            _buildAnalyticsItem('זמן שחסכת', '2.5 שעות'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showExcludedFolders() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('תיקיות מוחרגות'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('תיקיות אלה לא יסודרו:'),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.folder),
              title: Text('System'),
            ),
            const ListTile(
              leading: Icon(Icons.folder),
              title: Text('Android'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('הוסף תיקיה'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('עזרה ותמיכה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('זקוק לעזרה? אנחנו כאן בשבילך!'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('שלח אימייל'),
              contentPadding: EdgeInsets.zero,
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('צ\'אט עם תמיכה'),
              contentPadding: EdgeInsets.zero,
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('שאלות נפוצות'),
              contentPadding: EdgeInsets.zero,
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מדיניות פרטיות'),
        content: const SingleChildScrollView(
          child: Text(
            'האפליקציה FileOrganizer מכבדת את הפרטיות שלך.\n\n'
            '• כל הנתונים נשמרים מקומית בטלפון שלך\n'
            '• לא נאספים נתונים אישיים\n'
            '• לא נשלח מידע לשרתים חיצוניים\n'
            '• הגישה לקבצים היא רק לצורך סידור וניהול\n\n'
            'לשאלות נוספות, פנה אלינו.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('הבנתי'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('דרג את האפליקציה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('נשמח לדעתך על האפליקציה!'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('תודה על הדירוג ${index + 1} כוכבים!')),
                    );
                  },
                  icon: const Icon(Icons.star_border, size: 32),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('אולי מאוחר יותר'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/file_organizer_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/action_button.dart';
import '../widgets/recent_activity.dart';
import 'organize_screen.dart';
import 'gallery_screen.dart';
import 'documents_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileOrganizerProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'שלום! 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
            const SizedBox(height: 4),
            Text(
              'בוא נסדר את הקבצים שלך',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: -0.2),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings_outlined, size: 28),
        ).animate().fadeIn(duration: 600.ms, delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Consumer<FileOrganizerProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'סטטיסטיקות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'תמונות',
                    value: provider.stats.totalImages.toString(),
                    icon: Icons.image_outlined,
                    color: Colors.blue,
                  ).animate().fadeIn(duration: 600.ms, delay: 800.ms).slideY(begin: 0.3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'מסמכים',
                    value: provider.stats.totalDocuments.toString(),
                    icon: Icons.description_outlined,
                    color: Colors.green,
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms).slideY(begin: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'כפילויות',
                    value: provider.stats.duplicates.toString(),
                    icon: Icons.content_copy_outlined,
                    color: Colors.orange,
                  ).animate().fadeIn(duration: 600.ms, delay: 1200.ms).slideY(begin: 0.3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'שטח נחסך',
                    value: '${provider.stats.spaceSavedMB.toStringAsFixed(1)} MB',
                    icon: Icons.storage_outlined,
                    color: Colors.purple,
                  ).animate().fadeIn(duration: 600.ms, delay: 1400.ms).slideY(begin: 0.3),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פעולות מהירות',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 1600.ms),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            ActionButton(
              title: 'סדר אוטומטי',
              subtitle: 'כל הקבצים',
              icon: Icons.auto_fix_high,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrganizeScreen()),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 1800.ms).scale(begin: const Offset(0.8, 0.8)),
            
            ActionButton(
              title: 'גלריה',
              subtitle: 'תמונות וסרטונים',
              icon: Icons.photo_library_outlined,
              color: Colors.pink,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GalleryScreen()),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 2000.ms).scale(begin: const Offset(0.8, 0.8)),
            
            ActionButton(
              title: 'מסמכים',
              subtitle: 'PDFs ודוקים',
              icon: Icons.folder_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsScreen()),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 2200.ms).scale(begin: const Offset(0.8, 0.8)),
            
            ActionButton(
              title: 'ניקוי מהיר',
              subtitle: 'מחק מיותרים',
              icon: Icons.cleaning_services_outlined,
              color: Colors.red,
              onTap: () => _showQuickCleanDialog(),
            ).animate().fadeIn(duration: 600.ms, delay: 2400.ms).scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פעילות אחרונה',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 2600.ms),
        const SizedBox(height: 16),
        const RecentActivity().animate().fadeIn(duration: 600.ms, delay: 2800.ms).slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).surfaceVariant.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home, 'בית', true),
              _buildNavItem(Icons.analytics_outlined, 'ניתוח', false),
              _buildNavItem(Icons.history, 'היסטוריה', false),
              _buildNavItem(Icons.settings_outlined, 'הגדרות', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).unselectedWidgetColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).unselectedWidgetColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickCleanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ניקוי מהיר'),
        content: const Text('האם אתה בטוח שאתה רוצה למחוק קבצים מיותרים?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FileOrganizerProvider>().performQuickClean();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ניקוי הושלם בהצלחה!')),
              );
            },
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
}

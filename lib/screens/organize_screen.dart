import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/file_organizer_provider.dart';

class OrganizeScreen extends StatefulWidget {
  const OrganizeScreen({Key? key}) : super(key: key);

  @override
  State<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends State<OrganizeScreen> {
  bool _organizePictures = true;
  bool _organizeDocuments = true;
  bool _removeDuplicates = true;
  bool _compressImages = false;
  bool _createBackup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('סידור קבצים'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<FileOrganizerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingScreen();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildOptionsSection(),
                const SizedBox(height: 32),
                _buildActionButton(provider),
                const SizedBox(height: 24),
                _buildInfoSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'מסדר את הקבצים שלך...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'זה יכול לקחת כמה דקות',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'בחר אפשרויות סידור',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
        const SizedBox(height: 8),
        Text(
          'האפליקציה תסדר את הקבצים שלך לפי ההעדפות שתבחר',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: -0.2),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'אפשרויות סידור',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              title: 'סדר תמונות',
              subtitle: 'מיון לפי תאריכים ומיקומים',
              icon: Icons.image_outlined,
              value: _organizePictures,
              onChanged: (value) => setState(() => _organizePictures = value),
            ),
            _buildOptionTile(
              title: 'סדר מסמכים',
              subtitle: 'מיון לפי סוגי קבצים',
              icon: Icons.description_outlined,
              value: _organizeDocuments,
              onChanged: (value) => setState(() => _organizeDocuments = value),
            ),
            _buildOptionTile(
              title: 'מחק כפילויות',
              subtitle: 'זיהוי ומחיקת קבצים זהים',
              icon: Icons.content_copy_outlined,
              value: _removeDuplicates,
              onChanged: (value) => setState(() => _removeDuplicates = value),
            ),
            _buildOptionTile(
              title: 'דחס תמונות',
              subtitle: 'הקטנת גודל תמונות לחיסכון במקום',
              icon: Icons.compress,
              value: _compressImages,
              onChanged: (value) => setState(() => _compressImages = value),
            ),
            _buildOptionTile(
              title: 'צור גיבוי',
              subtitle: 'גיבוי קבצים חשובים לפני שינוי',
              icon: Icons.backup_outlined,
              value: _createBackup,
              onChanged: (value) => setState(() => _createBackup = value),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.3);
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(FileOrganizerProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _hasAnyOptionSelected() ? () => _startOrganizing(provider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_fix_high, size: 24),
            const SizedBox(width: 8),
            Text(
              'התחל סידור',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildInfoSection() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'מידע חשוב',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem('• התהליך יכול לקחת זמן תלוי בכמות הקבצים'),
            _buildInfoItem('• קבצים יועברו לתיקיות מסודרות חדשות'),
            _buildInfoItem('• האפליקציה תשמור על הקבצים המקוריים במידת הצורך'),
            _buildInfoItem('• ניתן לעצור את התהליך בכל שלב'),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 1000.ms).slideY(begin: 0.3);
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  bool _hasAnyOptionSelected() {
    return _organizePictures || _organizeDocuments || _removeDuplicates || _compressImages;
  }

  Future<void> _startOrganizing(FileOrganizerProvider provider) async {
    try {
      final result = await provider.organizeFiles(
        organizePictures: _organizePictures,
        organizeDocuments: _organizeDocuments,
        removeDuplicates: _removeDuplicates,
        compressImages: _compressImages,
      );

      if (mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בסידור הקבצים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResultDialog(dynamic result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('סידור הושלם!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('הסידור הושלם בהצלחה:'),
            const SizedBox(height: 16),
            _buildResultItem('קבצים שעובדו', '${result.processedFiles}'),
            _buildResultItem('כפילויות נמחקו', '${result.duplicatesRemoved}'),
            _buildResultItem('שטח נחסך', '${result.spaceSaved.toStringAsFixed(1)} MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('סיום'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
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
}

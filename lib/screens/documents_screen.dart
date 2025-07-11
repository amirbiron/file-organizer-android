import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<File> _documents = [];
  bool _isLoading = true;
  String _selectedCategory = 'הכל';
  
  final List<String> _categories = ['הכל', 'PDFs', 'Word', 'Excel', 'PowerPoint', 'אחר'];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate loading documents from Downloads folder
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _documents = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מסמכים'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: _searchDocuments,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildStatsBar(),
          Expanded(
            child: _isLoading ? _buildLoadingWidget() : _buildDocumentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _organizeDocuments,
        icon: const Icon(Icons.folder_outlined),
        label: const Text('סדר מסמכים'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.transparent,
              selectedColor: Colors.teal.withOpacity(0.2),
              side: BorderSide(
                color: isSelected ? Colors.teal : Theme.of(context).dividerColor,
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.5);
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('סה"כ מסמכים', '234', Icons.description),
          _buildStatItem('PDFs', '67', Icons.picture_as_pdf),
          _buildStatItem('Word', '45', Icons.text_snippet),
          _buildStatItem('גודל כולל', '2.3 GB', Icons.storage),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.3);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.teal,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.teal.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.teal),
    );
  }

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'לא נמצאו מסמכים',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'נסה לרענן או לבדוק את תיקיית ההורדות',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('רענן'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        return _buildDocumentTile(_documents[index], index);
      },
    );
  }

  Widget _buildDocumentTile(File document, int index) {
    final fileName = document.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final fileIcon = _getFileIcon(extension);
    final fileColor = _getFileColor(extension);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: fileColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(fileIcon, color: fileColor),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${_getFileSize(document)} • ${_getFileDate(document)}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: ListTile(
                leading: Icon(Icons.open_in_new),
                title: Text('פתח'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('שתף'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('מחק'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) => _handleDocumentAction(value.toString(), document),
        ),
        onTap: () => _openDocument(document),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: (index * 100).ms).slideX(begin: 0.3);
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.text_snippet;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_fields;
      default:
        return Icons.description;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  String _getFileSize(File file) {
    // Simulate file size
    return '2.3 MB';
  }

  String _getFileDate(File file) {
    // Simulate file date
    return 'היום';
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'מיון לפי',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('תאריך שינוי'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('גודל קובץ'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.abc),
              title: const Text('שם'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('סוג קובץ'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _searchDocuments() {
    showSearch(
      context: context,
      delegate: DocumentSearchDelegate(_documents),
    );
  }

  void _organizeDocuments() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סידור מסמכים'),
        content: const Text('האם אתה רוצה לסדר את המסמכים לתיקיות לפי סוגים?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performOrganization();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('סדר', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performOrganization() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('מסדר מסמכים...'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _openDocument(File document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('פותח: ${document.path.split('/').last}')),
    );
  }

  void _handleDocumentAction(String action, File document) {
    switch (action) {
      case 'open':
        _openDocument(document);
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('משתף קובץ...')),
        );
        break;
      case 'delete':
        _confirmDelete(document);
        break;
    }
  }

  void _confirmDelete(File document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת קובץ'),
        content: Text('האם אתה בטוח שאתה רוצה למחוק את ${document.path.split('/').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _documents.remove(document);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('קובץ נמחק')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class DocumentSearchDelegate extends SearchDelegate<File?> {
  final List<File> documents;

  DocumentSearchDelegate(this.documents);

  @override
  String get searchFieldLabel => 'חפש מסמכים...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredDocuments = documents.where((doc) =>
        doc.path.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: filteredDocuments.length,
      itemBuilder: (context, index) {
        final doc = filteredDocuments[index];
        return ListTile(
          title: Text(doc.path.split('/').last),
          onTap: () => close(context, doc),
        );
      },
    );
  }
}

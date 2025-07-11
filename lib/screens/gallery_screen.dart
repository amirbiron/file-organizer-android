import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _images = [];
  bool _isLoading = true;
  String _selectedCategory = 'הכל';
  
  final List<String> _categories = ['הכל', 'אמש', 'השבוע', 'החודש', 'השנה'];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final images = await recentAlbum.getAssetListRange(start: 0, end: 100);
        setState(() {
          _images = images;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<AssetEntity> get _filteredImages {
    final now = DateTime.now();
    switch (_selectedCategory) {
      case 'אמש':
        return _images.where((img) => 
            now.difference(img.createDateTime).inDays == 0).toList();
      case 'השבוע':
        return _images.where((img) => 
            now.difference(img.createDateTime).inDays <= 7).toList();
      case 'החודש':
        return _images.where((img) => 
            now.difference(img.createDateTime).inDays <= 30).toList();
      case 'השנה':
        return _images.where((img) => 
            now.difference(img.createDateTime).inDays <= 365).toList();
      default:
        return _images;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('גלריה'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: _showSelectOptions,
            icon: const Icon(Icons.select_all),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading ? _buildLoadingWidget() : _buildImageGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _organizeSelectedImages,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('סדר נבחרים'),
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
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).dividerColor,
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.5);
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildImageGrid() {
    final filteredImages = _filteredImages;
    
    if (filteredImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'לא נמצאו תמונות',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredImages.length,
      itemBuilder: (context, index) {
        final asset = filteredImages[index];
        return _buildImageTile(asset, index);
      },
    );
  }

  Widget _buildImageTile(AssetEntity asset, int index) {
    return GestureDetector(
      onTap: () => _viewImage(asset),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AssetEntityImage(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: (index * 50).ms).scale(begin: const Offset(0.8, 0.8));
  }

  void _viewImage(AssetEntity asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewScreen(asset: asset),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('מיון לפי תאריך'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('מיון לפי גודל'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.abc),
              title: const Text('מיון לפי שם'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('בחר הכל'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('בחר כפילויות'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.blur_on),
              title: const Text('בחר תמונות מטושטשות'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _organizeSelectedImages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('מסדר תמונות נבחרות...'),
      ),
    );
  }
}

class _ImageViewScreen extends StatelessWidget {
  final AssetEntity asset;

  const _ImageViewScreen({Key? key, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _showImageOptions(context),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: AssetEntityImage(
          asset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: const Text('מחק', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('שתף', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('פרטים', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import '../models/file_stats.dart';
import '../models/organize_result.dart';
import '../services/file_service.dart';

class FileOrganizerProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  
  FileStats _stats = FileStats();
  bool _isLoading = false;
  List<OrganizeResult> _recentResults = [];
  
  FileStats get stats => _stats;
  bool get isLoading => _isLoading;
  List<OrganizeResult> get recentResults => _recentResults;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _requestPermissions();
      await _calculateStats();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
    ];

    for (final permission in permissions) {
      if (await permission.isDenied) {
        await permission.request();
      }
    }
  }

  Future<void> _calculateStats() async {
    try {
      // ספירת תמונות
      final result = await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        final albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
        );
        
        int totalImages = 0;
        for (final album in albums) {
          final count = await album.assetCountAsync;
          totalImages += count;
        }
        _stats = _stats.copyWith(totalImages: totalImages);
      }

      // ספירת מסמכים
      final documentsDir = await getExternalStorageDirectory();
      if (documentsDir != null) {
        final documents = await _countDocuments(documentsDir);
        _stats = _stats.copyWith(totalDocuments: documents);
      }

      // זיהוי כפילויות
      final duplicates = await _findDuplicates();
      _stats = _stats.copyWith(duplicates: duplicates.length);

      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating stats: $e');
    }
  }

  Future<int> _countDocuments(Directory dir) async {
    int count = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (['pdf', 'doc', 'docx', 'txt', 'xlsx', 'ppt', 'pptx'].contains(extension)) {
            count++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error counting documents: $e');
    }
    return count;
  }

  Future<List<File>> _findDuplicates() async {
    final duplicates = <File>[];
    final fileHashes = <String, File>{};

    try {
      final result = await PhotoManager.requestPermissionExtend();
      if (result.isAuth) {
        final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
        
        for (final album in albums) {
          final assets = await album.getAssetListRange(start: 0, end: 100);
          
          for (final asset in assets) {
            final file = await asset.file;
            if (file != null) {
              final hash = await _calculateFileHash(file);
              if (fileHashes.containsKey(hash)) {
                duplicates.add(file);
              } else {
                fileHashes[hash] = file;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding duplicates: $e');
    }

    return duplicates;
  }

  Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating hash: $e');
      return '';
    }
  }

  Future<OrganizeResult> organizeFiles({
    bool organizePictures = true,
    bool organizeDocuments = true,
    bool removeDuplicates = true,
    bool compressImages = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    int processedFiles = 0;
    int duplicatesRemoved = 0;
    double spaceSaved = 0;

    try {
      if (organizePictures) {
        final result = await _organizePictures();
        processedFiles += result.processedFiles;
        spaceSaved += result.spaceSaved;
      }

      if (organizeDocuments) {
        final result = await _organizeDocuments();
        processedFiles += result.processedFiles;
        spaceSaved += result.spaceSaved;
      }

      if (removeDuplicates) {
        final result = await _removeDuplicates();
        duplicatesRemoved = result.duplicatesRemoved;
        spaceSaved += result.spaceSaved;
      }

      if (compressImages) {
        final result = await _compressImages();
        spaceSaved += result.spaceSaved;
      }

      final organizeResult = OrganizeResult(
        processedFiles: processedFiles,
        duplicatesRemoved: duplicatesRemoved,
        spaceSaved: spaceSaved,
        timestamp: DateTime.now(),
      );

      _recentResults.insert(0, organizeResult);
      if (_recentResults.length > 10) {
        _recentResults.removeLast();
      }

      // עדכון סטטיסטיקות
      _stats = _stats.copyWith(
        duplicates: _stats.duplicates - duplicatesRemoved,
        spaceSavedMB: _stats.spaceSavedMB + spaceSaved,
      );

      return organizeResult;
    } catch (e) {
      debugPrint('Error organizing files: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<_OrganizeResult> _organizePictures() async {
    int processedFiles = 0;
    double spaceSaved = 0;

    try {
      final result = await PhotoManager.requestPermissionExtend();
      if (!result.isAuth) return _OrganizeResult(0, 0);

      // יצירת תיקיות מסודרות
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return _OrganizeResult(0, 0);

      final organizedDir = Directory('${externalDir.path}/Organized/Pictures');
      if (!await organizedDir.exists()) {
        await organizedDir.create(recursive: true);
      }

      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      
      for (final album in albums) {
        final assets = await album.getAssetListRange(start: 0, end: 50);
        
        for (final asset in assets) {
          final file = await asset.file;
          if (file != null) {
            // סיווג לפי תאריך
            final date = asset.createDateTime;
            final year = date.year.toString();
            final month = date.month.toString().padLeft(2, '0');
            
            final targetDir = Directory('${organizedDir.path}/$year/$month');
            if (!await targetDir.exists()) {
              await targetDir.create(recursive: true);
            }

            final newPath = '${targetDir.path}/${file.path.split('/').last}';
            await file.copy(newPath);
            processedFiles++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error organizing pictures: $e');
    }

    return _OrganizeResult(processedFiles, spaceSaved);
  }

  Future<_OrganizeResult> _organizeDocuments() async {
    int processedFiles = 0;
    double spaceSaved = 0;

    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return _OrganizeResult(0, 0);

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) return _OrganizeResult(0, 0);

      final organizedDir = Directory('${externalDir.path}/Organized/Documents');
      if (!await organizedDir.exists()) {
        await organizedDir.create(recursive: true);
      }

      await for (final entity in downloadsDir.list()) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          final fileType = _getFileType(extension);
          
          if (fileType != 'other') {
            final targetDir = Directory('${organizedDir.path}/$fileType');
            if (!await targetDir.exists()) {
              await targetDir.create(recursive: true);
            }

            final fileName = entity.path.split('/').last;
            final newPath = '${targetDir.path}/$fileName';
            await entity.copy(newPath);
            processedFiles++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error organizing documents: $e');
    }

    return _OrganizeResult(processedFiles, spaceSaved);
  }

  String _getFileType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'PDFs';
      case 'doc':
      case 'docx':
        return 'Word Documents';
      case 'xls':
      case 'xlsx':
        return 'Spreadsheets';
      case 'ppt':
      case 'pptx':
        return 'Presentations';
      case 'txt':
        return 'Text Files';
      case 'zip':
      case 'rar':
      case '7z':
        return 'Archives';
      default:
        return 'other';
    }
  }

  Future<_DuplicateResult> _removeDuplicates() async {
    int duplicatesRemoved = 0;
    double spaceSaved = 0;

    try {
      final duplicates = await _findDuplicates();
      
      for (final duplicate in duplicates) {
        final size = await duplicate.length();
        await duplicate.delete();
        duplicatesRemoved++;
        spaceSaved += size / (1024 * 1024); // MB
      }
    } catch (e) {
      debugPrint('Error removing duplicates: $e');
    }

    return _DuplicateResult(duplicatesRemoved, spaceSaved);
  }

  Future<_CompressResult> _compressImages() async {
    double spaceSaved = 0;

    try {
      final result = await PhotoManager.requestPermissionExtend();
      if (!result.isAuth) return _CompressResult(0);

      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      
      for (final album in albums) {
        final assets = await album.getAssetListRange(start: 0, end: 20);
        
        for (final asset in assets) {
          final file = await asset.file;
          if (file != null) {
            final originalSize = await file.length();
            
            // דחיסת התמונה
            final compressedFile = await _compressImage(file);
            if (compressedFile != null) {
              final newSize = await compressedFile.length();
              spaceSaved += (originalSize - newSize) / (1024 * 1024);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error compressing images: $e');
    }

    return _CompressResult(spaceSaved);
  }

  Future<File?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        // שינוי גודל אם התמונה גדולה מדי
        final resized = image.width > 1920 || image.height > 1920
            ? img.copyResize(image, width: 1920, height: 1920, maintainAspect: true)
            : image;
        
        // דחיסה עם איכות 85%
        final compressed = img.encodeJpg(resized, quality: 85);
        
        // שמירה על הקובץ המקורי
        await file.writeAsBytes(compressed);
        return file;
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
    }
    return null;
  }

  Future<void> performQuickClean() async {
    _isLoading = true;
    notifyListeners();

    try {
      // מחיקת קבצי זמן
      await _cleanTempFiles();
      
      // מחיקת screenshots ישנים
      await _cleanOldScreenshots();
      
      // מחיקת קבצים ריקים
      await _cleanEmptyFiles();
      
      // עדכון סטטיסטיקות
      await _calculateStats();
    } catch (e) {
      debugPrint('Error in quick clean: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cleanTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }
    } catch (e) {
      debugPrint('Error cleaning temp files: $e');
    }
  }

  Future<void> _cleanOldScreenshots() async {
    try {
      final result = await PhotoManager.requestPermissionExtend();
      if (!result.isAuth) return;

      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      for (final album in albums) {
        final assets = await album.getAssetListRange(start: 0, end: 100);
        
        for (final asset in assets) {
          final file = await asset.file;
          if (file != null && 
              file.path.toLowerCase().contains('screenshot') &&
              asset.createDateTime.isBefore(cutoffDate)) {
            try {
              await file.delete();
            } catch (e) {
              debugPrint('Could not delete screenshot: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning screenshots: $e');
    }
  }

  Future<void> _cleanEmptyFiles() async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return;

      await for (final entity in externalDir.list(recursive: true)) {
        if (entity is File) {
          final size = await entity.length();
          if (size == 0) {
            try {
              await entity.delete();
            } catch (e) {
              debugPrint('Could not delete empty file: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning empty files: $e');
    }
  }
}

// Helper classes
class _OrganizeResult {
  final int processedFiles;
  final double spaceSaved;
  
  _OrganizeResult(this.processedFiles, this.spaceSaved);
}

class _DuplicateResult {
  final int duplicatesRemoved;
  final double spaceSaved;
  
  _DuplicateResult(this.duplicatesRemoved, this.spaceSaved);
}

class _CompressResult {
  final double spaceSaved;
  
  _CompressResult(this.spaceSaved);
}

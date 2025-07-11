import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:crypto/crypto.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// בדיקת הרשאות לגישה לקבצים
  Future<bool> checkPermissions() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  /// קבלת רשימת כל התמונות במכשיר
  Future<List<AssetEntity>> getAllImages() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    final List<AssetEntity> allImages = [];
    
    for (final album in albums) {
      final images = await album.getAssetListPaged(page: 0, size: 1000);
      allImages.addAll(images);
    }
    
    return allImages;
  }

  /// קבלת רשימת כל הסרטונים במכשיר
  Future<List<AssetEntity>> getAllVideos() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.video);
    final List<AssetEntity> allVideos = [];
    
    for (final album in albums) {
      final videos = await album.getAssetListPaged(page: 0, size: 1000);
      allVideos.addAll(videos);
    }
    
    return allVideos;
  }

  /// קבלת רשימת כל המסמכים במכשיר
  Future<List<File>> getAllDocuments() async {
    final List<File> documents = [];
    
    try {
      // חיפוש בתיקיית Downloads
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        await _scanDirectoryForDocuments(downloadsDir, documents);
      }
      
      // חיפוש בתיקיית Documents
      final documentsDir = Directory('/storage/emulated/0/Documents');
      if (await documentsDir.exists()) {
        await _scanDirectoryForDocuments(documentsDir, documents);
      }
      
      // חיפוש בתיקיות נוספות
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        await _scanDirectoryForDocuments(externalDir, documents);
      }
    } catch (e) {
      print('Error scanning for documents: $e');
    }
    
    return documents;
  }

  /// סריקת תיקיה למסמכים
  Future<void> _scanDirectoryForDocuments(Directory dir, List<File> documents) async {
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && _isDocumentFile(entity.path)) {
          documents.add(entity);
        }
      }
    } catch (e) {
      print('Error scanning directory ${dir.path}: $e');
    }
  }

  /// בדיקה האם קובץ הוא מסמך
  bool _isDocumentFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    const documentExtensions = [
      'pdf', 'doc', 'docx', 'txt', 'rtf',
      'xls', 'xlsx', 'csv',
      'ppt', 'pptx',
      'zip', 'rar', '7z'
    ];
    return documentExtensions.contains(extension);
  }

  /// זיהוי כפילויות תמונות
  Future<List<AssetEntity>> findDuplicateImages() async {
    final images = await getAllImages();
    final Map<String, List<AssetEntity>> hashGroups = {};
    final List<AssetEntity> duplicates = [];
    
    for (final image in images) {
      try {
        final file = await image.file;
        if (file != null) {
          final hash = await _calculateFileHash(file);
          if (hashGroups.containsKey(hash)) {
            hashGroups[hash]!.add(image);
            if (hashGroups[hash]!.length == 2) {
              // הוסף את התמונה הראשונה כשמוצאים את השנייה
              duplicates.add(hashGroups[hash]!.first);
            }
            duplicates.add(image);
          } else {
            hashGroups[hash] = [image];
          }
        }
      } catch (e) {
        print('Error processing image: $e');
      }
    }
    
    return duplicates;
  }

  /// זיהוי כפילויות מסמכים
  Future<List<File>> findDuplicateDocuments() async {
    final documents = await getAllDocuments();
    final Map<String, List<File>> hashGroups = {};
    final List<File> duplicates = [];
    
    for (final doc in documents) {
      try {
        final hash = await _calculateFileHash(doc);
        if (hashGroups.containsKey(hash)) {
          hashGroups[hash]!.add(doc);
          if (hashGroups[hash]!.length == 2) {
            duplicates.add(hashGroups[hash]!.first);
          }
          duplicates.add(doc);
        } else {
          hashGroups[hash] = [doc];
        }
      } catch (e) {
        print('Error processing document: $e');
      }
    }
    
    return duplicates;
  }

  /// חישוב hash לקובץ
  Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('Error calculating hash for ${file.path}: $e');
      return '';
    }
  }

  /// יצירת תיקייה מסודרת לתמונות
  Future<Directory> createOrganizedImageFolder(DateTime date) async {
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) throw Exception('Cannot access external storage');
    
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    
    final organizedDir = Directory('${externalDir.path}/Organized/Pictures/$year/$month');
    if (!await organizedDir.exists()) {
      await organizedDir.create(recursive: true);
    }
    
    return organizedDir;
  }

  /// יצירת תיקייה מסודרת למסמכים
  Future<Directory> createOrganizedDocumentFolder(String fileType) async {
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) throw Exception('Cannot access external storage');
    
    final organizedDir = Directory('${externalDir.path}/Organized/Documents/$fileType');
    if (!await organizedDir.exists()) {
      await organizedDir.create(recursive: true);
    }
    
    return organizedDir;
  }

  /// העברת תמונה לתיקיה מסודרת
  Future<bool> moveImageToOrganizedFolder(AssetEntity image) async {
    try {
      final file = await image.file;
      if (file == null) return false;
      
      final targetDir = await createOrganizedImageFolder(image.createDateTime);
      final fileName = file.path.split('/').last;
      final targetPath = '${targetDir.path}/$fileName';
      
      // בדיקה שהקובץ לא קיים כבר
      if (await File(targetPath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameWithoutExt = fileName.split('.').first;
        final extension = fileName.split('.').last;
        final newName = '${nameWithoutExt}_$timestamp.$extension';
        final newTargetPath = '${targetDir.path}/$newName';
        await file.copy(newTargetPath);
      } else {
        await file.copy(targetPath);
      }
      
      return true;
    } catch (e) {
      print('Error moving image: $e');
      return false;
    }
  }

  /// העברת מסמך לתיקיה מסודרת
  Future<bool> moveDocumentToOrganizedFolder(File document) async {
    try {
      final extension = document.path.split('.').last.toLowerCase();
      final fileType = _getDocumentType(extension);
      
      final targetDir = await createOrganizedDocumentFolder(fileType);
      final fileName = document.path.split('/').last;
      final targetPath = '${targetDir.path}/$fileName';
      
      // בדיקה שהקובץ לא קיים כבר
      if (await File(targetPath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameWithoutExt = fileName.split('.').first;
        final newName = '${nameWithoutExt}_$timestamp.$extension';
        final newTargetPath = '${targetDir.path}/$newName';
        await document.copy(newTargetPath);
      } else {
        await document.copy(targetPath);
      }
      
      return true;
    } catch (e) {
      print('Error moving document: $e');
      return false;
    }
  }

  /// קבלת סוג המסמך לפי סיומת
  String _getDocumentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'PDFs';
      case 'doc':
      case 'docx':
        return 'Word Documents';
      case 'xls':
      case 'xlsx':
      case 'csv':
        return 'Spreadsheets';
      case 'ppt':
      case 'pptx':
        return 'Presentations';
      case 'txt':
      case 'rtf':
        return 'Text Files';
      case 'zip':
      case 'rar':
      case '7z':
        return 'Archives';
      default:
        return 'Other';
    }
  }

  /// מחיקת קבצים זמניים
  Future<void> cleanTemporaryFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }
    } catch (e) {
      print('Error cleaning temporary files: $e');
    }
  }

  /// מחיקת screenshots ישנים
  Future<int> cleanOldScreenshots({int daysOld = 30}) async {
    int deletedCount = 0;
    
    try {
      final images = await getAllImages();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      for (final image in images) {
        final file = await image.file;
        if (file != null && 
            file.path.toLowerCase().contains('screenshot') &&
            image.createDateTime.isBefore(cutoffDate)) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            print('Could not delete screenshot: $e');
          }
        }
      }
    } catch (e) {
      print('Error cleaning old screenshots: $e');
    }
    
    return deletedCount;
  }

  /// מחיקת קבצים ריקים
  Future<int> cleanEmptyFiles() async {
    int deletedCount = 0;
    
    try {
      final documents = await getAllDocuments();
      
      for (final doc in documents) {
        try {
          final size = await doc.length();
          if (size == 0) {
            await doc.delete();
            deletedCount++;
          }
        } catch (e) {
          print('Could not process file ${doc.path}: $e');
        }
      }
    } catch (e) {
      print('Error cleaning empty files: $e');
    }
    
    return deletedCount;
  }

  /// חישוב גודל תיקיה
  Future<int> calculateDirectorySize(Directory directory) async {
    int totalSize = 0;
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            print('Could not get size of ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    
    return totalSize;
  }

  /// יצירת גיבוי לפני סידור
  Future<Directory?> createBackupFolder() async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return null;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory('${externalDir.path}/Backups/backup_$timestamp');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      return backupDir;
    } catch (e) {
      print('Error creating backup folder: $e');
      return null;
    }
  }
}

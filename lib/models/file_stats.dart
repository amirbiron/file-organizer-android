class FileStats {
  final int totalImages;
  final int totalDocuments;
  final int duplicates;
  final double spaceSavedMB;
  final DateTime lastUpdated;

  FileStats({
    this.totalImages = 0,
    this.totalDocuments = 0,
    this.duplicates = 0,
    this.spaceSavedMB = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  FileStats copyWith({
    int? totalImages,
    int? totalDocuments,
    int? duplicates,
    double? spaceSavedMB,
    DateTime? lastUpdated,
  }) {
    return FileStats(
      totalImages: totalImages ?? this.totalImages,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      duplicates: duplicates ?? this.duplicates,
      spaceSavedMB: spaceSavedMB ?? this.spaceSavedMB,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalImages': totalImages,
      'totalDocuments': totalDocuments,
      'duplicates': duplicates,
      'spaceSavedMB': spaceSavedMB,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory FileStats.fromJson(Map<String, dynamic> json) {
    return FileStats(
      totalImages: json['totalImages'] as int,
      totalDocuments: json['totalDocuments'] as int,
      duplicates: json['duplicates'] as int,
      spaceSavedMB: json['spaceSavedMB'] as double,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

class OrganizeResult {
  final int processedFiles;
  final int duplicatesRemoved;
  final double spaceSaved;
  final DateTime timestamp;
  final String? description;

  OrganizeResult({
    required this.processedFiles,
    required this.duplicatesRemoved,
    required this.spaceSaved,
    required this.timestamp,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'processedFiles': processedFiles,
      'duplicatesRemoved': duplicatesRemoved,
      'spaceSaved': spaceSaved,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }

  factory OrganizeResult.fromJson(Map<String, dynamic> json) {
    return OrganizeResult(
      processedFiles: json['processedFiles'] as int,
      duplicatesRemoved: json['duplicatesRemoved'] as int,
      spaceSaved: json['spaceSaved'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
    );
  }
}

enum FileType {
  image,
  document,
  video,
  audio,
  archive,
  other,
}

extension FileTypeExtension on FileType {
  String get displayName {
    switch (this) {
      case FileType.image:
        return 'תמונות';
      case FileType.document:
        return 'מסמכים';
      case FileType.video:
        return 'סרטונים';
      case FileType.audio:
        return 'אודיו';
      case FileType.archive:
        return 'ארכיונים';
      case FileType.other:
        return 'אחר';
    }
  }

  List<String> get extensions {
    switch (this) {
      case FileType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
      case FileType.document:
        return ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'ppt', 'pptx'];
      case FileType.video:
        return ['mp4', 'avi', 'mov', 'mkv', 'webm'];
      case FileType.audio:
        return ['mp3', 'wav', 'flac', 'aac', 'm4a'];
      case FileType.archive:
        return ['zip', 'rar', '7z', 'tar', 'gz'];
      case FileType.other:
        return [];
    }
  }
}

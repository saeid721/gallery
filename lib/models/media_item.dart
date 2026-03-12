class MediaItem {
  final int?    id;
  final String? assetId;        // ← NEW: photo_manager asset ID
  final String  filename;
  final String  uri;
  final String  thumbnailUri;
  final int?    albumId;
  final int     dateAdded;
  final int     dateModified;
  final int     fileSize;
  final int     width;
  final int     height;
  final bool    isFavorite;
  final bool    isDeleted;
  final String  mediaType;      // 'image' | 'video'
  final int?    videoDuration;  // ← NEW: seconds (video only)
  final double? latitude;
  final double? longitude;
  final int?    deletedAt;      // timestamp — trash এর জন্য

  const MediaItem({
    this.id,
    this.assetId,               // ← NEW
    required this.filename,
    required this.uri,
    required this.thumbnailUri,
    this.albumId,
    required this.dateAdded,
    required this.dateModified,
    required this.fileSize,
    required this.width,
    required this.height,
    this.isFavorite    = false,
    this.isDeleted     = false,
    this.mediaType     = 'image',
    this.videoDuration,         // ← NEW
    this.latitude,
    this.longitude,
    this.deletedAt,
  });

  // ─── SQLite fromMap ──────────────────────────────────────
  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id:            map['id']             as int?,
      assetId:       map['asset_id']       as String?,   // ← NEW
      filename:      map['filename']       as String,
      uri:           map['uri']            as String,
      thumbnailUri:  map['thumbnail_uri']  as String,
      albumId:       map['album_id']       as int?,
      dateAdded:     map['date_added']     as int,
      dateModified:  map['date_modified']  as int,
      fileSize:      map['file_size']      as int,
      width:         map['width']          as int,
      height:        map['height']         as int,
      isFavorite:    (map['is_favorite']   as int) == 1,
      isDeleted:     (map['is_deleted']    as int) == 1,
      mediaType:     map['media_type']     as String,
      videoDuration: map['video_duration'] as int?,      // ← NEW
      latitude:      map['latitude']       as double?,
      longitude:     map['longitude']      as double?,
      deletedAt:     map['deleted_at']     as int?,
    );
  }

  // ─── SQLite toMap ────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      if (id      != null) 'id':             id,
      if (assetId != null) 'asset_id':       assetId,   // ← NEW
      'filename':       filename,
      'uri':            uri,
      'thumbnail_uri':  thumbnailUri,
      'album_id':       albumId,
      'date_added':     dateAdded,
      'date_modified':  dateModified,
      'file_size':      fileSize,
      'width':          width,
      'height':         height,
      'is_favorite':    isFavorite  ? 1 : 0,
      'is_deleted':     isDeleted   ? 1 : 0,
      'media_type':     mediaType,
      'video_duration': videoDuration,                   // ← NEW
      'latitude':       latitude,
      'longitude':      longitude,
      'deleted_at':     deletedAt,
    };
  }

  // ─── copyWith ────────────────────────────────────────────
  MediaItem copyWith({
    int?     id,
    String?  assetId,           // ← NEW
    String?  filename,
    String?  uri,
    String?  thumbnailUri,
    int?     albumId,
    int?     dateAdded,
    int?     dateModified,
    int?     fileSize,
    int?     width,
    int?     height,
    bool?    isFavorite,
    bool?    isDeleted,
    String?  mediaType,
    int?     videoDuration,     // ← NEW
    double?  latitude,
    double?  longitude,
    int?     deletedAt,
  }) {
    return MediaItem(
      id:            id            ?? this.id,
      assetId:       assetId       ?? this.assetId,      // ← NEW
      filename:      filename      ?? this.filename,
      uri:           uri           ?? this.uri,
      thumbnailUri:  thumbnailUri  ?? this.thumbnailUri,
      albumId:       albumId       ?? this.albumId,
      dateAdded:     dateAdded     ?? this.dateAdded,
      dateModified:  dateModified  ?? this.dateModified,
      fileSize:      fileSize      ?? this.fileSize,
      width:         width         ?? this.width,
      height:        height        ?? this.height,
      isFavorite:    isFavorite    ?? this.isFavorite,
      isDeleted:     isDeleted     ?? this.isDeleted,
      mediaType:     mediaType     ?? this.mediaType,
      videoDuration: videoDuration ?? this.videoDuration, // ← NEW
      latitude:      latitude      ?? this.latitude,
      longitude:     longitude     ?? this.longitude,
      deletedAt:     deletedAt     ?? this.deletedAt,
    );
  }

  // ─── Computed Properties ─────────────────────────────────

  // File size human-readable (1.2 MB)
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Resolution string (1920 × 1080)
  String get resolution => '$width × $height';

  // Has GPS data
  bool get hasLocation => latitude != null && longitude != null;

  // Is video
  bool get isVideo => mediaType == 'video';

  // ← NEW: formatted video duration e.g. "1:23"
  String get formattedDuration {
    if (videoDuration == null || videoDuration == 0) return '';
    final m = videoDuration! ~/ 60;
    final s = videoDuration! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // DateTime object
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(dateAdded);

  // Hero tag for animation — prefer assetId for stability
  String get heroTag => 'media_${assetId ?? id ?? filename}';

  // ─── Equality ────────────────────────────────────────────
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MediaItem &&
              runtimeType == other.runtimeType &&
              (assetId != null
                  ? assetId == other.assetId
                  : id == other.id);

  @override
  int get hashCode => (assetId ?? id).hashCode;

  @override
  String toString() =>
      'MediaItem(assetId: $assetId, id: $id, filename: $filename, albumId: $albumId)';
}
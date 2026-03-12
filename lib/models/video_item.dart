class VideoItem {
  final int?    id;
  final String  filename;
  final String  uri;
  final String  thumbnailUri;
  final int?    albumId;
  final int     dateAdded;
  final int     dateModified;
  final int     fileSize;
  final int     width;
  final int     height;
  final int     duration;        // milliseconds
  final bool    isFavorite;
  final bool    isDeleted;
  final double? latitude;
  final double? longitude;
  final int?    deletedAt;

  const VideoItem({
    this.id,
    required this.filename,
    required this.uri,
    required this.thumbnailUri,
    this.albumId,
    required this.dateAdded,
    required this.dateModified,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.duration,
    this.isFavorite  = false,
    this.isDeleted   = false,
    this.latitude,
    this.longitude,
    this.deletedAt,
  });

  // ─── SQLite fromMap ──────────────────────────────────────
  factory VideoItem.fromMap(Map<String, dynamic> map) {
    return VideoItem(
      id:           map['id'] as int?,
      filename:     map['filename'] as String,
      uri:          map['uri'] as String,
      thumbnailUri: map['thumbnail_uri'] as String,
      albumId:      map['album_id'] as int?,
      dateAdded:    map['date_added'] as int,
      dateModified: map['date_modified'] as int,
      fileSize:     map['file_size'] as int,
      width:        map['width'] as int,
      height:       map['height'] as int,
      duration:     map['duration'] as int,
      isFavorite:   (map['is_favorite'] as int) == 1,
      isDeleted:    (map['is_deleted'] as int) == 1,
      latitude:     map['latitude'] as double?,
      longitude:    map['longitude'] as double?,
      deletedAt:    map['deleted_at'] as int?,
    );
  }

  // ─── SQLite toMap ────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'filename':      filename,
      'uri':           uri,
      'thumbnail_uri': thumbnailUri,
      'album_id':      albumId,
      'date_added':    dateAdded,
      'date_modified': dateModified,
      'file_size':     fileSize,
      'width':         width,
      'height':        height,
      'duration':      duration,
      'is_favorite':   isFavorite ? 1 : 0,
      'is_deleted':    isDeleted  ? 1 : 0,
      'media_type':    'video',
      'latitude':      latitude,
      'longitude':     longitude,
      'deleted_at':    deletedAt,
    };
  }

  // ─── copyWith ────────────────────────────────────────────
  VideoItem copyWith({
    int?    id,
    String? filename,
    String? uri,
    String? thumbnailUri,
    int?    albumId,
    int?    dateAdded,
    int?    dateModified,
    int?    fileSize,
    int?    width,
    int?    height,
    int?    duration,
    bool?   isFavorite,
    bool?   isDeleted,
    double? latitude,
    double? longitude,
    int?    deletedAt,
  }) {
    return VideoItem(
      id:           id           ?? this.id,
      filename:     filename     ?? this.filename,
      uri:          uri          ?? this.uri,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      albumId:      albumId      ?? this.albumId,
      dateAdded:    dateAdded    ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      fileSize:     fileSize     ?? this.fileSize,
      width:        width        ?? this.width,
      height:       height       ?? this.height,
      duration:     duration     ?? this.duration,
      isFavorite:   isFavorite   ?? this.isFavorite,
      isDeleted:    isDeleted    ?? this.isDeleted,
      latitude:     latitude     ?? this.latitude,
      longitude:    longitude    ?? this.longitude,
      deletedAt:    deletedAt    ?? this.deletedAt,
    );
  }

  // ─── Computed ────────────────────────────────────────────
  String get formattedDuration {
    final ms  = Duration(milliseconds: duration);
    final h   = ms.inHours;
    final m   = ms.inMinutes.remainder(60);
    final s   = ms.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get resolution   => '$width × $height';
  bool   get hasLocation  => latitude != null && longitude != null;
  String get heroTag      => 'video_${id ?? filename}';
  DateTime get dateTime   =>
      DateTime.fromMillisecondsSinceEpoch(dateAdded);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VideoItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
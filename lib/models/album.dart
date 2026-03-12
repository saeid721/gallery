class Album {
  final int?   id;
  final String name;
  final String coverUri;
  final int    itemCount;
  final int    dateModified;
  final bool   isHidden;
  final String albumType;  // 'camera' | 'screenshot' | 'download' | 'custom'

  const Album({
    this.id,
    required this.name,
    required this.coverUri,
    this.itemCount    = 0,
    required this.dateModified,
    this.isHidden     = false,
    this.albumType    = 'custom',
  });

  // ─── SQLite fromMap ──────────────────────────────────────
  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id:           map['id'] as int?,
      name:         map['name'] as String,
      coverUri:     map['cover_uri'] as String,
      itemCount:    map['item_count'] as int,
      dateModified: map['date_modified'] as int,
      isHidden:     (map['is_hidden'] as int) == 1,
      albumType:    map['album_type'] as String,
    );
  }

  // ─── SQLite toMap ────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name':          name,
      'cover_uri':     coverUri,
      'item_count':    itemCount,
      'date_modified': dateModified,
      'is_hidden':     isHidden ? 1 : 0,
      'album_type':    albumType,
    };
  }

  // ─── copyWith ────────────────────────────────────────────
  Album copyWith({
    int?    id,
    String? name,
    String? coverUri,
    int?    itemCount,
    int?    dateModified,
    bool?   isHidden,
    String? albumType,
  }) {
    return Album(
      id:           id           ?? this.id,
      name:         name         ?? this.name,
      coverUri:     coverUri     ?? this.coverUri,
      itemCount:    itemCount    ?? this.itemCount,
      dateModified: dateModified ?? this.dateModified,
      isHidden:     isHidden     ?? this.isHidden,
      albumType:    albumType    ?? this.albumType,
    );
  }

  // ─── Computed Properties ─────────────────────────────────

  // Item count label (120 items)
  String get itemCountLabel =>
      itemCount == 1 ? '1 item' : '$itemCount items';

  // Album icon based on type
  String get typeIcon {
    switch (albumType) {
      case 'camera':     return 'camera';
      case 'screenshot': return 'screenshot';
      case 'download':   return 'download';
      default:           return 'folder';
    }
  }

  // DateTime object
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(dateModified);

  // ─── Equality ────────────────────────────────────────────
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Album &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Album(id: $id, name: $name, itemCount: $itemCount)';
}
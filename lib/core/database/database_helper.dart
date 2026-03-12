import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/media_item.dart';
import '../../models/album.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  // ─── DB Config ──────────────────────────────────────────
  static const _dbName    = 'gallery.db';
  static const _dbVersion = 1;

  // ─── Table Names ────────────────────────────────────────
  static const tMediaItems = 'media_items';
  static const tAlbums     = 'albums';

  // ─── Get Database ───────────────────────────────────────
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // ─────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version:  _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Foreign key support enable
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ─── Albums Table ──────────────────────────────────────
    await db.execute('''
      CREATE TABLE $tAlbums (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        cover_uri     TEXT    NOT NULL DEFAULT '',
        item_count    INTEGER NOT NULL DEFAULT 0,
        date_modified INTEGER NOT NULL,
        is_hidden     INTEGER NOT NULL DEFAULT 0,
        album_type    TEXT    NOT NULL DEFAULT 'custom'
      )
    ''');

    // ─── Media Items Table ─────────────────────────────────
    await db.execute('''
      CREATE TABLE $tMediaItems (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        filename      TEXT    NOT NULL,
        uri           TEXT    NOT NULL,
        thumbnail_uri TEXT    NOT NULL,
        album_id      INTEGER,
        date_added    INTEGER NOT NULL,
        date_modified INTEGER NOT NULL,
        file_size     INTEGER NOT NULL DEFAULT 0,
        width         INTEGER NOT NULL DEFAULT 0,
        height        INTEGER NOT NULL DEFAULT 0,
        is_favorite   INTEGER NOT NULL DEFAULT 0,
        is_deleted    INTEGER NOT NULL DEFAULT 0,
        media_type    TEXT    NOT NULL DEFAULT 'image',
        latitude      REAL,
        longitude     REAL,
        deleted_at    INTEGER,
        FOREIGN KEY (album_id) REFERENCES $tAlbums(id)
          ON DELETE SET NULL
      )
    ''');

    // ─── Indexes ───────────────────────────────────────────
    await db.execute('''
      CREATE INDEX idx_media_album_id
      ON $tMediaItems (album_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_media_date_added
      ON $tMediaItems (date_added DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_media_is_favorite
      ON $tMediaItems (is_favorite)
    ''');
    await db.execute('''
      CREATE INDEX idx_media_is_deleted
      ON $tMediaItems (is_deleted)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migration এখানে handle করা হবে
  }

  // ─────────────────────────────────────────────────────────
  // SAMPLE DATA
  // ─────────────────────────────────────────────────────────

  Future<void> insertSampleData() async {
    final db  = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // ─── Albums ────────────────────────────────────────────
    final albums = [
      Album(
        id:           1,
        name:         'Camera',
        coverUri:     'https://picsum.photos/seed/1/800/800',
        itemCount:    12,
        dateModified: now,
        albumType:    'camera',
      ),
      Album(
        id:           2,
        name:         'Screenshots',
        coverUri:     'https://picsum.photos/seed/13/800/800',
        itemCount:    8,
        dateModified: now - 86400000,
        albumType:    'screenshot',
      ),
      Album(
        id:           3,
        name:         'Downloads',
        coverUri:     'https://picsum.photos/seed/21/800/800',
        itemCount:    6,
        dateModified: now - 172800000,
        albumType:    'download',
      ),
      Album(
        id:           4,
        name:         'WhatsApp',
        coverUri:     'https://picsum.photos/seed/27/800/800',
        itemCount:    4,
        dateModified: now - 259200000,
        albumType:    'custom',
      ),
    ];

    final batch = db.batch();
    for (final album in albums) {
      batch.insert(tAlbums, album.toMap());
    }
    await batch.commit(noResult: true);

    // ─── Media Items ───────────────────────────────────────
    // Album 1 → Camera     : seed 1–12
    // Album 2 → Screenshots: seed 13–20
    // Album 3 → Downloads  : seed 21–26
    // Album 4 → WhatsApp   : seed 27–30

    final albumRanges = {
      1: List.generate(12, (i) => i + 1),
      2: List.generate(8,  (i) => i + 13),
      3: List.generate(6,  (i) => i + 21),
      4: List.generate(4,  (i) => i + 27),
    };

    final mediaBatch = db.batch();

    albumRanges.forEach((albumId, seeds) {
      for (int i = 0; i < seeds.length; i++) {
        final seed   = seeds[i];
        final offset = i * 3600000; // 1 hour apart

        mediaBatch.insert(tMediaItems, MediaItem(
          filename:     'IMG_$seed.jpg',
          uri:          'https://picsum.photos/seed/$seed/1200/800',
          thumbnailUri: 'https://picsum.photos/seed/$seed/400/400',
          albumId:      albumId,
          dateAdded:    now - offset,
          dateModified: now - offset,
          fileSize:     (500000 + seed * 12345),  // ~0.5–1MB
          width:        1200,
          height:       800,
          isFavorite:   seed % 5 == 0,            // every 5th is favorite
          mediaType:    'image',
          latitude:     seed % 3 == 0 ? 23.8103 + (seed * 0.01) : null,
          longitude:    seed % 3 == 0 ? 90.4125 + (seed * 0.01) : null,
        ).toMap());
      }
    });

    await mediaBatch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────────────────
  // MEDIA ITEMS — READ
  // ─────────────────────────────────────────────────────────

  // SELECT * FROM media_items WHERE is_deleted = 0
  // ORDER BY {sortBy} {sortOrder}
  Future<List<MediaItem>> getAllMedia({
    String sortBy    = 'date_added',
    String sortOrder = 'DESC',
  }) async {
    final db   = await database;
    final maps = await db.query(
      tMediaItems,
      where:   'is_deleted = ?',
      whereArgs: [0],
      orderBy: '$sortBy $sortOrder',
    );
    return maps.map(MediaItem.fromMap).toList();
  }

  // SELECT * FROM media_items WHERE album_id = ? AND is_deleted = 0
  Future<List<MediaItem>> getMediaByAlbum(
      int albumId, {
        String sortBy    = 'date_added',
        String sortOrder = 'DESC',
      }) async {
    final db   = await database;
    final maps = await db.query(
      tMediaItems,
      where:     'album_id = ? AND is_deleted = ?',
      whereArgs: [albumId, 0],
      orderBy:   '$sortBy $sortOrder',
    );
    return maps.map(MediaItem.fromMap).toList();
  }

  // SELECT * FROM media_items WHERE is_favorite = 1 AND is_deleted = 0
  Future<List<MediaItem>> getFavorites() async {
    final db   = await database;
    final maps = await db.query(
      tMediaItems,
      where:     'is_favorite = ? AND is_deleted = ?',
      whereArgs: [1, 0],
      orderBy:   'date_added DESC',
    );
    return maps.map(MediaItem.fromMap).toList();
  }

  // SELECT * FROM media_items WHERE filename LIKE ? AND is_deleted = 0
  Future<List<MediaItem>> searchMedia(String query) async {
    if (query.trim().isEmpty) return getAllMedia();
    final db   = await database;
    final maps = await db.query(
      tMediaItems,
      where:     'filename LIKE ? AND is_deleted = ?',
      whereArgs: ['%$query%', 0],
      orderBy:   'date_added DESC',
    );
    return maps.map(MediaItem.fromMap).toList();
  }

  // SELECT * FROM media_items WHERE is_deleted = 1
  Future<List<MediaItem>> getTrash() async {
    final db   = await database;
    final maps = await db.query(
      tMediaItems,
      where:     'is_deleted = ?',
      whereArgs: [1],
      orderBy:   'deleted_at DESC',
    );
    return maps.map(MediaItem.fromMap).toList();
  }

  // SELECT * FROM media_items WHERE id = ?
  Future<MediaItem?> getMediaById(int id) async {
    final db   = await database;
    final maps = await db.query(
      tMediaItems,
      where:     'id = ?',
      whereArgs: [id],
      limit:     1,
    );
    if (maps.isEmpty) return null;
    return MediaItem.fromMap(maps.first);
  }

  // ─────────────────────────────────────────────────────────
  // MEDIA ITEMS — WRITE
  // ─────────────────────────────────────────────────────────

  // INSERT INTO media_items
  Future<int> insertMedia(MediaItem item) async {
    final db = await database;
    final id = await db.insert(
      tMediaItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Update album cover + count
    if (item.albumId != null) {
      await _updateAlbumMeta(item.albumId!);
    }
    return id;
  }

  // UPDATE media_items SET is_favorite = ? WHERE id = ?
  Future<void> toggleFavorite(int id) async {
    final db   = await database;
    final item = await getMediaById(id);
    if (item == null) return;

    await db.update(
      tMediaItems,
      {'is_favorite': item.isFavorite ? 0 : 1},
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  // UPDATE media_items SET is_favorite = 1 WHERE id IN (...)
  Future<void> favoriteMultiple(List<int> ids) async {
    if (ids.isEmpty) return;
    final db    = await database;
    final marks = List.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE $tMediaItems SET is_favorite = 1 WHERE id IN ($marks)',
      ids,
    );
  }

  // Soft delete — UPDATE media_items SET is_deleted = 1
  Future<void> moveToTrash(List<int> ids) async {
    if (ids.isEmpty) return;
    final db    = await database;
    final now   = DateTime.now().millisecondsSinceEpoch;
    final marks = List.filled(ids.length, '?').join(', ');

    await db.rawUpdate(
      '''UPDATE $tMediaItems
         SET is_deleted = 1, deleted_at = ?
         WHERE id IN ($marks)''',
      [now, ...ids],
    );

    // Update affected album counts
    final maps = await db.query(
      tMediaItems,
      columns:   ['album_id'],
      where:     'id IN ($marks)',
      whereArgs: ids,
    );
    final albumIds = maps
        .map((m) => m['album_id'] as int?)
        .whereType<int>()
        .toSet();
    for (final albumId in albumIds) {
      await _updateAlbumMeta(albumId);
    }
  }

  // Restore from trash
  Future<void> restoreFromTrash(List<int> ids) async {
    if (ids.isEmpty) return;
    final db    = await database;
    final marks = List.filled(ids.length, '?').join(', ');

    await db.rawUpdate(
      '''UPDATE $tMediaItems
         SET is_deleted = 0, deleted_at = NULL
         WHERE id IN ($marks)''',
      ids,
    );
  }

  // Hard delete — DELETE FROM media_items
  Future<void> deletePermanently(List<int> ids) async {
    if (ids.isEmpty) return;
    final db    = await database;
    final marks = List.filled(ids.length, '?').join(', ');
    await db.rawDelete(
      'DELETE FROM $tMediaItems WHERE id IN ($marks)',
      ids,
    );
  }

  // Empty trash — DELETE all is_deleted = 1
  Future<void> emptyTrash() async {
    final db = await database;
    await db.delete(
      tMediaItems,
      where:     'is_deleted = ?',
      whereArgs: [1],
    );
  }

  // ─────────────────────────────────────────────────────────
  // ALBUMS — READ
  // ─────────────────────────────────────────────────────────

  // SELECT * FROM albums ORDER BY date_modified DESC
  Future<List<Album>> getAllAlbums({bool includeHidden = false}) async {
    final db = await database;

    final maps = await db.query(
      tAlbums,
      where:     includeHidden ? null : 'is_hidden = ?',
      whereArgs: includeHidden ? null : [0],
      orderBy:   'date_modified DESC',
    );
    return maps.map(Album.fromMap).toList();
  }

  // SELECT * FROM albums WHERE id = ?
  Future<Album?> getAlbumById(int id) async {
    final db   = await database;
    final maps = await db.query(
      tAlbums,
      where:     'id = ?',
      whereArgs: [id],
      limit:     1,
    );
    if (maps.isEmpty) return null;
    return Album.fromMap(maps.first);
  }

  // ─────────────────────────────────────────────────────────
  // ALBUMS — WRITE
  // ─────────────────────────────────────────────────────────

  // INSERT INTO albums
  Future<int> insertAlbum(Album album) async {
    final db = await database;
    return await db.insert(
      tAlbums,
      album.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UPDATE albums SET name = ? WHERE id = ?
  Future<void> renameAlbum(int id, String newName) async {
    final db = await database;
    await db.update(
      tAlbums,
      {'name': newName},
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  // UPDATE albums SET is_hidden = ? WHERE id = ?
  Future<void> toggleAlbumVisibility(int id) async {
    final db    = await database;
    final album = await getAlbumById(id);
    if (album == null) return;
    await db.update(
      tAlbums,
      {'is_hidden': album.isHidden ? 0 : 1},
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE FROM albums WHERE id = ?
  Future<void> deleteAlbum(int id) async {
    final db = await database;
    // Media items → album_id SET NULL (ON DELETE SET NULL)
    await db.delete(
      tAlbums,
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────────────────
  // STATS
  // ─────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tMediaItems WHERE is_deleted = 0',
    );
    final favResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tMediaItems WHERE is_favorite = 1 AND is_deleted = 0',
    );
    final trashResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tMediaItems WHERE is_deleted = 1',
    );
    final albumResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tAlbums',
    );

    return {
      'total_media':  totalResult.first['count']  as int,
      'total_favorites': favResult.first['count'] as int,
      'total_trash':  trashResult.first['count']  as int,
      'total_albums': albumResult.first['count']  as int,
    };
  }

  // ─────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────

  // Album এর cover_uri ও item_count আপডেট করে
  Future<void> _updateAlbumMeta(int albumId) async {
    final db = await database;

    // Count active items
    final countResult = await db.rawQuery(
      '''SELECT COUNT(*) as count FROM $tMediaItems
         WHERE album_id = ? AND is_deleted = 0''',
      [albumId],
    );
    final count = countResult.first['count'] as int;

    // Latest item as cover
    final coverResult = await db.query(
      tMediaItems,
      columns:   ['thumbnail_uri'],
      where:     'album_id = ? AND is_deleted = ?',
      whereArgs: [albumId, 0],
      orderBy:   'date_added DESC',
      limit:     1,
    );
    final coverUri = coverResult.isNotEmpty
        ? coverResult.first['thumbnail_uri'] as String
        : '';

    await db.update(
      tAlbums,
      {
        'item_count':    count,
        'cover_uri':     coverUri,
        'date_modified': DateTime.now().millisecondsSinceEpoch,
      },
      where:     'id = ?',
      whereArgs: [albumId],
    );
  }

  // ─────────────────────────────────────────────────────────
  // CLOSE
  // ─────────────────────────────────────────────────────────

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
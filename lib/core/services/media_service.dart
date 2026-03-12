import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/media_item.dart';

class MediaService extends GetxService {

  // ─── Permission state ────────────────────────────────────
  final permissionState = Rx<PermissionState>(PermissionState.notDetermined);
  final hasPermission   = false.obs;

  // ─── In-memory thumbnail cache  id → bytes ───────────────
  final _thumbCache = <String, Uint8List>{};

  // ─── Config ──────────────────────────────────────────────
  static const _thumbSize    = ThumbnailSize(200, 200);
  static const _thumbQuality = 85;
  static const _pageSize     = 80;

  // ─────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────

  Future<MediaService> init() async {
    await requestPermission();
    return this;
  }

  // ─────────────────────────────────────────────────────────
  // PERMISSION
  // ─────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    permissionState.value = result;
    hasPermission.value   = result.isAuth || result == PermissionState.limited;
    return hasPermission.value;
  }

  void openSettings() => PhotoManager.openSetting();

  // ─────────────────────────────────────────────────────────
  // LOAD ALL MEDIA  (paginated)
  // ─────────────────────────────────────────────────────────

  Future<List<MediaItem>> loadPage({
    int         page      = 0,
    String      sortBy    = 'date_added',
    String      sortOrder = 'DESC',
    RequestType type      = RequestType.common,
  }) async {
    if (!hasPermission.value) return [];

    final albums = await PhotoManager.getAssetPathList(
      type:         type,
      hasAll:       true,
      onlyAll:      true,
      filterOption: _buildFilter(sortBy, sortOrder),
    );

    if (albums.isEmpty) return [];

    final assets = await albums.first.getAssetListPaged(
      page: page,
      size: _pageSize,
    );

    return Future.wait(assets.map(_assetToMediaItem));
  }

  Future<int> getTotalCount({RequestType type = RequestType.common}) async {
    if (!hasPermission.value) return 0;
    final albums = await PhotoManager.getAssetPathList(
      type:    type,
      hasAll:  true,
      onlyAll: true,
    );
    if (albums.isEmpty) return 0;
    return albums.first.assetCountAsync;
  }

  // ─────────────────────────────────────────────────────────
  // LOAD ALBUMS
  // ─────────────────────────────────────────────────────────

  Future<List<DeviceAlbum>> loadAlbums() async {
    if (!hasPermission.value) return [];

    final paths = await PhotoManager.getAssetPathList(
      type:   RequestType.common,
      hasAll: true,
    );

    final result = <DeviceAlbum>[];
    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (count == 0) continue;

      final assets = await path.getAssetListPaged(page: 0, size: 1);
      Uint8List? cover;
      if (assets.isNotEmpty) {
        cover = await _getThumb(assets.first);
      }

      result.add(DeviceAlbum(
        id:        path.id,
        name:      path.name,
        count:     count,
        coverData: cover,
        isAll:     path.isAll,
      ));
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────
  // LOAD BY ALBUM
  // ─────────────────────────────────────────────────────────

  Future<List<MediaItem>> loadByAlbum(String albumId, {int page = 0}) async {
    if (!hasPermission.value) return [];

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );
    final path = paths.firstWhereOrNull((p) => p.id == albumId);
    if (path == null) return [];

    final assets = await path.getAssetListPaged(page: page, size: _pageSize);
    return Future.wait(assets.map(_assetToMediaItem));
  }

  // ─────────────────────────────────────────────────────────
  // FAVORITES
  // ─────────────────────────────────────────────────────────

  Future<List<MediaItem>> loadFavorites({int page = 0}) async {
    if (!hasPermission.value) return [];

    final paths = await PhotoManager.getAssetPathList(
      type:   RequestType.common,
      hasAll: true,
    );

    final allPath = paths.firstWhereOrNull((p) => p.isAll);
    if (allPath == null) return [];

    final total  = await allPath.assetCountAsync;
    final pages  = (total / _pageSize).ceil();
    final result = <MediaItem>[];

    for (int p = 0; p < pages; p++) {
      final assets = await allPath.getAssetListPaged(page: p, size: _pageSize);
      for (final a in assets) {
        if (a.isFavorite) {
          result.add(await _assetToMediaItem(a));
        }
      }
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────
  // THUMBNAIL  (cached)
  // ─────────────────────────────────────────────────────────

  Future<Uint8List?> getThumbnail(String assetId) async {
    if (_thumbCache.containsKey(assetId)) return _thumbCache[assetId];

    final entity = await AssetEntity.fromId(assetId);
    if (entity == null) return null;

    final bytes = await _getThumb(entity);
    if (bytes != null) _thumbCache[assetId] = bytes;
    return bytes;
  }

  Future<Uint8List?> _getThumb(AssetEntity entity) {
    return entity.thumbnailDataWithSize(
      _thumbSize,
      quality: _thumbQuality,
      format:  ThumbnailFormat.jpeg,
    );
  }

  void clearThumbCache() => _thumbCache.clear();

  // ─────────────────────────────────────────────────────────
  // FULL IMAGE
  // ─────────────────────────────────────────────────────────

  Future<Uint8List?> getFullImage(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    return entity?.originBytes;
  }

  // ─────────────────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────────────────

  Future<List<MediaItem>> search(String query, {int page = 0}) async {
    if (!hasPermission.value || query.trim().isEmpty) return [];

    final allItems = await loadPage(page: page);
    final q        = query.toLowerCase();
    return allItems
        .where((m) => m.filename.toLowerCase().contains(q))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // ASSET → MediaItem CONVERSION
  // ─────────────────────────────────────────────────────────

  Future<MediaItem> _assetToMediaItem(AssetEntity asset) async {
    final latLng = await asset.latlngAsync();

    return MediaItem(
      id:            null,
      assetId:       asset.id,
      filename:      asset.title ?? 'IMG_${asset.id.substring(0, 8)}.jpg',
      uri:           asset.id,
      thumbnailUri:  asset.id,
      albumId:       null,
      dateAdded:     asset.createDateTime.millisecondsSinceEpoch,
      dateModified:  asset.modifiedDateTime?.millisecondsSinceEpoch
          ?? asset.createDateTime.millisecondsSinceEpoch,
      fileSize:      0,
      width:         asset.width,
      height:        asset.height,
      isFavorite:    asset.isFavorite,
      isDeleted:     false,
      mediaType:     asset.type == AssetType.video ? 'video' : 'image',
      videoDuration: asset.type == AssetType.video
          ? asset.videoDuration.inSeconds
          : null,
      latitude:      (latLng?.latitude  != 0) ? latLng?.latitude  : null,
      longitude:     (latLng?.longitude != 0) ? latLng?.longitude : null,
      deletedAt:     null,
    );
  }

  // ─────────────────────────────────────────────────────────
  // FILTER OPTIONS BUILDER
  // ─────────────────────────────────────────────────────────

  FilterOptionGroup _buildFilter(String sortBy, String sortOrder) {
    final asc = sortOrder.toUpperCase() == 'ASC';

    // OrderOptionType only has: createDate, updateDate
    // There is NO "title" value — filename sort is not supported natively
    final OrderOption order;
    switch (sortBy) {
      case 'date_modified':
        order = OrderOption(type: OrderOptionType.updateDate, asc: asc);
        break;
      case 'date_added':
      default:
      // 'filename' also falls here — photo_manager has no title sort,
      // so we fall back to createDate for any unsupported sortBy value
        order = OrderOption(type: OrderOptionType.createDate, asc: asc);
        break;
    }

    return FilterOptionGroup(
      imageOption: const FilterOption(
        needTitle:      true,
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      videoOption: const FilterOption(
        needTitle:      true,
        sizeConstraint: SizeConstraint(ignoreSize: true),
        durationConstraint: DurationConstraint(
          min: Duration(seconds: 1),
          max: Duration(hours: 4),
        ),
      ),
      orders: [order],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DEVICE ALBUM
// ─────────────────────────────────────────────────────────────

class DeviceAlbum {
  final String     id;
  final String     name;
  final int        count;
  final Uint8List? coverData;
  final bool       isAll;

  const DeviceAlbum({
    required this.id,
    required this.name,
    required this.count,
    this.coverData,
    this.isAll = false,
  });
}
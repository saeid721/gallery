abstract class Routes {
  Routes._();
  static const home          = _Paths.home;
  static const albums        = _Paths.albums;
  static const albumDetail   = _Paths.albumDetail;
  static const photoViewer   = _Paths.photoViewer;
  static const favorites     = _Paths.favorites;
  static const search        = _Paths.search;
  static const settings      = _Paths.settings;
  static const stories       = _Paths.stories;
  static const video         = _Paths.video;
  static const trash         = _Paths.trash;
  static const slideshow     = _Paths.slideshow;
}

abstract class _Paths {
  static const home          = '/home';
  static const albums        = '/albums';
  static const albumDetail   = '/album-detail';
  static const photoViewer   = '/photo-viewer';
  static const favorites     = '/favorites';
  static const search        = '/search';
  static const settings      = '/settings';
  static const stories       = '/stories';
  static const video         = '/video';
  static const trash         = '/trash';
  static const slideshow     = '/slideshow';
}
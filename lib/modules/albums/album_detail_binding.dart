import 'package:get/get.dart';
import 'album_detail_controller.dart';

class AlbumDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AlbumDetailController>(
          () => AlbumDetailController(),
    );
  }
}
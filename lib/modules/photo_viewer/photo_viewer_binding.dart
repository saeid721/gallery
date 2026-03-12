import 'package:get/get.dart';
import 'photo_viewer_controller.dart';

class PhotoViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PhotoViewerController>(
          () => PhotoViewerController(),
    );
  }
}
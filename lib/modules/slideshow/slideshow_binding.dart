import 'package:get/get.dart';
import 'slideshow_controller.dart';

class SlideshowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SlideshowController>(
          () => SlideshowController(),
    );
  }
}
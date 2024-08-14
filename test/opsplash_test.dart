import 'dart:io';

import 'package:opsplash_flutter/opsplash.dart';

void main() {
  var file = File("splash.img");
  if (file.existsSync()) {
    var data = file.readAsBytesSync();

    var splashImage = SplashImage(data: data);
    
    var imgdata = splashImage.getImageDataByName('boot');

    print(imgdata?.buffer.asUint8List(0, 2));
  }

}
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

Future<Uint8List> convertToBMP(img.Image imgimg) async {
  int headerSize = 54;
  int pixelDataOffset = headerSize;
  int fileSize = pixelDataOffset + (imgimg.width * imgimg.height * 3);

  ByteData byteData = ByteData(fileSize);

  // BMP 文件头 (14 字节)
  byteData.setUint8(0, 0x42); // 'B'
  byteData.setUint8(1, 0x4D); // 'M'
  byteData.setUint32(2, fileSize, Endian.little); // 文件大小
  byteData.setUint32(6, 0); // 保留
  byteData.setUint32(10, pixelDataOffset, Endian.little); // 数据偏移量

  // DIB 信息头 (40 字节)
  byteData.setUint32(14, 40, Endian.little); // 信息头大小
  byteData.setUint32(18, imgimg.width, Endian.little); // 宽度
  byteData.setUint32(22, imgimg.height, Endian.little); // 高度
  byteData.setUint16(26, 1, Endian.little); // 平面数
  byteData.setUint16(28, 24, Endian.little); // 位深度（24位，没有Alpha通道）
  byteData.setUint32(30, 0, Endian.little); // 压缩方式（无压缩）
  byteData.setUint32(34, fileSize - headerSize, Endian.little); // 图像数据大小
  byteData.setUint32(38, 2835, Endian.little); // 水平分辨率 (72 DPI)
  byteData.setUint32(42, 2835, Endian.little); // 垂直分辨率 (72 DPI)
  byteData.setUint32(46, 0, Endian.little); // 调色板颜色数
  byteData.setUint32(50, 0, Endian.little); // 重要颜色数

  // 像素数据
  int offset = pixelDataOffset;
  img.Pixel pixel;
  for (int y = imgimg.height - 1; y >= 0; y--) {
    for (int x = 0; x < imgimg.width; x++) {
      pixel = imgimg.getPixel(x, y);
      byteData.setUint8(offset++, pixel.getChannel(img.Channel.blue).toInt());  // Blue
      byteData.setUint8(offset++, pixel.getChannel(img.Channel.green).toInt()); // Green
      byteData.setUint8(offset++, pixel.getChannel(img.Channel.red).toInt());  // Red
    }
  }

  return byteData.buffer.asUint8List();
}


void main() async {
  var imgimg = await img.decodeImageFile("assets/splash.png");

  if (imgimg != null) {
    var data = await convertToBMP(imgimg);

    File("assets/splash.bmp").writeAsBytesSync(data);
  }
}
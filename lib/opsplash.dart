import 'dart:convert';
import 'dart:developer';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

final oppoSplashMagic = utf8.encode("SPLASH LOGO!");
const ddphHeaderOffset = 0x0;
const splashHeaderOffset = 0x4000;
const dataOffset = 0x8000;
const metadataOffset = splashHeaderOffset + 12;
const dataInfoOffset = splashHeaderOffset + 0x120;

var bmpencoder = img.BmpEncoder();

class DataInfo {
  DataInfo({
    required this.offset,
    required this.realsz,
    required this.compsz,
    required this.name,
  });
  int offset;
  int realsz;
  int compsz;
  Uint8List name;

  Uint8List getRaw() {
    var rawData = ByteData(0x80);

    rawData.setUint32(0, offset, Endian.little);
    rawData.setUint32(4, realsz, Endian.little);
    rawData.setUint32(8, compsz, Endian.little);
    rawData.buffer.asUint8List().setRange(12, 12 + name.length, name);

    return rawData.buffer.asUint8List();
  }
}

class SplashImage {
  SplashImage({required this.data}) {
    bool matchMagic(Uint8List magic, Uint8List comp) {
      var length = (magic.length > comp.length) ? comp.length : magic.length;
      for (int i= 0; i< length; i++) {
        if (magic[i] != comp[i]) return false;
      }
      return true;
    }

    if (data.length < dataOffset) {
      throw Exception("This file seems too small.");
    }

    var ddphData = ByteData.sublistView(data, ddphHeaderOffset, 8);
    ddphMagic = ddphData.getUint32(0, Endian.little);
    ddphFlag = ddphData.getUint32(4, Endian.little);

    var splashData = ByteData.sublistView(data, splashHeaderOffset, splashHeaderOffset + 0x120);
    splashMagic = data.sublist(splashHeaderOffset, metadataOffset);
    if (!matchMagic(splashMagic!, oppoSplashMagic)) {
      throw Exception(
          "Splash image magic not vaild, this may not a valid oppo splash image!");
    }

    metadata = [
      data.sublist(metadataOffset, metadataOffset + 0x40),
      data.sublist(metadataOffset + 0x40, metadataOffset + (0x40 * 2)),
      data.sublist(metadataOffset + (0x40 * 2), metadataOffset + (0x40 * 3)),
      data.sublist(metadataOffset + (0x40 * 3), metadataOffset + (0x40 * 4))
    ];

    imgNumber = splashData.getUint32(12 + (0x40 * 4), Endian.little);
    version = splashData.getUint32(12 + (0x40 * 4) + 4, Endian.little);
    width = splashData.getUint32(12 + (0x40 * 4) + 8, Endian.little);
    height = splashData.getUint32(12 + (0x40 * 4) + 12, Endian.little);
    special = splashData.getUint32(12 + (0x40 * 4) + 16, Endian.little);

    // Parse data info list
    var dataInfoData =
        ByteData.sublistView(data, dataInfoOffset, dataInfoOffset + (0x80 * imgNumber!));
    dataInfo = <DataInfo>[];
    for (var i = 0; i < imgNumber!; i++) {
      var name = Uint8List.sublistView(data, dataInfoOffset + (0x80 * i) + 12, dataInfoOffset + (0x80 * i) + 0x80);
      dataInfo?.add(DataInfo(
          offset: dataInfoData.getUint32((0x80 * i), Endian.little),
          realsz: dataInfoData.getUint32((0x80 * i) + 4, Endian.little),
          compsz: dataInfoData.getUint32((0x80 * i) + 8, Endian.little),
          name: name
      ));
    }

    compData = <Uint8List>[];
    for (int i=0; i<imgNumber!; i++) {
      compData!.add(getCompDataByIndex(i)!);
    }
  }

  Uint8List data;

  int? ddphMagic;
  int? ddphFlag;

  Uint8List? splashMagic;
  List<Uint8List>? metadata; // 4 x 0x40
  int? imgNumber;
  int? version;
  int? width;
  int? height;
  int? special;

  List<DataInfo>? dataInfo;

  List<Uint8List>? compData;

  Uint8List? getImageDataByIndex(int index) {
    if (index >= imgNumber!) {
      return null;
    }

    var decoder = GZipDecoder();

    if (compData != null) {
      var raw = decoder.decodeBytes(compData![index]);

      return Uint8List.fromList(raw);
    }
    return null;
  }

Future<Uint8List?> getImageDataByIndexAsync(int index) async {
  if (index >= imgNumber!) return null;

  // 使用 compute 函数将解压操作移到后台
  return await compute(decodeGZip, compData![index]);
}

// 解压缩操作移到独立的函数中
Uint8List decodeGZip(Uint8List compressedData) {
  var decoder = GZipDecoder();
  return Uint8List.fromList(decoder.decodeBytes(compressedData));
}

  Uint8List? getCompDataByIndex(int index) {
    if (index >= imgNumber!) {
      return null;
    }

    var dinfo = dataInfo?[index];
    if (dinfo != null) {
      return data.buffer.asUint8List(dinfo.offset + dataOffset, dinfo.compsz);
    }
    return null;
  }
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

  Future<bool> setImageCompressedDataByIndex(Uint8List? fileData, int index) async {
    if (fileData == null) return false;
    if (index >= imgNumber! || index < 0) return false;

    // convert image to bmp
    var imgimg = img.decodeImage(fileData);
    if (imgimg != null) {
      var bmpdata = await convertToBMP(imgimg);

      // compress with gzip
      var encoder = GZipEncoder();

      var compdata = Uint8List.fromList(encoder.encode(bmpdata)!);
      // clear timestamp
      compdata[4] = 0;
      compdata[5] = 0;
      compdata[6] = 0;
      compdata[7] = 0;

      compData?[index] = compdata;

      // update datainfo
      var dinfo = dataInfo?[index];
      if (dinfo != null) {
        dinfo.realsz = bmpdata.length;
        dinfo.compsz = compdata.length;
      }
      return true;
    }

    return false;
  }

  Uint8List? generateNewSplashImage() {
    if (splashMagic == null) return null;
    if (dataInfo == null) return null;
    if (compData == null) return null;

    log("Starting generate new splash image");
    // update datainfo
    log("Updating datainfo offset");
    int offset = 0;
    for (int i=0; i< imgNumber!; i++) {
      dataInfo?[i].offset = offset;
      offset += compData![i].length;
    }

    int totalSize = dataOffset + offset;
    var buffer = ByteData(totalSize);

    if (ddphMagic == 1213219908) { // 'DDPH'
      log("Generate ddph header");
      buffer.setUint32(0, ddphMagic!, Endian.little);
      buffer.setUint32(4, ddphFlag!, Endian.little);
    }

      log("Generated splash header");
      buffer.buffer.asUint8List().setRange(splashHeaderOffset, splashHeaderOffset + 12, splashMagic!);
      for (int i=0; i<4; i++) {
        buffer.buffer.asUint8List().setRange(metadataOffset + (i * 0x40), metadataOffset + (i * 0x40) + 0x40 , metadata![i]);
      }

      buffer.setUint32(metadataOffset + (4 * 0x40), imgNumber!, Endian.little);
      buffer.setUint32(metadataOffset + (4 * 0x40) + 4, version!, Endian.little);
      buffer.setUint32(metadataOffset + (4 * 0x40) + 8, width!, Endian.little);
      buffer.setUint32(metadataOffset + (4 * 0x40) + 12, height!, Endian.little);
      buffer.setUint32(metadataOffset + (4 * 0x40) + 16, special!, Endian.little);

      // Generate datainfo
      log("Generate datainfo");
      for (int i=0; i< imgNumber!; i++) {
        buffer.buffer.asUint8List().setRange(dataInfoOffset + (i * 0x80), dataInfoOffset + (i * 0x80) + 0x80, dataInfo![i].getRaw());
      }

      // Copy compdata
      log("Copying compressed data");
      offset = dataOffset;
      for (int i=0; i< imgNumber!; i++) {
        buffer.buffer.asUint8List().setRange(offset, offset + compData![i].length, compData![i]);
        offset += compData![i].length;
      }

      log("Generate looks success");
      return buffer.buffer.asUint8List();
  }
}

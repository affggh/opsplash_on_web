import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

final splashMagic = utf8.encode("SPLASH LOGO!");
const ddphHeaderOffset = 0x0;
const splashHeaderOffset = 0x4000;
const dataOffset = 0x8000;
const metadataOffset = splashHeaderOffset + 12;
const dataInfoOffset = splashHeaderOffset + 0x120;

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
    if (data.length < dataOffset) {
      throw Exception("This file seems too small.");
    }

    var ddphData = ByteData.sublistView(data, ddphHeaderOffset, 8);
    ddphMagic = ddphData.getUint32(0, Endian.little);
    ddphFlag = ddphData.getUint32(4, Endian.little);

    var splashData = ByteData.sublistView(data, splashHeaderOffset, splashHeaderOffset + 0x120);
    splashMagic = data.sublist(splashHeaderOffset, metadataOffset);
    if (splashMagic != splashMagic) {
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

  Uint8List? getImageDataByName(String name) {
    String decode(Uint8List data) {
      return utf8.decode(data.where((byte) => byte != 0).toList());
    }

    var decoder = GZipDecoder();

    DataInfo? dinfo;
    for (int i=0; i< imgNumber!; i++) {
      if (decode(dataInfo![i].name) == name) {
        dinfo = dataInfo?[i];
      }
    }

    if (dinfo != null) {
      var raw = decoder.decodeBytes(data.buffer.asUint8List(dinfo.offset + dataOffset, dinfo.compsz));

      return Uint8List.fromList(raw);
    }
    return null;
  }

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
}

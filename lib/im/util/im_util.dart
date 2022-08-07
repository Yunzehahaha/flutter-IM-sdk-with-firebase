import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class IMUtil {
  static int parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    if (value is int) return value;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static Future<String?> makeBase64(String path) async {
    try {
      if (path == null) return null;
      File file = File(path);
      var contents = await file.readAsBytes();
      var base64File = base64.encode(contents);

      return base64File;
    } catch (e) {
      print(e.toString());

      return null;
    }
  }

  static bool isCollectionEmpty(Iterable it) {
    return it == null || it.length == 0;
  }

  static bool isStringEmpty(String str) {
    return str == null || str.length == 0;
  }

  static Future<String> fmd5AndBase64(String filePath) async {
    File file = File(filePath);
    if (await file.exists()) {
      return base64
          .encode(md5.convert(file.readAsBytesSync()).bytes)
          .toString();
    }
    return "";
  }

  static bool isHttpUrl(String s) {
    if (isStringEmpty(s)) {
      return false;
    }

    return s.startsWith(RegExp(r'http(s?):\/\/'));
  }

  static int getPlatform() {
    if (Platform.isAndroid) {
      return 1;
    } else if (Platform.isIOS) {
      return 2;
    } else if (Platform.isWindows) {
      return 4;
    } else if (Platform.isMacOS) {
      return 5;
    }
    return 0;
  }

  static dynamic parseExtra(Object extra) {
    if (extra is Map) return extra;

    if (extra == null ||
        !(extra is String) ||
        extra == '[]' ||
        (extra is String && extra.isEmpty)) {
      return {};
    }
    try {
      return json.decode(extra);
    } catch (e) {
      print(e);
      return {};
    }
  }

  static Map parseToMap(Object data) {
    if (data is Map) return data;
    if (data is String) return json.decode(data);
    return {};
  }
}

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  const url = "https://motu-avb-controller.web.app/#/aux/0";
  final jsonObject =
      jsonDecode(await File('./input_settings.json').readAsString());
  final jsonStr = utf8.encode(jsonEncode(jsonObject));
  final encodedBytes = base64Encode(jsonStr);
  print("$url?settings=$encodedBytes");
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:lubrication_indicator/core/api/api_client.dart';

final _qrShot = ScreenshotController();

Future<String> _uploadQr(Uint8List bytes) async {
  debugPrint('[QR] Uploading QR image to server...');
  final filename = 'tank_qr_${DateTime.now().millisecondsSinceEpoch}.png';
  final url = await ApiClient.uploadBytes(bytes, filename: filename, category: 'qr');
  debugPrint('[QR] Uploaded successfully -> $url');
  return url;
}

Future<String> generateAndUploadQr({
  required String tankCode,
  required String tankName,
  required String location,
}) async {
  debugPrint(
      '[QR] Generating QR for code=$tankCode name=$tankName loc=$location');
  final qrData = jsonEncode({
    'tank_code': tankCode,
    'tank_name': tankName,
    'location': location,
  });
  final bytes = await _qrShot.captureFromWidget(
    Material(color: Colors.white, child: QrImageView(data: qrData, size: 320)),
  );
  debugPrint('[QR] QR captured, size=${bytes.length} bytes');
  return _uploadQr(bytes);
}

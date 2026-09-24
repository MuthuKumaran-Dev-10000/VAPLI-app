import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:lubrication_indicator/core/api/api_client.dart';

const String _folderQr = 'qr';
const String folderMain = 'general';

Future<String> uploadBytesToCloudinary(Uint8List bytes,
    {String folder = _folderQr}) async {
  debugPrint('[ServerUpload] Uploading bytes=${bytes.length} category=$folder');
  final filename = 'tank_qr_${DateTime.now().millisecondsSinceEpoch}.png';
  final url = await ApiClient.uploadBytes(bytes, filename: filename, category: folder.contains('qr') ? 'qr' : folder);
  debugPrint('[ServerUpload] Uploaded → $url');
  return url;
}

/// Renders a QR from identity data, uploads to backend, returns the URL.
Future<String> _generateQrAndUpload({
  required ScreenshotController shotCtrl,
  required String tankCode,
  required String tankName,
  required String location,
}) async {
  debugPrint('[QR] Generating QR: code=$tankCode name=$tankName loc=$location');
  final qrData = jsonEncode({
    'tank_code': tankCode,
    'tank_name': tankName,
    'location': location,
  });
  final bytes = await shotCtrl.captureFromWidget(
    Material(color: Colors.white, child: QrImageView(data: qrData, size: 320)),
  );
  debugPrint('[QR] Captured ${bytes.length} bytes');
  return uploadBytesToCloudinary(bytes, folder: _folderQr);
}

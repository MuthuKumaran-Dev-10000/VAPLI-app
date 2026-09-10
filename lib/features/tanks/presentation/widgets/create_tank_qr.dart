import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vapli/features/admin/services/admin_cloudinary.dart';

final _qrShot = ScreenshotController();

class QrGenerationResult {
  final String qrJson;
  final String qrImageUrl;

  QrGenerationResult({required this.qrJson, required this.qrImageUrl});
}

Future<QrGenerationResult> generateAndUploadQr({
  String? tankId,
  required String tankCode,
  required String tankName,
  required String location,
}) async {
  debugPrint('[QR] Generating unique QR for tankId=$tankId code=$tankCode name=$tankName loc=$location');
  final Map<String, dynamic> payload = {
    if (tankId != null && tankId.isNotEmpty) 'tank_id': tankId,
    'tank_code': tankCode,
    'tank_name': tankName,
    'location': location,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final qrData = jsonEncode(payload);

  final bytes = await _qrShot.captureFromWidget(
    Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: QrImageView(data: qrData, size: 320),
      ),
    ),
  );

  debugPrint('[QR] QR captured, size=${bytes.length} bytes. Uploading to server...');
  final url = await uploadBytesToCloudinary(
    bytes,
    assetId: tankCode,
    assetName: tankName,
  );

  return QrGenerationResult(qrJson: qrData, qrImageUrl: url);
}

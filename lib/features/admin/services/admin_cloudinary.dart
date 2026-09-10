import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/api/api_client.dart';

const String _folderQr = 'lubricationindicator_qr';
const String folderMain = 'lubricationindicator';

Future<String> uploadBytesToCloudinary(
  Uint8List bytes, {
  String folder = _folderQr,
  String? assetId,
  String? assetName,
}) async {
  debugPrint('[LocalStorage] Uploading QR image bytes=${bytes.length} to local server uploads/qr/');
  final api = ApiClient();
  final fields = <String, String>{};
  if (assetId != null && assetId.isNotEmpty) fields['asset_id'] = assetId;
  if (assetName != null && assetName.isNotEmpty) fields['asset_name'] = assetName;

  final res = await api.uploadMultipart(
    '/uploads/qr',
    bytes: bytes,
    filename: 'image.png',
    fields: fields,
  );

  if (res is Map && res['url'] != null) {
    final url = res['url'].toString();
    debugPrint('[LocalStorage] QR Uploaded successfully → $url');
    return url;
  }
  throw Exception('QR image upload failed: invalid response from server');
}

Future<void> deleteImageByUrl(String? url) async {
  if (url == null || url.trim().isEmpty) return;
  try {
    debugPrint('[LocalStorage] Deleting QR image for url: $url');
    final api = ApiClient();
    await api.delete('/uploads/qr', body: {'url': url});
  } catch (e) {
    debugPrint('[LocalStorage] Warning: delete QR image failed: $e');
  }
}

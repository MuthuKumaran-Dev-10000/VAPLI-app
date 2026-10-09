import 'package:lubrication_indicator/core/api/api_client.dart';

/// Resolves stored media paths for display. Legacy Cloudinary URLs are used as-is.
/// Server upload URLs are rewritten to the app API host (fixes 127.0.0.1 in DB).
class MediaUrlResolver {
  static String get apiOrigin {
    final base = ApiClient.baseUrl.trim();
    if (base.endsWith('/api/v1')) {
      return base.substring(0, base.length - '/api/v1'.length);
    }
    if (base.endsWith('/api/v1/')) {
      return base.substring(0, base.length - '/api/v1/'.length);
    }
    return base;
  }

  static String resolve(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _rewriteLocalUploadUrl(trimmed);
    }

    final origin = apiOrigin;
    if (trimmed.startsWith('/')) {
      return '$origin$trimmed';
    }
    if (trimmed.startsWith('uploads/')) {
      return '$origin/$trimmed';
    }
    return '$origin/uploads/$trimmed';
  }

  /// Maps any stored `/uploads/...` URL to [apiOrigin] so phones are not stuck on 127.0.0.1.
  static String _rewriteLocalUploadUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final uploadsIdx = path.indexOf('/uploads/');
      if (uploadsIdx < 0) {
        return url;
      }
      final uploadPath = path.substring(uploadsIdx);
      var out = '${apiOrigin}$uploadPath';
      if (uri.hasQuery) {
        out = '$out?${uri.query}';
      }
      return out;
    } catch (_) {
      return url;
    }
  }

  static List<String> resolveList(Iterable<String?> urls) {
    final out = <String>[];
    for (final u in urls) {
      final resolved = resolve(u);
      if (resolved.isNotEmpty && !out.contains(resolved)) {
        out.add(resolved);
      }
    }
    return out;
  }
}

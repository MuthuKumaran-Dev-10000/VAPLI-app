import 'dart:convert';

import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';
import 'package:lubrication_indicator/core/utils/media_url_resolver.dart';
import 'dashboard_alerts_display_model.dart';

/// Loads completed tasks from MySQL (`completed_tasks` + alert snapshot).
class CompletedAlertsLoader {
  static List<String> _parsePhotoUrls(Map<dynamic, dynamic> m) {
    dynamic raw = m['completed_photo_urls'] ?? m['photo_urls_json'];
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    if (raw is List) {
      return MediaUrlResolver.resolveList(raw.map((e) => e.toString()));
    }
    final single = m['completed_photo_url']?.toString() ?? '';
    return single.isNotEmpty ? [MediaUrlResolver.resolve(single)] : [];
  }

  static Future<List<DashboardAlertDisplayItem>> load() async {
    final clientId = await ClientContextService.requireActiveClientId();
    final response = await ApiClient.get('/clients/$clientId/completed-tasks');
    if (response is! Map || response['success'] != true || response['data'] == null) {
      return [];
    }

    final items = <DashboardAlertDisplayItem>[];
    for (final v in (response['data'] as List)) {
      if (v is! Map) continue;
      final m = Map<dynamic, dynamic>.from(v);
      final alertRaw = m['alert'];
      if (alertRaw is! Map) continue;
      final alert = Map<dynamic, dynamic>.from(alertRaw);

      final photoUrls = _parsePhotoUrls(m);
      final completedAt = m['completed_at']?.toString() ?? '';
      final completedBy = m['completed_by']?.toString() ?? 'Inspector';
      final description = m['completed_description']?.toString() ??
          alert['completed_description']?.toString() ??
          '';

      final merged = Map<dynamic, dynamic>.from(alert);
      merged['completed_description'] = description;
      merged['completed_photo_urls'] = photoUrls;
      if (photoUrls.isNotEmpty) {
        merged['completed_photo_url'] = photoUrls.first;
      }
      if (completedAt.isNotEmpty) {
        merged['timestamp'] = completedAt;
      }
      merged['status'] = 'COMPLETED';
      merged['acknowledged'] = true;

      final item = DashboardAlertDisplayItem.fromMap(merged);
      items.add(DashboardAlertDisplayItem(
        id: item.id,
        alertTitle: item.alertTitle,
        message: item.message,
        op: item.op,
        severity: item.severity,
        tankId: item.tankId,
        tankName: item.tankName,
        tankCode: item.tankCode,
        paramId: item.paramId,
        paramLabel: item.paramLabel,
        paramValue: item.paramValue,
        constraintValue: item.constraintValue,
        capturedBy: item.capturedBy,
        capturedByName: item.capturedByName,
        imageUrl: item.imageUrl,
        constraintId: item.constraintId,
        timestamp: completedAt.isNotEmpty ? completedAt : item.timestamp,
        acknowledged: true,
        isLive: false,
        status: 'COMPLETED',
        readingId: item.readingId,
        ifThen: item.ifThen,
        completedDescription: description,
        completedPhotoUrl: photoUrls.isNotEmpty ? photoUrls.first : '',
        completedPhotoUrls: photoUrls,
        rankScore: item.rankScore,
        severityRating: item.severityRating,
        dueTimeRange: item.dueTimeRange,
        dueDate: item.dueDate,
        completedBy: completedBy,
      ));
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }
}

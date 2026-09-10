import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/api/api_client.dart';

class AuditLogService {
  static final ApiClient _api = ApiClient();
  static const _uuid = Uuid();

  static Future<void> record({
    required String operation,
    required String entityType,
    String? entityId,
    String? entityName,
    String? actorId,
    String? actorUsername,
    String? actorName,
    String? actorRole,
    String? tab,
    String? clientId,
    String? clientDbKey,
    String? clientName,
    Map<String, dynamic>? details,
    String outcome = 'success',
    String? summary,
    String? cascadeId,
    String? parentLogId,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logId = _uuid.v4();
      final payload = <String, dynamic>{
        'log_id': logId,
        'timestamp': timestamp,
        'operation': operation,
        'summary': summary?.trim().isNotEmpty == true
            ? summary!.trim()
            : _defaultSummary(
                operation: operation,
                entityType: entityType,
                entityName: entityName,
                details: details,
              ),
        'entity_type': entityType,
        'entity_id': entityId ?? '',
        'entity_name': entityName ?? '',
        'outcome': outcome,
        'actor_id': actorId ?? 'system',
        'actor_username': actorUsername ?? 'system',
        'actor_name': actorName ?? 'System',
        'actor_role': actorRole ?? 'system',
        'tab': tab ?? '',
        'client_id': clientId ?? '',
        'client_name': clientName ?? '',
        'details': details ?? <String, dynamic>{},
      };

      await _api.post('/audit-logs', payload);
    } catch (e) {
      debugPrint('[AuditLogService] Error recording log: $e');
    }
  }

  static String _defaultSummary({
    required String operation,
    required String entityType,
    String? entityName,
    Map<String, dynamic>? details,
  }) {
    final target = (entityName ?? '').trim();
    switch (operation) {
      case 'create_tank':
        return target.isEmpty ? 'Created tank' : 'Created tank $target';
      case 'update_tank':
        return target.isEmpty ? 'Updated tank' : 'Updated tank $target';
      case 'create_tank_parameter':
        return target.isEmpty
            ? 'Added an inspection parameter'
            : 'Added inspection parameter $target';
      case 'update_tank_parameter':
        return target.isEmpty
            ? 'Updated an inspection parameter'
            : 'Updated inspection parameter $target';
      case 'save_reading':
        return target.isEmpty ? 'Saved reading' : 'Saved reading for $target';
      default:
        return target.isEmpty ? operation : '$operation on $target';
    }
  }
}

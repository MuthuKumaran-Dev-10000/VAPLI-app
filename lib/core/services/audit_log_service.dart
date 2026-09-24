import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';

class AuditLogService {
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
      final activeClient = await ClientContextService.getActiveClient();
      final targetClientId = clientId ?? activeClient?.id;
      if (targetClientId == null || targetClientId.isEmpty) return;

      final payload = {
        'operation': operation,
        'summary': summary ?? _defaultSummary(operation: operation, entityType: entityType, entityName: entityName),
        'entity_type': entityType,
        'entity_id': entityId ?? '',
        'entity_name': entityName ?? '',
        'outcome': outcome,
        'actor_id': actorId ?? '',
        'actor_name': actorName ?? actorUsername ?? 'User',
        'actor_role': actorRole ?? '',
        'tab': tab ?? '',
        'details': details ?? {},
      };

      await ApiClient.post('/clients/$targetClientId/audit-logs', payload);
    } catch (_) {}
  }

  static String _defaultSummary({
    required String operation,
    required String entityType,
    String? entityName,
  }) {
    final target = (entityName ?? '').trim();
    return target.isEmpty ? operation : '$operation on $target';
  }
}

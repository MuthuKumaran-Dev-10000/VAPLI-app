import 'dart:async';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';
import '../models/dashboard_stats_model.dart';
import 'package:lubrication_indicator/features/readings/data/models/reading_model.dart';
import 'package:lubrication_indicator/features/tanks/data/models/tank_model.dart';

class DashboardStatsRepository {
  Future<String> _getClientId() async {
    final client = await ClientContextService.getActiveClient();
    return client?.id ?? 'dummy_client_id';
  }

  Stream<DashboardStatsModel> watchStats(String tankId) {
    final controller = StreamController<DashboardStatsModel>.broadcast();
    getStats(tankId).then((stats) {
      controller.add(stats);
    }).catchError((err) {
      controller.addError(err);
    });
    return controller.stream;
  }

  Future<DashboardStatsModel> getStats(String tankId) async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/dashboard/stats');
    if (response is Map && response['success'] == true && response['data'] != null) {
      final statsList = (response['data']['tanksStats'] as List?) ?? [];
      final match = statsList.firstWhere(
        (s) => s['tank_id'].toString() == tankId,
        orElse: () => null,
      );
      if (match != null) {
        return DashboardStatsModel.fromMap(tankId, Map<dynamic, dynamic>.from(match));
      }
    }
    return DashboardStatsModel.empty(tankId);
  }

  Future<void> updateStatsAfterReading({
    required ReadingModel reading,
    required TankModel tank,
  }) async {
    // Stat updates are processed automatically inside backend saveReadingTransaction
  }
}
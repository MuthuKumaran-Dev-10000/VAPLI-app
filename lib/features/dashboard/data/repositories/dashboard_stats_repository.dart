import 'dart:async';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';
import '../models/dashboard_stats_model.dart';
import 'package:lubrication_indicator/features/readings/data/models/reading_model.dart';
import 'package:lubrication_indicator/features/tanks/data/models/tank_model.dart';

class DashboardStatsRepository {
  Future<String> _getClientId() async {
    return ClientContextService.requireActiveClientId();
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

  Future<Map<String, DashboardStatsModel>> getAllStatsByTank() async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/dashboard/stats');
    final out = <String, DashboardStatsModel>{};
    if (response is Map &&
        response['success'] == true &&
        response['data'] != null) {
      final statsList = (response['data']['tanksStats'] as List?) ?? [];
      for (final row in statsList) {
        if (row is! Map) continue;
        final tid = row['tank_id']?.toString() ?? '';
        if (tid.isEmpty) continue;
        out[tid] = DashboardStatsModel.fromMap(
          tid,
          Map<dynamic, dynamic>.from(row),
        );
      }
    }
    return out;
  }

  Future<DashboardStatsModel> getStats(String tankId) async {
    final all = await getAllStatsByTank();
    return all[tankId] ?? DashboardStatsModel.empty(tankId);
  }

  Future<void> updateStatsAfterReading({
    required ReadingModel reading,
    required TankModel tank,
  }) async {
    // Stat updates are processed automatically inside backend saveReadingTransaction
  }
}
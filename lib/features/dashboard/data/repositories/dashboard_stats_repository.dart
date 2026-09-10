import '../models/dashboard_stats_model.dart';
import 'package:vapli/features/readings/data/models/reading_model.dart';
import 'package:vapli/features/tanks/data/models/tank_model.dart';

class DashboardStatsRepository {
  Stream<DashboardStatsModel> watchStats(String tankId) async* {
    yield DashboardStatsModel.empty(tankId);
  }

  Future<DashboardStatsModel> getStats(String tankId) async {
    return DashboardStatsModel.empty(tankId);
  }

  Future<void> updateStatsAfterReading({
    required ReadingModel reading,
    required TankModel tank,
  }) async {}
}
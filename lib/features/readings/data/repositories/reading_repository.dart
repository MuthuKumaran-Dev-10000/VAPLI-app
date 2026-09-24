import 'dart:async';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';
import 'package:lubrication_indicator/core/utils/hash_util.dart';
import '../models/reading_model.dart';

class ReadingRepository {
  static final ReadingRepository _instance = ReadingRepository._internal();
  factory ReadingRepository() => _instance;
  ReadingRepository._internal();

  final _readingUpdateController = StreamController<void>.broadcast();

  void notifySubscribers() {
    if (!_readingUpdateController.isClosed) {
      _readingUpdateController.add(null);
    }
  }

  Future<String> _getClientId() async {
    final client = await ClientContextService.getActiveClient();
    return client?.id ?? 'dummy_client_id';
  }

  Stream<List<ReadingModel>> watchAllReadings() {
    late StreamController<List<ReadingModel>> localController;
    StreamSubscription? sub;

    void update() async {
      try {
        final all = await getAllReadings();
        if (!localController.isClosed) {
          localController.add(all);
        }
      } catch (err) {
        if (!localController.isClosed) {
          localController.addError(err);
        }
      }
    }

    localController = StreamController<List<ReadingModel>>(
      onListen: () {
        update();
        sub = _readingUpdateController.stream.listen((_) {
          update();
        });
      },
      onCancel: () {
        sub?.cancel();
        localController.close();
      },
    );

    return localController.stream;
  }

  Stream<List<ReadingModel>> watchReadingsForTank(String tankId) {
    late StreamController<List<ReadingModel>> localController;
    StreamSubscription? sub;

    void update() async {
      try {
        final all = await getAllReadings();
        final filtered = all.where((r) => r.tankId == tankId).toList();
        if (!localController.isClosed) {
          localController.add(filtered);
        }
      } catch (err) {
        if (!localController.isClosed) {
          localController.addError(err);
        }
      }
    }

    localController = StreamController<List<ReadingModel>>(
      onListen: () {
        update();
        sub = _readingUpdateController.stream.listen((_) {
          update();
        });
      },
      onCancel: () {
        sub?.cancel();
        localController.close();
      },
    );

    return localController.stream;
  }

  Future<ReadingModel> saveReading({
    required String tankId,
    required String tankName,
    required double level,
    required String capturedBy,
    required String capturedByName,
    String? capturedAtStart,
    String? capturedAt,
    Map<String, dynamic>? inspectionValues,
    String? imageUrl,
  }) async {
    final clientId = await _getClientId();
    final id = HashUtil.generateId();

    final payload = {
      'id': id,
      'tank_id': tankId,
      'tank_name': tankName,
      'final_level': level,
      'captured_by': capturedBy,
      'captured_by_name': capturedByName,
      'captured_at_start': capturedAtStart,
      'captured_at': capturedAt ?? DateTime.now().toIso8601String(),
      'inspection_values': inspectionValues ?? {},
      'image_url': imageUrl,
      'source': 'manual',
    };

    final response = await ApiClient.post('/clients/$clientId/tanks/$tankId/readings', payload);

    if (response is Map && response['success'] == true) {
      notifySubscribers();
      return ReadingModel(
        id: id,
        tankId: tankId,
        tankSnapshotName: tankName,
        finalLevel: level,
        inspectionValues: inspectionValues ?? {},
        imageUrl: imageUrl,
        source: "manual",
        capturedBy: capturedBy,
        capturedByName: capturedByName,
        capturedAtStart: capturedAtStart,
        capturedAt: capturedAt ?? DateTime.now().toIso8601String(),
      );
    } else {
      final msg = (response is Map && response['error'] != null)
          ? response['error']['message']
          : 'Failed to save reading';
      throw Exception(msg);
    }
  }

  Future<List<ReadingModel>> getReadingsInRange({
    required String tankId,
    required DateTime from,
    required DateTime to,
  }) async {
    final all = await getAllReadings();
    final readings = all.where((r) {
      if (r.tankId != tankId) return false;
      final t = DateTime.tryParse(r.capturedAt);
      if (t == null) return false;
      return !t.toLocal().isBefore(from.toLocal()) && !t.toLocal().isAfter(to.toLocal());
    }).toList();

    readings.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return readings;
  }

  Future<List<ReadingModel>> getAllReadings() async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/readings');
    if (response is Map && response['success'] == true && response['data'] != null) {
      final list = response['data'] as List;
      return list
          .map((item) => ReadingModel.fromMap(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }
    return [];
  }

  Future<ReadingModel?> getLastReading(String tankId) async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/tanks/$tankId/readings/last');
    if (response is Map && response['success'] == true && response['data'] != null) {
      return ReadingModel.fromMap(Map<String, dynamic>.from(response['data']));
    }
    return null;
  }
}
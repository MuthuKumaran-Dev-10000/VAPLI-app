import 'dart:async';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/services/client_context_service.dart';
import 'package:lubrication_indicator/core/utils/hash_util.dart';
import '../models/tank_node_model.dart';

class TankTreeRepository {
  static final TankTreeRepository _instance = TankTreeRepository._internal();
  factory TankTreeRepository() => _instance;
  TankTreeRepository._internal();

  final _treeUpdateController = StreamController<void>.broadcast();

  void notifySubscribers() {
    if (!_treeUpdateController.isClosed) {
      _treeUpdateController.add(null);
    }
  }

  Future<String> _getClientId() async {
    final client = await ClientContextService.getActiveClient();
    return client?.id ?? 'dummy_client_id';
  }

  Stream<List<TankNode>> watchChildren(String? parentId) {
    late StreamController<List<TankNode>> localController;
    StreamSubscription? sub;

    void updateChildren() async {
      try {
        final allNodes = await fetchAll();
        final children = allNodes
            .where((n) => n.parentId == parentId)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        if (!localController.isClosed) {
          localController.add(children);
        }
      } catch (err) {
        if (!localController.isClosed) {
          localController.addError(err);
        }
      }
    }

    localController = StreamController<List<TankNode>>(
      onListen: () {
        updateChildren();
        sub = _treeUpdateController.stream.listen((_) {
          updateChildren();
        });
      },
      onCancel: () {
        sub?.cancel();
        localController.close();
      },
    );

    return localController.stream;
  }

  Future<List<TankNode>> fetchAll() async {
    final clientId = await _getClientId();
    final response = await ApiClient.get('/clients/$clientId/tank-tree');
    if (response is Map && response['success'] == true && response['data'] != null) {
      final list = response['data'] as List;
      final nodes = list
          .map((item) => TankNode.fromMap(
                item['id'].toString(),
                Map<dynamic, dynamic>.from(item),
              ))
          .toList();
      nodes.sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return nodes;
    }
    return [];
  }

  Future<TankNode?> fetchNode(String id) async {
    final all = await fetchAll();
    try {
      return all.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TankNode> createFolder({
    required String name,
    String? description,
    String? zone,
    String? parentId,
  }) async {
    final clientId = await _getClientId();
    final id = HashUtil.generateId();
    final allNodes = await fetchAll();
    final siblings = allNodes.where((n) => n.parentId == parentId).toList();
    final nextOrder = siblings.isEmpty
        ? 1
        : (siblings.map((s) => s.order).fold<int>(0, (prev, elem) => elem > prev ? elem : prev) + 1);

    final nodeMap = {
      'id': id,
      'type': 'folder',
      'name': name,
      'description': description,
      'zone': zone,
      'parent_id': parentId,
      'order': nextOrder,
      'sort_order': nextOrder,
    };
    await ApiClient.post('/clients/$clientId/tank-tree', nodeMap);
    notifySubscribers();
    return TankNode.fromMap(id, nodeMap);
  }

  Future<TankNode> createLeaf({
    required String name,
    required String tankId,
    String? zone,
    String? parentId,
  }) async {
    final clientId = await _getClientId();
    final id = HashUtil.generateId();
    final allNodes = await fetchAll();
    final siblings = allNodes.where((n) => n.parentId == parentId).toList();
    final nextOrder = siblings.isEmpty
        ? 1
        : (siblings.map((s) => s.order).fold<int>(0, (prev, elem) => elem > prev ? elem : prev) + 1);

    final nodeMap = {
      'id': id,
      'type': 'leaf',
      'name': name,
      'tank_id': tankId,
      'zone': zone,
      'parent_id': parentId,
      'order': nextOrder,
      'sort_order': nextOrder,
    };
    await ApiClient.post('/clients/$clientId/tank-tree', nodeMap);
    notifySubscribers();
    return TankNode.fromMap(id, nodeMap);
  }

  Future<void> updateFolder({
    required String id,
    required String name,
    String? description,
    String? zone,
  }) async {
    final clientId = await _getClientId();
    await ApiClient.post('/clients/$clientId/tank-tree', {
      'id': id,
      'name': name,
      'description': description,
      'zone': zone,
    });
    notifySubscribers();
  }

  Future<void> deleteNode(String id) async {
    final clientId = await _getClientId();
    await ApiClient.delete('/clients/$clientId/tank-tree/$id');
    notifySubscribers();
  }

  Future<List<TankNode>> fetchSubtree(String id) async {
    final all = await fetchAll();
    return all.where((n) => n.id == id || n.parentId == id).toList();
  }

  Future<void> deleteTankFromTree(String tankId) async {
    final all = await fetchAll();
    final matches = all.where((n) => n.tankId == tankId);
    for (final m in matches) {
      await deleteNode(m.id);
    }
    notifySubscribers();
  }

  Future<void> moveNode({
    required String nodeId,
    required String? newParentId,
  }) async {
    final clientId = await _getClientId();
    await ApiClient.post('/clients/$clientId/tank-tree', {
      'id': nodeId,
      'parent_id': newParentId,
    });
    notifySubscribers();
  }

  Future<void> reorderNodes(List<String> nodeIds) async {
    final clientId = await _getClientId();
    for (int i = 0; i < nodeIds.length; i++) {
      await ApiClient.post('/clients/$clientId/tank-tree', {
        'id': nodeIds[i],
        'sort_order': i + 1,
        'order': i + 1,
      });
    }
    notifySubscribers();
  }

  Future<int> countChildren(String parentId) async {
    final all = await fetchAll();
    return all.where((n) => n.parentId == parentId).length;
  }
}

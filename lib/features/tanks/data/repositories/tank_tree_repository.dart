import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/api/api_client.dart';
import '../models/tank_node_model.dart';

class TankTreeRepository {
  final ApiClient _api = ApiClient();
  final _uuid = const Uuid();

  /// Stream of direct children of [parentId] (or root if null).
  Stream<List<TankNode>> watchChildren(String? parentId) async* {
    while (true) {
      try {
        final nodes = await getChildren(parentId);
        yield nodes;
      } catch (e) {
        debugPrint('[TankTreeRepository] watchChildren error: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<List<TankNode>> getChildren(String? parentId) async {
    final query = parentId == null ? '?parent_id=null' : '?parent_id=$parentId';
    final res = await _api.get('/assets/nodes$query');
    if (res is Map && res['nodes'] is List) {
      final list = (res['nodes'] as List).cast<Map>();
      final nodes = list.map((m) => TankNode.fromMap(m['id'].toString(), m)).toList();

      return nodes.where((n) {
        if (parentId == null) {
          return n.parentId == null || n.parentId!.trim().isEmpty || n.parentId == 'null';
        } else {
          return n.parentId == parentId;
        }
      }).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }
    return [];
  }

  Future<int> countChildren(String parentId) async {
    final children = await getChildren(parentId);
    return children.length;
  }

  Future<List<TankNode>> fetchAll() async {
    final res = await _api.get('/assets/nodes?all=true');
    if (res is Map && res['nodes'] is List) {
      final list = (res['nodes'] as List).cast<Map>();
      return list.map((m) => TankNode.fromMap(m['id'].toString(), m)).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }
    return [];
  }

  Future<List<TankNode>> fetchSubtree(String rootNodeId) async {
    final all = await fetchAll();
    final nodeMap = {for (var n in all) n.id: n};
    if (!nodeMap.containsKey(rootNodeId)) return [];

    final result = <TankNode>[];
    void collect(String id) {
      final curr = nodeMap[id];
      if (curr != null) {
        result.add(curr);
        final children = all.where((n) => n.parentId == id);
        for (final child in children) {
          collect(child.id);
        }
      }
    }

    collect(rootNodeId);
    return result;
  }

  Future<TankNode?> getNode(String id) async {
    final all = await fetchAll();
    try {
      return all.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TankNode?> fetchNode(String id) => getNode(id);

  Future<TankNode?> getNodeByTankId(String tankId) async {
    final all = await fetchAll();
    try {
      return all.firstWhere((n) => n.tankId == tankId);
    } catch (_) {
      return null;
    }
  }

  Future<String> createFolder({
    required String name,
    String? description,
    String? zone,
    String? parentId,
  }) async {
    final id = _uuid.v4();
    String path = name;
    int order = 0;

    if (parentId != null) {
      final parent = await getNode(parentId);
      if (parent != null) {
        path = '${parent.path}/$name';
      }
      final sibs = await getChildren(parentId);
      order = sibs.length;
    } else {
      final roots = await getChildren(null);
      order = roots.length;
    }

    final node = TankNode(
      id: id,
      type: 'folder',
      name: name,
      description: description,
      zone: zone,
      parentId: parentId,
      path: path,
      order: order,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _api.post('/assets/nodes', node.toMap());
    return id;
  }

  Future<String> createLeaf({
    required String name,
    required String tankId,
    String? zone,
    String? parentId,
  }) async {
    final id = _uuid.v4();
    String path = name;
    int order = 0;

    if (parentId != null) {
      final parent = await getNode(parentId);
      if (parent != null) {
        path = '${parent.path}/$name';
      }
      final sibs = await getChildren(parentId);
      order = sibs.length;
    } else {
      final roots = await getChildren(null);
      order = roots.length;
    }

    final node = TankNode(
      id: id,
      type: 'leaf',
      name: name,
      zone: zone,
      parentId: parentId,
      path: path,
      order: order,
      tankId: tankId,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _api.post('/assets/nodes', node.toMap());
    return id;
  }

  Future<void> updateNode(
    String id, {
    String? name,
    String? description,
    String? zone,
    String? path,
    int? order,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (zone != null) body['zone'] = zone;
    if (path != null) body['path'] = path;
    if (order != null) body['order'] = order;

    if (body.isNotEmpty) {
      await _api.patch('/assets/nodes/$id', body);
    }
  }

  Future<void> updateFolder({
    required String id,
    required String name,
    String? description,
    String? zone,
  }) async {
    await updateNode(id, name: name, description: description, zone: zone);
  }

  Future<void> moveNode({
    required String nodeId,
    String? newParentId,
  }) async {
    final target = await getNode(nodeId);
    if (target == null) return;

    String newPath = target.name;
    if (newParentId != null) {
      final parent = await getNode(newParentId);
      if (parent != null) {
        newPath = '${parent.path}/${target.name}';
      }
    }

    final sibs = await getChildren(newParentId);
    final order = sibs.length;

    await _api.patch('/assets/nodes/$nodeId', {
      'parent_id': newParentId,
      'path': newPath,
      'order': order,
    });
  }

  Future<void> reorderChildren(List<String> orderedNodeIds) async {
    for (int i = 0; i < orderedNodeIds.length; i++) {
      await _api.patch('/assets/nodes/${orderedNodeIds[i]}', {'order': i});
    }
  }

  Future<void> reorderNodes(List<String> orderedNodeIds) =>
      reorderChildren(orderedNodeIds);

  Future<void> deleteNode(String id) async {
    await _api.delete('/assets/nodes/$id');
  }
}

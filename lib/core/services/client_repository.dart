import 'dart:async';
import 'package:lubrication_indicator/core/api/api_client.dart';
import 'package:lubrication_indicator/core/models/client_model.dart';

class ClientRepository {
  final _controller = StreamController<List<ClientModel>>.broadcast();

  Stream<List<ClientModel>> watchClients() {
    // Initial fetch
    getAllClients().then((clients) {
      _controller.add(clients);
    }).catchError((err) {
      _controller.addError(err);
    });
    return _controller.stream;
  }

  Future<List<ClientModel>> getAllClients() async {
    final response = await ApiClient.get('/clients');
    if (response is Map && response['success'] == true && response['data'] != null) {
      final list = response['data'] as List;
      final clients = list
          .map((item) => ClientModel.fromMap(Map<String, dynamic>.from(item)))
          .where((c) => c.isActive)
          .toList();
      _controller.add(clients);
      return clients;
    }
    return [];
  }

  Future<ClientModel> createClient({
    required String name,
    String description = '',
  }) async {
    final response = await ApiClient.post('/clients', {
      'name': name.trim(),
      'description': description.trim(),
      'db_key': name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
    });

    if (response is Map && response['success'] == true && response['data'] != null) {
      final client = ClientModel.fromMap(Map<String, dynamic>.from(response['data']));
      await getAllClients();
      return client;
    } else {
      throw Exception('Failed to create client');
    }
  }

  Future<void> updateClient(String id, Map<String, dynamic> updates) async {
    await ApiClient.put('/clients/$id', updates);
    await getAllClients();
  }

  Future<void> deleteClient(String id) async {
    await ApiClient.delete('/clients/$id');
    await getAllClients();
  }

  Future<void> ensureClientBootstrap(ClientModel client) async {
    try {
      await ApiClient.get('/clients/${client.id}/bootstrap');
    } catch (_) {}
  }
}

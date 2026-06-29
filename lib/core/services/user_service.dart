import 'dart:convert';
import 'package:finance_control/core/api/api_client.dart';

class UserService {
  final ApiClient _client;

  UserService(String token) : _client = ApiClient(token: token);

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get('/user/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    throw Exception('Erro ao carregar perfil');
  }

  Future<void> updateName(String name) async {
    final response = await _client.patch('/user/me', {'name': name});
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erro ao atualizar nome');
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final response = await _client.patch('/user/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erro ao alterar senha');
    }
  }
}

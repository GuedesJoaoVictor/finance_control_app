import 'dart:convert';

import 'package:finance_control/core/api/api_client.dart';
import 'package:finance_control/core/models/user.dart';
import 'package:finance_control/core/utils/jwt_util.dart';

class AuthService {
  String? _token;
  User? _user;
  JwtClaims? _claims;

  String? get token => _token;
  User? get user => _user;
  JwtClaims? get claims => _claims;
  bool get isLogged => _token != null;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final apiClient = ApiClient();
    final response = await apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['token'] as String?;
      _claims = JwtDecoder.decode(_token);
      if (data['user'] != null) {
        _user = User.fromJson(data['user'] as Map<String, dynamic>);
      }
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erro ao fazer login',
      );
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String cpf,
  ) async {
    final apiClient = ApiClient();
    final response = await apiClient.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'cpf': cpf,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erro ao registrar',
      );
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _claims = null;
  }
}

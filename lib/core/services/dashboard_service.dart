import 'dart:convert';

import 'package:finance_control/core/api/api_client.dart';
import 'package:finance_control/core/models/dashboard_data.dart';

class DashboardService {
  final ApiClient _client;

  DashboardService(String token) : _client = ApiClient(token: token);

  Future<DashboardData> getDashboard() async {
    final response = await _client.get('/dashboard');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DashboardData.fromJson(data['data']);
    }
    throw Exception('Erro ao carregar dashboard');
  }
}

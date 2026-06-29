import 'dart:convert';
import 'package:finance_control/core/api/api_client.dart';
import 'package:finance_control/core/models/budget.dart';

class BudgetService {
  final ApiClient _client;

  BudgetService(String token) : _client = ApiClient(token: token);

  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    var endpoint = '/budget';
    final params = <String>[];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';

    final response = await _client.get(endpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => Budget.fromJson(json)).toList();
    }
    throw Exception('Erro ao carregar orçamentos');
  }

  Future<Budget> create(Budget budget) async {
    final response = await _client.post('/budget', budget.toJson());
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Budget.fromJson(data['data']);
    }
    throw Exception('Erro ao criar orçamento');
  }

  Future<Budget> update(int id, Map<String, dynamic> body) async {
    final response = await _client.patch('/budget/$id', body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Budget.fromJson(data['data']);
    }
    throw Exception('Erro ao atualizar orçamento');
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/budget/$id');
    if (response.statusCode != 200) {
      throw Exception('Erro ao remover orçamento');
    }
  }
}

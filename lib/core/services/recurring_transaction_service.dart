import 'dart:convert';
import 'package:finance_control/core/api/api_client.dart';
import 'package:finance_control/core/models/recurring_transaction.dart';

class RecurringTransactionService {
  final ApiClient _client;

  RecurringTransactionService(String token) : _client = ApiClient(token: token);

  Future<List<RecurringTransaction>> findAll() async {
    final response = await _client.get('/recurring');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => RecurringTransaction.fromJson(json)).toList();
    }
    throw Exception('Erro ao carregar transações recorrentes');
  }

  Future<RecurringTransaction> create(RecurringTransaction rt) async {
    final response = await _client.post('/recurring', rt.toJson());
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return RecurringTransaction.fromJson(data['data']);
    }
    throw Exception('Erro ao criar transação recorrente');
  }

  Future<RecurringTransaction> update(int id, Map<String, dynamic> body) async {
    final response = await _client.patch('/recurring/$id', body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RecurringTransaction.fromJson(data['data']);
    }
    throw Exception('Erro ao atualizar transação recorrente');
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/recurring/$id');
    if (response.statusCode != 200) {
      throw Exception('Erro ao remover transação recorrente');
    }
  }

  Future<int> apply(int month, int year) async {
    final response = await _client.post('/recurring/apply?month=$month&year=$year', {});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as num).toInt();
    }
    throw Exception('Erro ao aplicar transações recorrentes');
  }
}

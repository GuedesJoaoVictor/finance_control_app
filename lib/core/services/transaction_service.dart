import 'dart:convert';

import 'package:finance_control/core/api/api_client.dart';
import 'package:finance_control/core/models/transaction.dart';

class TransactionService {
  final ApiClient _client;

  TransactionService(String token) : _client = ApiClient(token: token);

  Future<List<Revenue>> getRevenuesByUser(String uuid) async {
    final response =
        await _client.get('/transaction/find-all/revenue/by/user/$uuid');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => Revenue.fromJson(json)).toList();
    }
    throw Exception('Erro ao carregar receitas');
  }

  Future<Revenue> createRevenue(Map<String, dynamic> revenueData) async {
    final response =
        await _client.post('/transaction/create/revenue', revenueData);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Revenue.fromJson(data['data']);
    }
    throw Exception('Erro ao criar receita');
  }

  Future<Revenue> updateRevenue(int id, Map<String, dynamic> revenueData) async {
    final response =
        await _client.patch('/transaction/update/revenue/$id', revenueData);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Revenue.fromJson(data['data']);
    }
    throw Exception('Erro ao atualizar receita');
  }

  Future<bool> deleteRevenue(int id) async {
    final response =
        await _client.delete('/transaction/delete/revenue/by/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] == true;
    }
    throw Exception('Erro ao deletar receita');
  }

  Future<List<Expense>> getExpensesByUser(String uuid) async {
    final response =
        await _client.get('/transaction/find-all/expense/by/user/$uuid');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => Expense.fromJson(json)).toList();
    }
    throw Exception('Erro ao carregar despesas');
  }

  Future<Expense> createExpense(Map<String, dynamic> expenseData) async {
    final response =
        await _client.post('/transaction/create/expense', expenseData);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Expense.fromJson(data['data']);
    }
    throw Exception('Erro ao criar despesa');
  }

  Future<Expense> updateExpense(int id, Map<String, dynamic> expenseData) async {
    final response =
        await _client.patch('/transaction/update/expense/$id', expenseData);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Expense.fromJson(data['data']);
    }
    throw Exception('Erro ao atualizar despesa');
  }

  Future<bool> deleteExpense(int id) async {
    final response =
        await _client.delete('/transaction/delete/expense/by/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] == true;
    }
    throw Exception('Erro ao deletar despesa');
  }
}

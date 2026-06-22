import 'dart:convert';

import 'package:finance_control/core/api/api_client.dart';
import 'package:finance_control/core/models/bank.dart';

class BankService {
  final ApiClient _client;

  BankService(String token) : _client = ApiClient(token: token);

  Future<List<Bank>> getBanksByUser([String? uuid]) async {
    final endpoint = uuid != null
        ? '/bank/find-all/links/by/user/$uuid'
        : '/bank/find-all/links/by-user';
    final response = await _client.get(endpoint);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Bank.fromJson(json)).toList();
    }
    throw Exception('Erro ao carregar bancos');
  }

  Future<Bank> getBankById(int id) async {
    final response = await _client.get('/bank/find-by-id/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Bank.fromJson(data['data']);
    }
    throw Exception('Erro ao carregar banco');
  }

  Future<Map<String, dynamic>> linkBankToUser(
    String userUuid,
    int bankId,
    String name,
    double totalAmount,
  ) async {
    final response = await _client.post(
      '/bank/vinculate/by/user/$userUuid',
      {
        'bank': {'id': bankId},
        'name': name,
        'totalAmount': totalAmount,
      },
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao vincular banco');
  }

  Future<bool> unlinkBank(int userBankId) async {
    final response =
        await _client.delete('/bank/delete/user-bank/by/$userBankId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] == true;
    }
    throw Exception('Erro ao desvincular banco');
  }

  Future<List<Bank>> getAvailableBanks(String userUuid) async {
    final response = await _client.get('/bank/find-all/by/$userUuid');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Bank.fromJson(json)).toList();
    }
    throw Exception('Erro ao carregar bancos');
  }

}

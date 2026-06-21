import 'dart:convert';

import 'package:finance_control/core/api/api_client.dart';
import 'package:finance_control/core/models/category.dart';

class CategoryService {
  final ApiClient _client;

  CategoryService(String token) : _client = ApiClient(token: token);

  Future<List<Category>> getCategoriesByUser([String? uuid]) async {
    final endpoint = uuid != null
        ? '/category/find-all-by-user/$uuid'
        : '/category/find-all-by-user';
    final response = await _client.get(endpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => Category.fromJson(json)).toList();
    }
    throw Exception('Erro ao carregar categorias');
  }

  Future<Category> createCategory(
    String name,
    String type, [
    String? uuid,
  ]) async {
    final endpoint = uuid != null
        ? '/category/create-by-user-uuid/$uuid'
        : '/category/create-by-user';
    final response = await _client.post(
      endpoint,
      {'name': name, 'type': type},
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Category.fromJson(data['data']);
    }
    throw Exception('Erro ao criar categoria');
  }

  Future<bool> deleteCategory(int id) async {
    final response = await _client.delete('/category/delete-by-id/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] == true;
    }
    throw Exception('Erro ao deletar categoria');
  }

  Future<Category> updateCategory(int id, String name, String type) async {
    final response = await _client.patch(
      '/category/update-by-id/$id',
      {'name': name, 'type': type},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Category.fromJson(data['data']);
    }
    throw Exception('Erro ao atualizar categoria');
  }
}

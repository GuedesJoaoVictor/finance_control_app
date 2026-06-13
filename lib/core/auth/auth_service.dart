import 'package:finance_control/core/api/api_client.dart';

class AuthService {
  final ApiClient apiClient = ApiClient();

  Future<void> login(String email, String password) async {
    await apiClient.post('/auth/login', {'email': email, 'password': password});
  }
}

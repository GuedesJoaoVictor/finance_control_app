import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;

class ApiClient {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8081";
    }
    return "http://localhost:8081";
  }

  final String? _token;

  ApiClient({this._token});

  Map<String, String> _buildHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(extra: headers),
    );
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(extra: headers),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(extra: headers),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(extra: headers),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(extra: headers),
    );
  }
}

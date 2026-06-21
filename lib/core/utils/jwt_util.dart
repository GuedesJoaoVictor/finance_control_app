import 'dart:convert';

class JwtClaims {
  final String? uuid;
  final String? cpf;
  final String? email;
  final String? name;
  final String? role;
  final int? exp;

  JwtClaims({
    this.uuid,
    this.cpf,
    this.email,
    this.name,
    this.role,
    this.exp,
  });

  bool get isExpired {
    if (exp == null) return false;
    return DateTime.now().millisecondsSinceEpoch > exp! * 1000;
  }

  factory JwtClaims.fromJson(Map<String, dynamic> json) {
    return JwtClaims(
      uuid: json['uuid'],
      cpf: json['cpf'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      exp: json['exp'],
    );
  }
}

class JwtDecoder {
  static JwtClaims? decode(String? token) {
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized.padRight(
        normalized.length + (4 - normalized.length % 4) % 4,
        '=',
      );

      final decoded = utf8.decode(base64.decode(padded));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return JwtClaims.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

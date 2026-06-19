class User {
  final int? id;
  final String? uuid;
  final String? email;
  final String? password;
  final String? name;
  final String? cpf;
  final String? role;

  User({
    this.id,
    this.uuid,
    this.name,
    this.email,
    this.password,
    this.cpf,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      uuid: json['uuid'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      cpf: json['cpf'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'email': email,
      'password': password,
      'cpf': cpf,
      'role': role,
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory User.fromMap(Map<String, dynamic> map) => User.fromJson(map);
}

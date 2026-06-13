class User {
  final int? id;
  final String? uuid;
  final String? email;
  final String? password;
  final String? name;
  final String? cpf;

  User({
    this.id,
    this.uuid,
    required this.name,
    required this.email,
    required this.password,
    required this.cpf,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'email': email,
      'password': password,
      'cpf': cpf,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      uuid: map['uuid'],
      name: map['name'],
      email: map['email'],
      password: map['email'],
      cpf: map['cpf'],
    );
  }
}

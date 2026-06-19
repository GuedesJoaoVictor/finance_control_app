class Bank {
  final int? id;
  final String? name;
  final String? type;
  final int? vinculoId;

  Bank({this.id, this.name, this.type, this.vinculoId});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      vinculoId: json['vinculoId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'vinculoId': vinculoId,
    };
  }
}

class UserBank {
  final int? id;
  final String? name;
  final double? totalAmount;
  final UserBankUser? user;
  final Bank? bank;

  UserBank({this.id, this.name, this.totalAmount, this.user, this.bank});

  factory UserBank.fromJson(Map<String, dynamic> json) {
    return UserBank(
      id: json['id'],
      name: json['name'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      user: json['user'] != null
          ? UserBankUser.fromJson(json['user'])
          : null,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'user': user?.toJson(),
      'bank': bank?.toJson(),
    };
  }
}

class UserBankUser {
  final int? id;
  final String? uuid;
  final String? email;
  final String? name;
  final String? cpf;

  UserBankUser({this.id, this.uuid, this.email, this.name, this.cpf});

  factory UserBankUser.fromJson(Map<String, dynamic> json) {
    return UserBankUser(
      id: json['id'],
      uuid: json['uuid'],
      email: json['email'],
      name: json['name'],
      cpf: json['cpf'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'email': email,
      'name': name,
      'cpf': cpf,
    };
  }
}

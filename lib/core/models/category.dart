import 'package:finance_control/core/models/user.dart';

class Category {
  final int? id;
  final String? name;
  final String? type;
  final User? user;

  Category({this.id, this.name, this.type, this.user});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'user': user?.toJson(),
    };
  }
}

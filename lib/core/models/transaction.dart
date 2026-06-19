import 'package:finance_control/core/models/bank.dart';
import 'package:finance_control/core/models/category.dart';
import 'package:finance_control/core/models/user.dart';

class Revenue {
  final int? id;
  final String? description;
  final double? value;
  final User? user;
  final Category? category;
  final Bank? bank;
  final String? receiptDate;

  Revenue({
    this.id,
    this.description,
    this.value,
    this.user,
    this.category,
    this.bank,
    this.receiptDate,
  });

  factory Revenue.fromJson(Map<String, dynamic> json) {
    return Revenue(
      id: json['id'],
      description: json['description'],
      value: (json['value'] as num?)?.toDouble(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
      receiptDate: json['receiptDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'user': user?.toJson(),
      'category': category?.toJson(),
      'bank': bank?.toJson(),
      'receiptDate': receiptDate,
    };
  }
}

class Expense {
  final int? id;
  final String? description;
  final double? value;
  final User? user;
  final Category? category;
  final Bank? bank;
  final String? expenseDate;

  Expense({
    this.id,
    this.description,
    this.value,
    this.user,
    this.category,
    this.bank,
    this.expenseDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      description: json['description'],
      value: (json['value'] as num?)?.toDouble(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
      expenseDate: json['expenseDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'user': user?.toJson(),
      'category': category?.toJson(),
      'bank': bank?.toJson(),
      'expenseDate': expenseDate,
    };
  }
}

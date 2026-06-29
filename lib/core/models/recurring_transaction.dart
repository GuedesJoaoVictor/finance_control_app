import 'package:finance_control/core/models/bank.dart';
import 'package:finance_control/core/models/category.dart';

class RecurringTransaction {
  final int? id;
  final String? description;
  final double? value;
  final String? type;
  final int? day;
  final bool? active;
  final Category? category;
  final Bank? bank;

  RecurringTransaction({
    this.id,
    this.description,
    this.value,
    this.type,
    this.day,
    this.active,
    this.category,
    this.bank,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'],
      description: json['description'],
      value: (json['value'] as num?)?.toDouble(),
      type: json['type'],
      day: json['day'],
      active: json['active'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'type': type,
      'day': day,
      'active': active,
      'category': category != null ? {'id': category!.id} : null,
      'bank': bank != null ? {'id': bank!.id} : null,
    };
  }
}

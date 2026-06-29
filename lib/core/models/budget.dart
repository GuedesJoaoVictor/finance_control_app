import 'package:finance_control/core/models/category.dart';

class Budget {
  final int? id;
  final Category? category;
  final int? month;
  final int? year;
  final double? limitAmount;
  final double? spent;

  Budget({this.id, this.category, this.month, this.year, this.limitAmount, this.spent});

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      month: json['month'],
      year: json['year'],
      limitAmount: (json['limitAmount'] as num?)?.toDouble(),
      spent: (json['spent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category?.toJson(),
      'month': month,
      'year': year,
      'limitAmount': limitAmount,
    };
  }
}

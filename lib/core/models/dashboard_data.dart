import 'package:finance_control/core/models/budget.dart';

class DashboardData {
  final double totalBalance;
  final double totalRevenues;
  final double totalExpenses;
  final List<BankBalance> bankBalances;
  final List<RecentTransaction> recentTransactions;
  final List<MonthlySummary> monthlySummary;
  final List<Budget> budgets;

  DashboardData({
    required this.totalBalance,
    required this.totalRevenues,
    required this.totalExpenses,
    required this.bankBalances,
    required this.recentTransactions,
    required this.monthlySummary,
    required this.budgets,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0,
      totalRevenues: (json['totalRevenues'] as num?)?.toDouble() ?? 0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0,
      bankBalances: (json['bankBalances'] as List<dynamic>?)
              ?.map((e) => BankBalance.fromJson(e))
              .toList() ??
          [],
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) => RecentTransaction.fromJson(e))
              .toList() ??
          [],
      monthlySummary: (json['monthlySummary'] as List<dynamic>?)
              ?.map((e) => MonthlySummary.fromJson(e))
              .toList() ??
          [],
      budgets: (json['budgets'] as List<dynamic>?)
              ?.map((e) => Budget.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MonthlySummary {
  final int year;
  final int month;
  final double revenues;
  final double expenses;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.revenues,
    required this.expenses,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      year: json['year'] as int,
      month: json['month'] as int,
      revenues: (json['revenues'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BankBalance {
  final int? bankId;
  final String? bankName;
  final double balance;

  BankBalance({this.bankId, this.bankName, required this.balance});

  factory BankBalance.fromJson(Map<String, dynamic> json) {
    return BankBalance(
      bankId: json['bankId'],
      bankName: json['bankName'],
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RecentTransaction {
  final int? id;
  final String? description;
  final double? value;
  final String? type;
  final String? date;
  final String? bankName;
  final String? categoryName;

  RecentTransaction({
    this.id,
    this.description,
    this.value,
    this.type,
    this.date,
    this.bankName,
    this.categoryName,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      id: json['id'],
      description: json['description'],
      value: (json['value'] as num?)?.toDouble(),
      type: json['type'],
      date: json['date'],
      bankName: json['bankName'],
      categoryName: json['categoryName'],
    );
  }
}

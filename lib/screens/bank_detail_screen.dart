import 'package:finance_control/core/models/bank.dart';
import 'package:finance_control/core/models/transaction.dart';
import 'package:finance_control/core/services/transaction_service.dart';
import 'package:flutter/material.dart';

class BankDetailScreen extends StatefulWidget {
  final String token;
  final Bank bank;

  const BankDetailScreen({super.key, required this.token, required this.bank});

  @override
  State<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends State<BankDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TransactionService _service;

  List<Revenue> _revenues = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;

  double get _totalRevenues =>
      _revenues.fold(0, (s, r) => s + (r.value ?? 0));
  double get _totalExpenses =>
      _expenses.fold(0, (s, e) => s + (e.value ?? 0));
  double get _balance => _totalRevenues - _totalExpenses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = TransactionService(widget.token);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getRevenuesByBank(widget.bank.id!),
        _service.getExpensesByBank(widget.bank.id!),
      ]);
      if (mounted) {
        setState(() {
          _revenues = results[0] as List<Revenue>;
          _expenses = results[1] as List<Expense>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _balance >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(widget.bank.name ?? 'Banco')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text('Saldo no ${widget.bank.name}',
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          '${_balance >= 0 ? '+' : ''}R\$ ${_balance.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat('Receitas',
                                _totalRevenues.toStringAsFixed(2), Colors.green),
                            _stat('Despesas',
                                _totalExpenses.toStringAsFixed(2), Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Receitas (${_revenues.length})'),
                    Tab(text: 'Despesas (${_expenses.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _list(_revenues, Icons.arrow_upward, Colors.green,
                          (r) => r.receiptDate ?? ''),
                      _list(_expenses, Icons.arrow_downward, Colors.red,
                          (e) => e.expenseDate ?? ''),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _list<T>(
    List<T> items,
    IconData icon,
    Color color,
    String Function(T) dateFn,
  ) {
    if (items.isEmpty) {
      return const Center(child: Text('Nenhuma transação'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final desc = item is Revenue
            ? item.description
            : (item is Expense ? item.description : '');
        final value = item is Revenue
            ? item.value
            : (item is Expense ? item.value : 0.0);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(desc ?? '-'),
            subtitle: Text(dateFn(item)),
            trailing: Text('R\$ ${value?.toStringAsFixed(2) ?? '0,00'}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
        );
      },
    );
  }
}

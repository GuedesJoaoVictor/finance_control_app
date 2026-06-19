import 'package:finance_control/core/models/transaction.dart';
import 'package:finance_control/core/services/transaction_service.dart';
import 'package:flutter/material.dart';

class TransactionsScreen extends StatefulWidget {
  final String token;
  final String userUuid;

  const TransactionsScreen(
      {super.key, required this.token, required this.userUuid});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TransactionService _service;

  List<Revenue> _revenues = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = TransactionService(widget.token);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getRevenuesByUser(widget.userUuid),
        _service.getExpensesByUser(widget.userUuid),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Receitas'),
              Tab(text: 'Despesas'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRevenueList(),
                      _buildExpenseList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueList() {
    if (_revenues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma receita',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        itemCount: _revenues.length,
        itemBuilder: (context, index) {
          final rev = _revenues[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.green),
              title: Text(rev.description ?? '-'),
              subtitle: Text(rev.receiptDate ?? ''),
              trailing: Text(
                'R\$ ${rev.value?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseList() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma despesa',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final exp = _expenses[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.red),
              title: Text(exp.description ?? '-'),
              subtitle: Text(exp.expenseDate ?? ''),
              trailing: Text(
                'R\$ ${exp.value?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

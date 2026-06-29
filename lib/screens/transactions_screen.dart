import 'package:finance_control/core/models/transaction.dart';
import 'package:finance_control/core/services/transaction_service.dart';
import 'package:finance_control/screens/add_transaction_form.dart';
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
  late final TransactionService _transactionService;

  List<Revenue> _allRevenues = [];
  List<Expense> _allExpenses = [];
  bool _isLoading = true;

  int? _filterMonth;
  int? _filterYear;

  static const _monthNames = [
    'Todos', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  List<Revenue> get _revenues {
    if (_filterMonth == null && _filterYear == null) return _allRevenues;
    return _allRevenues.where((r) {
      if (r.receiptDate == null) return false;
      final parts = r.receiptDate!.split('-');
      if (parts.length != 3) return false;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (_filterYear != null && year != _filterYear) return false;
      if (_filterMonth != null && month != _filterMonth) return false;
      return true;
    }).toList();
  }

  List<Expense> get _expenses {
    if (_filterMonth == null && _filterYear == null) return _allExpenses;
    return _allExpenses.where((e) {
      if (e.expenseDate == null) return false;
      final parts = e.expenseDate!.split('-');
      if (parts.length != 3) return false;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (_filterYear != null && year != _filterYear) return false;
      if (_filterMonth != null && month != _filterMonth) return false;
      return true;
    }).toList();
  }

  Set<int> get _availableYears {
    final years = <int>{};
    for (final r in _allRevenues) {
      if (r.receiptDate != null) {
        final parts = r.receiptDate!.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          if (y != null) years.add(y);
        }
      }
    }
    for (final e in _allExpenses) {
      if (e.expenseDate != null) {
        final parts = e.expenseDate!.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          if (y != null) years.add(y);
        }
      }
    }
    return years;
  }

  double get _totalRevenues =>
      _revenues.fold(0, (sum, r) => sum + (r.value ?? 0));
  double get _totalExpenses =>
      _expenses.fold(0, (sum, e) => sum + (e.value ?? 0));
  double get _balance => _totalRevenues - _totalExpenses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transactionService = TransactionService(widget.token);
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
        _transactionService.getRevenuesByUser(),
        _transactionService.getExpensesByUser(),
      ]);
      if (mounted) {
        setState(() {
          _allRevenues = results[0] as List<Revenue>;
          _allExpenses = results[1] as List<Expense>;
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

  void _clearFilters() {
    setState(() {
      _filterMonth = null;
      _filterYear = null;
    });
  }

  Future<void> _deleteRevenue(int id) async {
    try {
      await _transactionService.deleteRevenue(id);
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _deleteExpense(int id) async {
    try {
      await _transactionService.deleteExpense(id);
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _confirmDelete(bool isExpense, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir'),
        content: const Text('Tem certeza?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isExpense) {
                _deleteExpense(id);
              } else {
                _deleteRevenue(id);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddTransactionForm(
        token: widget.token,
        userUuid: widget.userUuid,
        onSaved: () {
          Navigator.pop(ctx);
          _loadAll();
        },
      ),
    );
  }

  void _showEditTransactionDialog({
    required bool isExpense,
    int? revenueId,
    int? expenseId,
    String? description,
    double? value,
    String? date,
    int? bankId,
    int? categoryId,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AddTransactionForm(
        token: widget.token,
        userUuid: widget.userUuid,
        onSaved: () {
          Navigator.pop(ctx);
          _loadAll();
        },
        editMode: true,
        isExpense: isExpense,
        revenueId: revenueId,
        expenseId: expenseId,
        initialDescription: description,
        initialValue: value,
        initialDate: date,
        initialBankId: bankId,
        initialCategoryId: categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                _buildBalanceCard(),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Receitas (${_format(_totalRevenues)})'),
                    Tab(text: 'Despesas (${_format(_totalExpenses)})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRevenueList(),
                      _buildExpenseList(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        tooltip: 'Adicionar Transação',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    final years = _availableYears.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _filterMonth,
              decoration: InputDecoration(
                labelText: 'Mês',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: List.generate(12, (i) => i + 1).map((m) {
                return DropdownMenuItem(value: m, child: Text(_monthNames[m]));
              }).toList(),
              onChanged: (v) => setState(() => _filterMonth = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _filterYear,
              decoration: InputDecoration(
                labelText: 'Ano',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: years.map((y) {
                return DropdownMenuItem(value: y, child: Text(y.toString()));
              }).toList(),
              onChanged: (v) => setState(() => _filterYear = v),
            ),
          ),
          if (_filterMonth != null || _filterYear != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Limpar filtros',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final color = _balance >= 0 ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          children: [
            const Text('Saldo Total',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '${_balance >= 0 ? '+' : ''}R\$ ${_format(_balance)}',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  'Receitas',
                  _format(_totalRevenues),
                  Colors.green,
                ),
                _buildMiniStat(
                  'Despesas',
                  _format(_totalExpenses),
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _format(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
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
              subtitle: Text(
                  '${rev.category?.name ?? '-'} • ${rev.receiptDate ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'R\$ ${rev.value?.toStringAsFixed(2) ?? '0,00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _showEditTransactionDialog(
                          isExpense: false,
                          revenueId: rev.id,
                          description: rev.description,
                          value: rev.value,
                          date: rev.receiptDate,
                          bankId: rev.bank?.id,
                          categoryId: rev.category?.id,
                        );
                      } else if (v == 'delete') {
                        _confirmDelete(false, rev.id!);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
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
              subtitle: Text(
                  '${exp.category?.name ?? '-'} • ${exp.expenseDate ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'R\$ ${exp.value?.toStringAsFixed(2) ?? '0,00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _showEditTransactionDialog(
                          isExpense: true,
                          expenseId: exp.id,
                          description: exp.description,
                          value: exp.value,
                          date: exp.expenseDate,
                          bankId: exp.bank?.id,
                          categoryId: exp.category?.id,
                        );
                      } else if (v == 'delete') {
                        _confirmDelete(true, exp.id!);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

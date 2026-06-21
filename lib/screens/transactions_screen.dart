import 'package:finance_control/core/models/bank.dart';
import 'package:finance_control/core/models/category.dart';
import 'package:finance_control/core/models/transaction.dart';
import 'package:finance_control/core/services/bank_service.dart';
import 'package:finance_control/core/services/category_service.dart';
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
  late final TransactionService _transactionService;

  List<Revenue> _revenues = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;

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
      builder: (ctx) => _AddTransactionForm(
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
      builder: (ctx) => _AddTransactionForm(
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

class _AddTransactionForm extends StatefulWidget {
  final String token;
  final String userUuid;
  final VoidCallback onSaved;

  final bool editMode;
  final bool isExpense;
  final int? revenueId;
  final int? expenseId;
  final String? initialDescription;
  final double? initialValue;
  final String? initialDate;
  final int? initialBankId;
  final int? initialCategoryId;

  const _AddTransactionForm({
    required this.token,
    required this.userUuid,
    required this.onSaved,
    this.editMode = false,
    this.isExpense = false,
    this.revenueId,
    this.expenseId,
    this.initialDescription,
    this.initialValue,
    this.initialDate,
    this.initialBankId,
    this.initialCategoryId,
  });

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _dateController = TextEditingController();

  late final BankService _bankService;
  late final CategoryService _categoryService;
  late final TransactionService _transactionService;

  bool _isExpense = false;
  List<Bank> _banks = [];
  List<Category> _categories = [];
  Bank? _selectedBank;
  Category? _selectedCategory;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpense;
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialValue != null) {
      _valueController.text = widget.initialValue.toString();
    }
    if (widget.initialDate != null) {
      _dateController.text = widget.initialDate!;
    }

    _bankService = BankService(widget.token);
    _categoryService = CategoryService(widget.token);
    _transactionService = TransactionService(widget.token);
    _loadFormData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    try {
      final results = await Future.wait([
        _bankService.getBanksByUser(),
        _categoryService.getCategoriesByUser(),
      ]);
      if (mounted) {
        setState(() {
          _banks = results[0] as List<Bank>;
          _categories = results[1] as List<Category>;
          _loadingData = false;

          if (widget.initialBankId != null) {
            _selectedBank = _banks.cast<Bank?>().firstWhere(
                  (b) => b?.id == widget.initialBankId,
                  orElse: () => null,
                );
          }
          if (widget.initialCategoryId != null) {
            _selectedCategory = _categories.cast<Category?>().firstWhere(
                  (c) => c?.id == widget.initialCategoryId,
                  orElse: () => null,
                );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateTime.tryParse(_dateController.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      _dateController.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      'description': _descriptionController.text.trim(),
      'value': double.parse(_valueController.text.trim()),
      'category': {'id': _selectedCategory!.id},
      'bank': {'id': _selectedBank!.id},
      if (_isExpense)
        'expenseDate': _dateController.text
      else
        'receiptDate': _dateController.text,
    };

    try {
      if (widget.editMode) {
        if (_isExpense) {
          await _transactionService.updateExpense(widget.expenseId!, body);
        } else {
          await _transactionService.updateRevenue(widget.revenueId!, body);
        }
      } else {
        if (_isExpense) {
          await _transactionService.createExpense(body);
        } else {
          await _transactionService.createRevenue(body);
        }
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editMode;
    return AlertDialog(
      title: Text(
        isEditing
            ? (_isExpense ? 'Editar Despesa' : 'Editar Receita')
            : (_isExpense ? 'Nova Despesa' : 'Nova Receita'),
      ),
      content: _loadingData
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Receita')),
                        ButtonSegment(value: true, label: Text('Despesa')),
                      ],
                      selected: {_isExpense},
                      onSelectionChanged: (v) =>
                          setState(() => _isExpense = v.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe a descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o valor';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                        labelText: 'Data',
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Selecione a data';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Bank>(
                      initialValue: _selectedBank,
                      decoration: InputDecoration(
                        labelText: 'Banco',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _banks
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.name ?? 'Banco'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBank = v),
                      validator: (v) {
                        if (v == null) return 'Selecione um banco';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name ?? 'Categoria'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v),
                      validator: (v) {
                        if (v == null) return 'Selecione uma categoria';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loadingData ? null : _submit,
          child: Text(
            isEditing
                ? 'Salvar'
                : (_isExpense ? 'Criar Despesa' : 'Criar Receita'),
          ),
        ),
      ],
    );
  }
}

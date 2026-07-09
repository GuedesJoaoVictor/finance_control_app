import 'package:finance_control/core/models/budget.dart';
import 'package:finance_control/core/models/category.dart';
import 'package:finance_control/core/services/budget_service.dart';
import 'package:finance_control/core/services/category_service.dart';
import 'package:flutter/material.dart';

class BudgetsScreen extends StatefulWidget {
  final String token;

  const BudgetsScreen({super.key, required this.token});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final BudgetService _budgetService;
  List<Budget> _budgets = [];
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _budgetService = BudgetService(widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await _budgetService.getBudgets(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) setState(() => _budgets = budgets);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _BudgetForm(
        token: widget.token,
        month: _selectedMonth,
        year: _selectedYear,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  void _showEditDialog(Budget budget) {
    final controller = TextEditingController(text: budget.limitAmount?.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Orçamento'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Novo limite',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final value = double.tryParse(controller.text);
                if (value == null) return;
                await _budgetService.update(budget.id!, {'limitAmount': value});
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _load();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover'),
        content: Text('Remover orçamento de ${budget.category?.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _budgetService.delete(budget.id!);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Mês',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    items: List.generate(12, (i) => i + 1).map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                            'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'][m - 1]),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedMonth = v!);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Ano',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    items: List.generate(5, (i) => DateTime.now().year - 2 + i).map((y) {
                      return DropdownMenuItem(value: y, child: Text(y.toString()));
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedYear = v!);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _budgets.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          const Center(
                            child: Column(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Nenhum orçamento definido',
                                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _budgets.length,
                          itemBuilder: (_, i) {
                            final b = _budgets[i];
                            final spent = b.spent ?? 0;
                            final limit = b.limitAmount ?? 0;
                            final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0).toDouble() : 0.0;
                            final barColor = ratio < 0.5
                                ? Colors.green
                                : ratio < 0.8
                                    ? Colors.orange
                                    : Colors.red;

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(b.category?.name ?? '-',
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w600)),
                                        PopupMenuButton<String>(
                                          onSelected: (v) {
                                            if (v == 'edit') _showEditDialog(b);
                                            if (v == 'delete') _delete(b);
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                            const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Remover', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 10,
                                        backgroundColor: Colors.grey.shade300,
                                        valueColor: AlwaysStoppedAnimation(barColor),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'R\$ ${spent.toStringAsFixed(2)} / R\$ ${limit.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'Novo orçamento',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BudgetForm extends StatefulWidget {
  final String token;
  final int month;
  final int year;
  final VoidCallback onSaved;

  const _BudgetForm({
    required this.token,
    required this.month,
    required this.year,
    required this.onSaved,
  });

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  final _limitController = TextEditingController();
  late final BudgetService _budgetService;
  late final CategoryService _categoryService;
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _budgetService = BudgetService(widget.token);
    _categoryService = CategoryService(widget.token);
    _loadCategories();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getCategoriesByUser();
      if (mounted) {
        setState(() {
          _categories = cats.where((c) => c.type == 'DESPESA').toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null || _limitController.text.isEmpty) return;
    final limit = double.tryParse(_limitController.text);
    if (limit == null || limit <= 0) return;

    setState(() => _submitting = true);
    try {
      await _budgetService.create(Budget(
        category: _selectedCategory,
        month: widget.month,
        year: widget.year,
        limitAmount: limit,
      ));
      _limitController.clear();
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Orçamento'),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? '-'))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Limite mensal',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: (_loading || _submitting) ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }
}

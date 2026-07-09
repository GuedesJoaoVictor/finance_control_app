import 'package:finance_control/core/models/bank.dart';
import 'package:finance_control/core/models/category.dart';
import 'package:finance_control/core/models/recurring_transaction.dart';
import 'package:finance_control/core/services/bank_service.dart';
import 'package:finance_control/core/services/category_service.dart';
import 'package:finance_control/core/services/recurring_transaction_service.dart';
import 'package:flutter/material.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  final String token;

  const RecurringTransactionsScreen({super.key, required this.token});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  late final RecurringTransactionService _service;
  List<RecurringTransaction> _items = [];
  bool _isLoading = true;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _service = RecurringTransactionService(widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.findAll();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForm([RecurringTransaction? existing]) {
    showDialog(
      context: context,
      builder: (ctx) => _RecurringForm(
        token: widget.token,
        existing: existing,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  Future<void> _toggleActive(RecurringTransaction rt) async {
    try {
      await _service.update(rt.id!, {'active': !(rt.active ?? true)});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _apply() async {
    final now = DateTime.now();
    final monthCtl = TextEditingController(text: now.month.toString());
    final yearCtl = TextEditingController(text: now.year.toString());
    final applied = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aplicar Recorrentes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cria as transações reais para o mês:'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: monthCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mês',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: yearCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ano',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (applied != true) return;

    final month = int.tryParse(monthCtl.text);
    final year = int.tryParse(yearCtl.text);
    if (month == null || year == null) return;

    setState(() => _applying = true);
    try {
      final count = await _service.apply(month, year);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count transações criadas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _delete(RecurringTransaction rt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover'),
        content: Text('Remover "${rt.description}"?'),
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
        await _service.delete(rt.id!);
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
      appBar: AppBar(
        title: const Text('Recorrentes'),
        actions: [
          if (_applying)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.playlist_add_check),
              onPressed: _apply,
              tooltip: 'Aplicar ao mês',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.repeat, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma transação recorrente',
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
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final rt = _items[i];
                      final isRevenue = rt.type == 'RECEITA';
                      final color = isRevenue ? Colors.green : Colors.red;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Switch(
                            value: rt.active ?? true,
                            onChanged: (_) => _toggleActive(rt),
                            activeColor: color,
                          ),
                          title: Text(rt.description ?? '-',
                              style: TextStyle(
                                decoration: (rt.active ?? true) ? null : TextDecoration.lineThrough,
                                color: (rt.active ?? true) ? null : Colors.grey,
                              )),
                          subtitle: Text(
                            '${rt.category?.name ?? '-'} • ${rt.bank?.name ?? '-'} • Dia ${rt.day}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'R\$ ${rt.value?.toStringAsFixed(2) ?? '0,00'}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: color),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _showForm(rt);
                                  if (v == 'delete') _delete(rt);
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
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        tooltip: 'Nova recorrente',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecurringForm extends StatefulWidget {
  final String token;
  final RecurringTransaction? existing;
  final VoidCallback onSaved;

  const _RecurringForm({
    required this.token,
    this.existing,
    required this.onSaved,
  });

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _dayController = TextEditingController();
  late final RecurringTransactionService _service;
  late final BankService _bankService;
  late final CategoryService _categoryService;
  String _type = 'DESPESA';
  List<Bank> _banks = [];
  List<Category> _categories = [];
  Bank? _selectedBank;
  Category? _selectedCategory;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = RecurringTransactionService(widget.token);
    _bankService = BankService(widget.token);
    _categoryService = CategoryService(widget.token);
    if (widget.existing != null) {
      final e = widget.existing!;
      _descriptionController.text = e.description ?? '';
      _valueController.text = e.value.toString();
      _dayController.text = e.day.toString();
      _type = e.type ?? 'DESPESA';
    }
    _loadFormData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _dayController.dispose();
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
          _loading = false;

          if (widget.existing != null) {
            _selectedBank = _banks.cast<Bank?>().firstWhere(
                  (b) => b?.id == widget.existing!.bank?.id,
                  orElse: () => null,
                );
            _selectedCategory = _categories.cast<Category?>().firstWhere(
                  (c) => c?.id == widget.existing!.category?.id,
                  orElse: () => null,
                );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_descriptionController.text.isEmpty ||
        _valueController.text.isEmpty ||
        _dayController.text.isEmpty ||
        _selectedBank == null ||
        _selectedCategory == null) return;

    final value = double.tryParse(_valueController.text);
    final day = int.tryParse(_dayController.text);
    if (value == null || day == null || day < 1 || day > 31) return;

    final body = {
      'description': _descriptionController.text.trim(),
      'value': value,
      'type': _type,
      'day': day,
      'category': {'id': _selectedCategory!.id},
      'bank': {'id': _selectedBank!.id},
    };

    setState(() => _submitting = true);
    try {
      if (widget.existing != null) {
        await _service.update(widget.existing!.id!, body);
      } else {
        body['active'] = true;
        await _service.create(RecurringTransaction(
          description: body['description'] as String?,
          value: body['value'] as double?,
          type: body['type'] as String?,
          day: body['day'] as int?,
          category: _selectedCategory,
          bank: _selectedBank,
        ));
      }
      _descriptionController.clear();
      _valueController.clear();
      _dayController.clear();
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
      title: Text(widget.existing != null ? 'Editar Recorrente' : 'Nova Recorrente'),
      content: _loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'RECEITA', label: Text('Receita')),
                      ButtonSegment(value: 'DESPESA', label: Text('Despesa')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (v) => setState(() => _type = v.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dayController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Dia do vencimento',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Bank>(
                    value: _selectedBank,
                    decoration: InputDecoration(
                      labelText: 'Banco',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _banks
                        .map((b) => DropdownMenuItem(value: b, child: Text(b.name ?? 'Banco')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBank = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? 'Categoria')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ],
              ),
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
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

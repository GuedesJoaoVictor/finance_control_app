import 'package:finance_control/core/models/bank.dart';
import 'package:finance_control/core/models/category.dart';
import 'package:finance_control/core/services/bank_service.dart';
import 'package:finance_control/core/services/category_service.dart';
import 'package:finance_control/core/services/transaction_service.dart';
import 'package:flutter/material.dart';

class AddTransactionForm extends StatefulWidget {
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

  const AddTransactionForm({
    super.key,
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
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
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
  bool _submitting = false;

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

    setState(() => _submitting = true);

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
        setState(() => _submitting = false);
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
            onPressed: (_loadingData || _submitting) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isEditing
                        ? 'Salvar'
                        : (_isExpense ? 'Criar Despesa' : 'Criar Receita'),
                  ),
          ),
      ],
    );
  }
}

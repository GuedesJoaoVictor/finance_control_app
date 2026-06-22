import 'package:finance_control/core/models/bank.dart';
import 'package:finance_control/core/services/bank_service.dart';
import 'package:finance_control/screens/bank_detail_screen.dart';
import 'package:flutter/material.dart';

class BanksScreen extends StatefulWidget {
  final String token;
  final String userUuid;

  const BanksScreen({super.key, required this.token, required this.userUuid});

  @override
  State<BanksScreen> createState() => _BanksScreenState();
}

class _BanksScreenState extends State<BanksScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  int _bankId = 1;
  List<Bank> _banks = [];
  bool _isLoading = true;

  late final BankService _service;

  @override
  void initState() {
    super.initState();
    _service = BankService(widget.token);
    _loadBanks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() => _isLoading = true);
    try {
      final banks = await _service.getBanksByUser();
      if (mounted) setState(() => _banks = banks);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLinkDialog() async {
    _isLoading = true;
    final banks = await _service.getAvailableBanks(widget.userUuid);
    _isLoading = false;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vincular Banco'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da conta'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Saldo inicial'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: DropdownMenu(
                label: const Text('Banco'),
                initialSelection: _bankId,
                dropdownMenuEntries: banks
                    .map(
                      (bank) => DropdownMenuEntry(
                        value: bank.id,
                        label: bank.name ?? 'Banco',
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  setState(() => _bankId = value!);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.linkBankToUser(
                  widget.userUuid,
                  _bankId,
                  _nameController.text,
                  double.parse(_amountController.text),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadBanks();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  Future<void> _unlinkBank(int vinculoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular Banco'),
        content: const Text(
          'Todas as transações deste banco serão removidas. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.unlinkBank(vinculoId);
      _loadBanks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banco removido com sucesso')),
        );
      }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBanks,
        child: _banks.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.account_balance,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum banco vinculado',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _banks.length,
                itemBuilder: (context, index) {
                  final bank = _banks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.account_balance),
                      title: Text(bank.name ?? 'Banco'),
                      subtitle: Text('Tipo: ${bank.type ?? '-'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_right),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'delete') {
                                _unlinkBank(bank.vinculoId!);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Remover',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BankDetailScreen(
                              token: widget.token,
                              bank: bank,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLinkDialog,
        tooltip: 'Vincular banco',
        child: const Icon(Icons.add),
      ),
    );
  }
}

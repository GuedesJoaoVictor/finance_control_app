import 'package:finance_control/core/auth/auth_service.dart';
import 'package:finance_control/core/models/budget.dart';
import 'package:finance_control/core/models/dashboard_data.dart';
import 'package:finance_control/core/services/dashboard_service.dart';
import 'package:finance_control/core/theme/theme_provider.dart';
import 'package:finance_control/screens/add_transaction_form.dart';
import 'package:finance_control/screens/budgets_screen.dart';
import 'package:finance_control/screens/banks_screen.dart';
import 'package:finance_control/screens/categories_screen.dart';
import 'package:finance_control/screens/login_screen.dart';
import 'package:finance_control/screens/profile_screen.dart';
import 'package:finance_control/screens/recurring_transactions_screen.dart';
import 'package:finance_control/screens/transactions_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeProvider? themeProvider;

  const HomeScreen({super.key, required this.authService, this.themeProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final token = widget.authService.token!;
    final uuid = widget.authService.user?.uuid ?? '';
    _screens = [
      _DashboardContent(
        token: token,
        uuid: uuid,
        onNavigate: (tab) => setState(() => _currentIndex = tab),
      ),
      BanksScreen(token: token, userUuid: uuid),
      CategoriesScreen(token: token, userUuid: uuid),
      TransactionsScreen(token: token, userUuid: uuid),
    ];
  }

  void _logout() {
    widget.authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${user?.name ?? 'Usuário'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  authService: widget.authService,
                  themeProvider: widget.themeProvider,
                ),
              ),
            ),
            tooltip: 'Perfil',
          ),
          if (widget.themeProvider != null)
            IconButton(
              icon: Icon(
                widget.themeProvider!.isDark ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: widget.themeProvider!.toggle,
              tooltip: 'Alternar tema',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Bancos',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorias',
          ),
          NavigationDestination(
            icon: Icon(Icons.monetization_on_outlined),
            selectedIcon: Icon(Icons.monetization_on),
            label: 'Transações',
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final String token;
  final String uuid;
  final void Function(int tab)? onNavigate;

  const _DashboardContent({
    required this.token,
    required this.uuid,
    this.onNavigate,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late final DashboardService _service;
  DashboardData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = DashboardService(widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getDashboard();
      if (mounted) setState(() => _data = data);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_data == null) {
      return const Center(child: Text('Erro ao carregar dashboard'));
    }

    final data = _data!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(data),
          const SizedBox(height: 20),
          if (data.monthlySummary.isNotEmpty) ...[
            _buildMonthlyChart(data.monthlySummary),
            const SizedBox(height: 20),
          ],
          _buildBankBalances(data.bankBalances),
          const SizedBox(height: 20),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          if (data.budgets.isNotEmpty) ...[
            _buildBudgetsOverview(data.budgets),
            const SizedBox(height: 20),
          ],
          _buildRecentTransactions(data.recentTransactions),
        ],
      ),
    );
  }

  String _formatBalance(double value) {
    return '${value >= 0 ? '+' : ''}R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _format(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static const _monthNames = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  Widget _buildMonthlyChart(List<MonthlySummary> summary) {
    final reversed = summary.reversed.toList();
    final barWidth = reversed.length > 6 ? 8.0 : 14.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receitas vs Despesas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _legendDot(Colors.green, 'Receitas'),
                const SizedBox(width: 16),
                _legendDot(Colors.red, 'Despesas'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxChartValue(reversed),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final m = reversed[group.x.toInt()];
                        return BarTooltipItem(
                          '${_monthNames[m.month - 1]}/${m.year}\n${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= reversed.length) {
                            return const SizedBox.shrink();
                          }
                          final m = reversed[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _monthNames[m.month - 1],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: reversed.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: m.revenues,
                          color: Colors.green,
                          width: barWidth,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: m.expenses,
                          color: Colors.red,
                          width: barWidth,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  double _maxChartValue(List<MonthlySummary> summary) {
    double max = 0;
    for (final m in summary) {
      if (m.revenues > max) max = m.revenues;
      if (m.expenses > max) max = m.expenses;
    }
    if (max == 0) return 100;
    return (max * 1.2);
  }

  Widget _buildSummaryCards(DashboardData data) {
    final balanceColor = data.totalBalance >= 0 ? Colors.green : Colors.red;

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                const Text('Saldo Total',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                  Text(
                    _formatBalance(data.totalBalance),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Receitas',
                        _format(data.totalRevenues),
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMiniStat(
                        'Despesas',
                        _format(data.totalExpenses),
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBankBalances(List<BankBalance> banks) {
    if (banks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saldo por Banco',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...banks.map((bank) {
          final color = bank.balance >= 0 ? Colors.green : Colors.red;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.deepPurple),
              title: Text(bank.bankName ?? 'Banco'),
              trailing: Text(
                _formatBalance(bank.balance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ações Rápidas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
              Expanded(
                child: _buildActionButton(
                  'Transações',
                  Icons.monetization_on,
                  Colors.deepPurple,
                  () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AddTransactionForm(
                        token: widget.token,
                        userUuid: widget.uuid,
                        onSaved: () => Navigator.pop(ctx),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Orçamentos',
                Icons.account_balance_wallet,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetsScreen(token: widget.token),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Recorrentes',
                Icons.repeat,
                Colors.teal,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecurringTransactionsScreen(token: widget.token),
                    ),
                  );
                },
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
            const SizedBox(width: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetsOverview(List<Budget> budgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Orçamentos do Mês',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BudgetsScreen(token: widget.token),
                  ),
                );
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...budgets.take(3).map((b) {
          final spent = b.spent ?? 0;
          final limit = b.limitAmount ?? 0;
          final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0).toDouble() : 0.0;
          final barColor = ratio < 0.5
              ? Colors.green
              : ratio < 0.8 ? Colors.orange : Colors.red;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.category?.name ?? '-',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${spent.toStringAsFixed(2)} / R\$ ${limit.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<RecentTransaction> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text('Nenhuma transação recente',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transações Recentes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...transactions.map((t) {
          final isRevenue = t.type == 'RECEITA';
          final color = isRevenue ? Colors.green : Colors.red;
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              dense: true,
              leading: Icon(
                isRevenue ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 20,
              ),
              title: Text(t.description ?? '-',
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                '${t.categoryName ?? '-'} • ${t.bankName ?? '-'}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                'R\$ ${t.value?.toStringAsFixed(2) ?? '0,00'}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            ),
          );
        }),
      ],
    );
  }
}

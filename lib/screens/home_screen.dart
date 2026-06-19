import 'package:finance_control/core/auth/auth_service.dart';
import 'package:finance_control/screens/login_screen.dart';
import 'package:finance_control/screens/banks_screen.dart';
import 'package:finance_control/screens/categories_screen.dart';
import 'package:finance_control/screens/transactions_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;

  const HomeScreen({super.key, required this.authService});

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

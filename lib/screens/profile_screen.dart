import 'package:finance_control/core/auth/auth_service.dart';
import 'package:finance_control/core/services/user_service.dart';
import 'package:finance_control/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeProvider? themeProvider;

  const ProfileScreen({super.key, required this.authService, this.themeProvider});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserService _userService;
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _savingName = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _userService = UserService(widget.authService.token!);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _nameController.text = profile['name'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _saveName() async {
    setState(() => _savingName = true);
    try {
      await _userService.updateName(_nameController.text.trim());
      widget.authService.updateUserName(_nameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePassword() async {
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nova senha deve ter no mínimo 6 caracteres')),
      );
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await _userService.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.person, size: 64, color: Colors.deepPurple),
                        const SizedBox(height: 8),
                        Text(_profile?['name'] ?? '-',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(_profile?['email'] ?? '-',
                            style: const TextStyle(color: Colors.grey)),
                        Text('CPF: ${_profile?['cpf'] ?? '-'}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Editar Nome',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelText: 'Nome',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingName ? null : _saveName,
                    child: _savingName
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salvar'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Alterar Senha',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelText: 'Senha atual',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    labelText: 'Nova senha',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingPassword ? null : _savePassword,
                    child: _savingPassword
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Alterar Senha'),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.themeProvider != null) ...[
                  const Text('Aparência',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Tema escuro'),
                    subtitle: Text(widget.themeProvider!.isDark ? 'Ativo' : 'Inativo'),
                    value: widget.themeProvider!.isDark,
                    onChanged: (_) => widget.themeProvider!.toggle(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ],
              ],
            ),
    );
  }
}

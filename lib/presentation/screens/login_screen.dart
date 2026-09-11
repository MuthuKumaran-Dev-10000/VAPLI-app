import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/client_model.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';

import '../../core/utils/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  ClientModel? _selectedClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final adminCtrl = context.read<AdminController>();
      await adminCtrl.loadPublicClients();

      final lastClient = await SessionManager.getLastUsedClient();
      final lastUsername = await SessionManager.getLastUsedUsername();

      if (mounted) {
        setState(() {
          if (lastClient != null) {
            _selectedClient = lastClient;
            _clientSearchCtrl.text = lastClient.name;
            adminCtrl.selectClient(lastClient);
          }
          if (lastUsername != null && lastUsername.isNotEmpty) {
            _usernameCtrl.text = lastUsername;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _clientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final authCtrl = context.read<AuthController>();
    final adminCtrl = context.read<AdminController>();
    final clientToUse = _selectedClient ?? adminCtrl.selectedClient;

    final success = await authCtrl.login(
      _usernameCtrl.text,
      _passwordCtrl.text,
      selectedClient: clientToUse,
    );

    if (success && mounted) {
      if (_usernameCtrl.text.trim().isNotEmpty) {
        await SessionManager.saveLastUsedUsername(_usernameCtrl.text.trim());
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final query = _clientSearchCtrl.text.trim().toLowerCase();

    List<ClientModel> matchedClients = [];
    if (query.length >= 3) {
      matchedClients = adminCtrl.clients.where((c) {
        final n = c.name.toLowerCase();
        final id = c.id.toLowerCase();
        final db = c.dbKey.toLowerCase();
        return n.contains(query) || id.contains(query) || db.contains(query);
      }).toList();
      matchedClients.sort((a, b) => a.name.compareTo(b.name));
      debugPrint('[DEBUG_SEARCH] Query: "$query", Loaded Total Clients: ${adminCtrl.clients.length}, Matched Clients: ${matchedClients.map((c) => c.name).toList()}');
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(38),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.opacity,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VAPLI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lubrication Monitoring Platform',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Banner
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      if (auth.errorMessage == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withAlpha(31),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.danger.withAlpha(76)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Client Search TextField
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Client Organization',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (adminCtrl.isLoadingClients)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _clientSearchCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type 3+ chars to search client (e.g. Test)',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                      suffixIcon: _clientSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _clientSearchCtrl.clear();
                                  _selectedClient = null;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  // Autocomplete Dropdown List
                  if (query.length >= 3) ...[
                    const SizedBox(height: 6),
                    if (matchedClients.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primary.withAlpha(128)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: matchedClients.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                          itemBuilder: (ctx, idx) {
                            final c = matchedClients[idx];
                            final isSelected = _selectedClient?.id == c.id;
                            return ListTile(
                              dense: true,
                              tileColor: isSelected ? AppTheme.primary.withAlpha(25) : null,
                              leading: const Icon(Icons.business, color: AppTheme.primary, size: 20),
                              title: Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                c.description.isNotEmpty ? c.description : 'Code: ${c.dbKey}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                                  : const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 12),
                              onTap: () {
                                setState(() {
                                  _selectedClient = c;
                                  _clientSearchCtrl.text = c.name;
                                });
                                adminCtrl.selectClient(c);
                              },
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          'No client found matching "$query"',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                  if (_selectedClient != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Selected: ${_selectedClient!.name}',
                            style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Username Input
                  Text(
                    'Username',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _usernameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter username' : null,
                  ),
                  const SizedBox(height: 18),

                  // Password Input
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter password' : null,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 28),

                  // Sign In Button
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

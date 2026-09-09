import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/security/rbac.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';

class CreateUserScreen extends StatefulWidget {
  final String targetClientId;
  final String clientName;

  const CreateUserScreen({
    super.key,
    required this.targetClientId,
    required this.clientName,
  });

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'admin';
  bool _isLoading = false;
  final Map<String, bool> _privilegesMap = {};

  @override
  void initState() {
    super.initState();
    _applyDefaultRolePrivileges('admin');
  }

  void _applyDefaultRolePrivileges(String role) {
    _privilegesMap.clear();
    for (final key in RBAC.allPrivileges.keys) {
      if (role == 'admin') {
        // For Client Admin: enable all privileges EXCEPT create_client and view_admin_clients
        if (key == RBAC.pCreateClient || key == RBAC.pViewAdminClients) {
          _privilegesMap[key] = false;
        } else {
          _privilegesMap[key] = true;
        }
      } else if (role == 'super admin') {
        _privilegesMap[key] = true;
      } else {
        // Standard User
        _privilegesMap[key] = false;
      }
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final adminCtrl = context.read<AdminController>();

    final success = await adminCtrl.createUser(
      username: _usernameCtrl.text,
      fullName: _nameCtrl.text,
      password: _passwordCtrl.text,
      role: _selectedRole,
      clientIds: [widget.targetClientId],
      email: _emailCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim().isNotEmpty ? _mobileCtrl.text.trim() : null,
      address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      privileges: _privilegesMap,
    );

    if (mounted) setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User "@${_usernameCtrl.text.trim()}" created successfully in ${widget.clientName}!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().currentUser;
    final isSuper = RBAC.isSuperAdmin(currentUser);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'New User for ${widget.clientName}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'User Profile Details',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Username is compulsory' : null,
                  ),
                  const SizedBox(height: 14),

                  // Full Name
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Full name is compulsory' : null,
                  ),
                  const SizedBox(height: 14),

                  // Email ID (compulsory)
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email address is compulsory';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Mobile No
                  TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Mobile No.',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.home_outlined, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Password must be min 6 characters' : null,
                  ),
                  const SizedBox(height: 20),

                  // User Type / Role Selection
                  Text(
                    'User Role Type',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'User Type',
                      prefixIcon: Icon(Icons.manage_accounts_outlined, color: AppTheme.textSecondary),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'admin', child: Text('Client Admin')),
                      const DropdownMenuItem(value: 'user', child: Text('Standard Operational User')),
                      if (isSuper)
                        const DropdownMenuItem(value: 'super admin', child: Text('Super Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRole = val;
                          _applyDefaultRolePrivileges(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Privileges Section Below User Type (Shrunken / Click to Expand)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        leading: const Icon(Icons.security, color: AppTheme.primary, size: 20),
                        title: Text(
                          'User Privileges & Permissions',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          '${_privilegesMap.values.where((v) => v).length} of ${RBAC.allPrivileges.length} enabled (Tap to expand/edit)',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        children: [
                          const Divider(height: 1, color: AppTheme.border),
                          const SizedBox(height: 8),
                          ...RBAC.allPrivileges.entries.map((entry) {
                            final isChecked = _privilegesMap[entry.key] ?? false;
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppTheme.primary,
                              title: Text(entry.value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                              subtitle: Text(entry.key, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  _privilegesMap[entry.key] = val ?? false;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCreateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Create User Account',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
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

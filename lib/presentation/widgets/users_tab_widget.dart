import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/security/rbac.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';

import '../screens/user_form_screen.dart';

class UsersTabWidget extends StatefulWidget {
  const UsersTabWidget({super.key});

  @override
  State<UsersTabWidget> createState() => _UsersTabWidgetState();
}

class _UsersTabWidgetState extends State<UsersTabWidget> {
  ClientGroupedUsers? _selectedGroup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminController>().loadUsers();
      }
    });
  }





  void _showCustomPermissionsDialog(UserModel userTarget) {
    final privilegesMap = Map<String, bool>.from(userTarget.privileges);
    final adminCtrl = context.read<AdminController>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.security, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom Permissions: @${userTarget.username}',
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: RBAC.allPrivileges.entries.map((entry) {
                    final isChecked = privilegesMap[entry.key] ?? false;
                    return CheckboxListTile(
                      dense: true,
                      activeColor: AppTheme.primary,
                      title: Text(entry.value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          privilegesMap[entry.key] = val ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await adminCtrl.updateUser(
                    id: userTarget.id,
                    privileges: privilegesMap,
                  );
                  if (success && dialogContext.mounted) {
                    userTarget.privileges.clear();
                    userTarget.privileges.addAll(privilegesMap);
                    Navigator.pop(dialogContext);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Permissions saved for @${userTarget.username}')),
                    );
                  }
                },
                child: const Text('Save Permissions'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(String userId, String username) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Revoke / Delete User',
          style: GoogleFonts.outfit(color: AppTheme.danger, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to revoke access for "$username"?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final adminCtrl = context.read<AdminController>();
              final success = await adminCtrl.deleteUser(userId);
              if (success && dialogContext.mounted) {
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  SnackBar(content: Text('User "$username" revoked.')),
                );
              }
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().currentUser;
    final canCreate = RBAC.can(currentUser, RBAC.pCreateUsers);
    final adminCtrl = context.watch<AdminController>();

    if (adminCtrl.isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    // LEVEL 2: DRILLDOWN INTO SELECTED CLIENT FOLDER
    if (_selectedGroup != null) {
      // Find latest group data from controller
      final currentGroup = adminCtrl.groupedUsers.firstWhere(
        (g) => g.client.id == _selectedGroup!.client.id,
        orElse: () => _selectedGroup!,
      );

      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                backgroundColor: AppTheme.primary,
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserFormScreen(
                        targetClientId: currentGroup.client.id,
                        clientName: currentGroup.client.name,
                      ),
                    ),
                  );
                  if (res == true && mounted) {
                    if (context.mounted) {
                      context.read<AdminController>().loadUsers();
                    }
                  }
                },
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  'New User',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    tooltip: 'Back to Client Organizations',
                    onPressed: () => setState(() => _selectedGroup = null),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentGroup.client.name,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'User Accounts Folder Scope',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: currentGroup.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_off_outlined, size: 48, color: AppTheme.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'No Users in ${currentGroup.client.name}',
                              style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: currentGroup.users.length,
                        itemBuilder: (ctx, idx) {
                          final u = currentGroup.users[idx];
                          final isSuperUser = u.roleRank == 1 || u.role == 'super admin';
                          final isAdminUser = u.roleRank == 2 || u.role == 'admin';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSuperUser
                                    ? AppTheme.primary.withAlpha(51)
                                    : isAdminUser
                                        ? AppTheme.accent.withAlpha(51)
                                        : AppTheme.surface,
                                child: Icon(
                                  isSuperUser
                                      ? Icons.security
                                      : isAdminUser
                                          ? Icons.admin_panel_settings
                                          : Icons.person,
                                  color: isSuperUser
                                      ? AppTheme.primary
                                      : isAdminUser
                                          ? AppTheme.accent
                                          : AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                u.fullName.isNotEmpty ? u.fullName : u.username,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '@${u.username} • Role: ${u.role.toUpperCase()}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.security, color: AppTheme.primary, size: 20),
                                    tooltip: 'Custom Permissions',
                                    onPressed: () => _showCustomPermissionsDialog(u),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppTheme.accent, size: 20),
                                    tooltip: 'Edit User Profile',
                                    onPressed: () async {
                                      final res = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserFormScreen(
                                            targetClientId: currentGroup.client.id,
                                            clientName: currentGroup.client.name,
                                            userToEdit: u,
                                          ),
                                        ),
                                      );
                                      if (res == true && mounted && context.mounted) {
                                        context.read<AdminController>().loadUsers();
                                      }
                                    },
                                  ),
                                  if (currentUser != null &&
                                      currentUser.roleRank < u.roleRank &&
                                      currentUser.id != u.id)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                                      tooltip: 'Revoke Access',
                                      onPressed: () => _confirmDeleteUser(u.id, u.username),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    }

    // LEVEL 1: CLIENT ORGANIZATIONS LIST (FOLDER LEVEL)
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Accounts by Client Scope',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a client folder below to manage its users and custom permissions.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: adminCtrl.groupedUsers.isEmpty
                ? Center(
                    child: Text(
                      'No Client Folders Found',
                      style: GoogleFonts.outfit(fontSize: 18, color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: adminCtrl.groupedUsers.length,
                    itemBuilder: (ctx, gIdx) {
                      final group = adminCtrl.groupedUsers[gIdx];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(38),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.folder_shared_outlined, color: AppTheme.primary, size: 24),
                          ),
                          title: Text(
                            group.client.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Client Code: ${group.client.dbKey}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(
                                  '${group.users.length} Users',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedGroup = group;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

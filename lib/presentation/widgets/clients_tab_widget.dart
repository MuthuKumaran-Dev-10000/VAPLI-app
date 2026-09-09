import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/security/rbac.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../screens/client_form_screen.dart';

class ClientsTabWidget extends StatefulWidget {
  const ClientsTabWidget({super.key});

  @override
  State<ClientsTabWidget> createState() => _ClientsTabWidgetState();
}

class _ClientsTabWidgetState extends State<ClientsTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminController>().loadClients();
      }
    });
  }

  void _confirmDeleteClient(String clientId, String clientName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Client',
          style: GoogleFonts.outfit(color: AppTheme.danger, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete client "$clientName"? This action cannot be undone.',
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
              final success = await adminCtrl.deleteClient(clientId);
              if (success && dialogContext.mounted) {
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  SnackBar(content: Text('Client "$clientName" deleted.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final canCreate = RBAC.can(user, RBAC.pCreateClient);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                );
                if (res == true && mounted && context.mounted) {
                  context.read<AdminController>().loadClients();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'New Client',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organizations & Clients',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Consumer<AdminController>(
                builder: (context, adminCtrl, _) {
                  if (adminCtrl.isLoadingClients) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }

                  if (adminCtrl.clients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business_outlined, size: 48, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No Clients Found',
                            style: GoogleFonts.outfit(fontSize: 18, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: adminCtrl.clients.length,
                    itemBuilder: (ctx, index) {
                      final client = adminCtrl.clients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withAlpha(38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.domain, color: AppTheme.accent),
                          ),
                          title: Text(
                            client.name,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'DB Key: ${client.dbKey} • Created: ${client.createdAt.split("T").first}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                                tooltip: 'Edit Client',
                                onPressed: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ClientFormScreen(clientToEdit: client),
                                    ),
                                  );
                                  if (res == true && mounted && context.mounted) {
                                    context.read<AdminController>().loadClients();
                                  }
                                },
                              ),
                              if (RBAC.isSuperAdmin(user))
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                                  tooltip: 'Delete Client',
                                  onPressed: () => _confirmDeleteClient(client.id, client.name),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/security/rbac.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../../features/tanks/presentation/pages/tank_browser_screen.dart';
import '../widgets/audit_logs_tab_widget.dart';
import '../widgets/clients_tab_widget.dart';
import '../widgets/placeholder_tab_widget.dart';
import '../widgets/users_tab_widget.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirm Sign Out',
          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to end your current session?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthController>().logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().currentUser;
    final isSuper = RBAC.isSuperAdmin(currentUser);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuper
                      ? AppTheme.primary.withAlpha(51)
                      : AppTheme.accent.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSuper ? AppTheme.primary : AppTheme.accent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuper ? Icons.security : Icons.person_outline,
                      size: 14,
                      color: isSuper ? AppTheme.primary : AppTheme.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${currentUser.username} (${currentUser.role.toUpperCase()})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSuper ? AppTheme.primary : AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.danger),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSuper ? 94 : 48),
          child: Column(
            children: [
              if (isSuper)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Consumer<AdminController>(
                        builder: (context, adminCtrl, _) {
                          return DropdownButtonFormField<String>(
                            initialValue: adminCtrl.selectedClient?.id,
                            isExpanded: true,
                            dropdownColor: AppTheme.card,
                            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Switch Client',
                              border: OutlineInputBorder(),
                            ),
                            items: adminCtrl.clients.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (String? clientId) {
                              if (clientId != null) {
                                final match = adminCtrl.clients.firstWhere((c) => c.id == clientId);
                                adminCtrl.selectClient(match);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.water_drop), text: 'Assets'),
                  Tab(icon: Icon(Icons.domain), text: 'Clients'),
                  Tab(icon: Icon(Icons.people), text: 'Users'),
                  Tab(icon: Icon(Icons.settings), text: 'Settings'),
                  Tab(icon: Icon(Icons.receipt_long), text: 'Audit'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
      body: TabBarView(
        controller: _tabController,
        children: const [
          TankBrowserScreen(),
          ClientsTabWidget(),
          UsersTabWidget(),
          PlaceholderTabWidget(title: 'System & Parameter Configuration', icon: Icons.settings),
          AuditLogsTabWidget(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/security/rbac.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/placeholder_tab_widget.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openClientPicker(BuildContext context, AdminController adminCtrl) {
    final clients = adminCtrl.clients;
    if (clients.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Client Organization',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Divider(color: AppTheme.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: clients.length,
                  itemBuilder: (context, idx) {
                    final c = clients[idx];
                    final isSelected = adminCtrl.selectedClient?.id == c.id;
                    return ListTile(
                      leading: const Icon(Icons.apartment_outlined, color: AppTheme.primary),
                      title: Text(c.name, style: const TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text(c.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.success) : null,
                      onTap: () {
                        adminCtrl.selectClient(c);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
    final authCtrl = context.watch<AuthController>();
    final adminCtrl = context.watch<AdminController>();
    final currentUser = authCtrl.currentUser;
    final activeClient = adminCtrl.selectedClient;
    final isSuper = RBAC.isSuperAdmin(currentUser);
    final canOpenAdmin = RBAC.can(currentUser, RBAC.pOpenAdminPage);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.oil_barrel_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'VAPLI',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          if (activeClient != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_outlined, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 6),
                      Text(
                        activeClient.name,
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(31),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withAlpha(115)),
                  ),
                  child: Text(
                    currentUser.role.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  currentUser.fullName.split(' ').first,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          if (isSuper)
            IconButton(
              icon: const Icon(Icons.apartment_outlined, color: AppTheme.textSecondary),
              tooltip: 'Switch Client',
              onPressed: () => _openClientPicker(context, adminCtrl),
            ),
          if (canOpenAdmin)
            IconButton(
              icon: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppTheme.primary,
              ),
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppTheme.danger),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.input_outlined), text: 'Input'),
            Tab(icon: Icon(Icons.trending_up_outlined), text: 'Trends'),
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PlaceholderTabWidget(title: 'Tank Inspection & Readings Browser', icon: Icons.input_outlined),
          PlaceholderTabWidget(title: 'Trends & Analytics Reports', icon: Icons.trending_up_outlined),
          PlaceholderTabWidget(title: 'Operational Status Dashboard', icon: Icons.dashboard_outlined),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/security/rbac.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../../features/tanks/presentation/pages/tank_browser_screen.dart';
import '../widgets/audit_logs_tab_widget.dart';
import '../widgets/clients_tab_widget.dart';
import '../widgets/users_tab_widget.dart';
import 'login_screen.dart';

import '../../features/admin/presentation/pages/admin_settings_page.dart';

// Styling Palette (Obsidian / Copper)
const _kBg = Color(0xFF0C0D0F);
const _kSurface = Color(0xFF141618);
const _kCard = Color(0xFF1A1C20);
const _kBorder = Color(0xFF252830);
const _kCopper = Color(0xFFCB8C3E);
const _kText = Color(0xFFF0EEE9);
const _kSub = Color(0xFF8A8F9C);
const _kDanger = Color(0xFFEF4444);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabCount = 0;

  void _updateTabController(int count) {
    if (_tabController != null && _currentTabCount == count) return;
    _tabController?.dispose();
    _tabController = TabController(length: count, vsync: this);
    _tabController!.addListener(() {
      if (mounted) setState(() {});
    });
    _currentTabCount = count;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminCtrl = context.read<AdminController>();
      adminCtrl.loadClients();
      adminCtrl.loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _kBorder),
        ),
        title: Text(
          'Confirm Sign Out',
          style: GoogleFonts.outfit(color: _kText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to end your current session?',
          style: GoogleFonts.inter(color: _kSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDanger,
              foregroundColor: Colors.white,
            ),
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
    final canViewClients = isSuper || RBAC.can(currentUser, RBAC.pViewAdminClients);

    final tabCount = canViewClients ? 5 : 4;
    _updateTabController(tabCount);

    final tabs = [
      const Tab(icon: Icon(Icons.water_drop_outlined, size: 18), text: 'Assets'),
      if (canViewClients)
        const Tab(icon: Icon(Icons.domain_outlined, size: 18), text: 'Clients'),
      const Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
      const Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Settings'),
      const Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Audit'),
    ];

    final tabViews = [
      const TankBrowserScreen(),
      if (canViewClients) const ClientsTabWidget(),
      const UsersTabWidget(),
      const AdminSettingsPage(),
      const AuditLogsTabWidget(),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.outfit(
            color: _kText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: _kText),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        backgroundColor: _kSurface,
        elevation: 0,
        actions: [
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kCopper.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _kCopper.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSuper ? Icons.security : Icons.person_outline,
                      size: 14,
                      color: _kCopper,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSuper ? 'SUPER ADMIN' : (RBAC.isAdmin(currentUser) ? 'ADMIN' : 'USER'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _kCopper,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: _kDanger, size: 20),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSuper ? 124 : 72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSuper)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Consumer<AdminController>(
                        builder: (context, adminCtrl, _) {
                          final selectedId = adminCtrl.selectedClient?.id;
                          final hasValue = adminCtrl.clients.any((c) => c.id == selectedId);

                          return DropdownButtonFormField<String>(
                            value: hasValue ? selectedId : null,
                            isExpanded: true,
                            dropdownColor: _kCard,
                            style: GoogleFonts.inter(color: _kText, fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Switch Client (Super Admin Only)',
                              labelStyle: GoogleFonts.inter(color: _kCopper, fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: _kCopper.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: _kCopper, width: 1.5),
                              ),
                            ),
                            items: adminCtrl.clients.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(color: _kText, fontSize: 13),
                                ),
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
                indicatorColor: _kCopper,
                indicatorWeight: 3,
                labelColor: _kCopper,
                unselectedLabelColor: _kSub,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 12),
                tabs: tabs,
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: _kBg,
        child: TabBarView(
          controller: _tabController,
          children: tabViews,
        ),
      ),
    );
  }
}

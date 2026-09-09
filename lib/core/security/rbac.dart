import '../../data/models/user_model.dart';

class RBAC {
  static const String roleSuperAdmin = 'super admin';
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  static const String pOpenAdminPage = 'open_admin_page';
  static const String pViewAdminTanks = 'view_admin_tanks';
  static const String pViewAdminClients = 'view_admin_clients';
  static const String pViewAdminUsers = 'view_admin_users';
  static const String pViewSettings = 'view_settings';
  static const String pViewAuditLogs = 'view_audit_logs';

  static const String pCreateClient = 'create_client';
  static const String pCreateUsers = 'create_users';
  static const String pGrantUsers = 'grant_users';
  static const String pCreateTanks = 'create_tanks';
  static const String pDeleteTanks = 'delete_tanks';
  static const String pModifyTanks = 'modify_tanks';

  static const Map<String, String> allPrivileges = {
    pOpenAdminPage: 'Access Admin Module',
    pViewAdminTanks: 'View Assets Tab',
    pViewAdminClients: 'View Clients Tab',
    pViewAdminUsers: 'View Users Tab',
    pViewSettings: 'View Settings Tab',
    pViewAuditLogs: 'View Audit Logs Tab',
    pCreateClient: 'Create Clients',
    pCreateUsers: 'Create Users',
    pGrantUsers: 'Manage User Access',
    pCreateTanks: 'Create Tanks',
    pDeleteTanks: 'Delete Tanks',
    pModifyTanks: 'Modify Tank Structure',
  };

  static bool isSuperAdmin(UserModel? user) {
    if (user == null) return false;
    return user.roleRank == 1 || user.role.trim().toLowerCase() == roleSuperAdmin;
  }

  static bool isAdmin(UserModel? user) {
    if (user == null) return false;
    return isSuperAdmin(user) || user.roleRank == 2 || user.role.trim().toLowerCase() == roleAdmin;
  }

  static bool can(UserModel? user, String privilege) {
    if (user == null) return false;
    if (isSuperAdmin(user)) return true;
    final explicit = user.privileges[privilege];
    if (explicit != null) return explicit;
    return false;
  }
}

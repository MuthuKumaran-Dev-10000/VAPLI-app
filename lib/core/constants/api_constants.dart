class ApiConstants {
  static const String serverIp = '192.168.1.109';
  static const String serverPort = '8081';

  static String get baseUrl => 'http://$serverIp:$serverPort/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Clients
  static const String clients = '/clients';

  // Users
  static const String users = '/users';

  // Audit Logs
  static const String auditLogs = '/audit-logs';
}

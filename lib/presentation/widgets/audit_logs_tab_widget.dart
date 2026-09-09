import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/api_client.dart';

class AuditLogEntry {
  final int id;
  final String actorId;
  final String actorUsername;
  final String actorRole;
  final String? clientId;
  final String? clientName;
  final String entityType;
  final String? entityId;
  final String operation;
  final String outcome;
  final dynamic beforeState;
  final dynamic afterState;
  final dynamic details;
  final String timestamp;

  AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorUsername,
    required this.actorRole,
    this.clientId,
    this.clientName,
    required this.entityType,
    this.entityId,
    required this.operation,
    required this.outcome,
    this.beforeState,
    this.afterState,
    this.details,
    required this.timestamp,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      actorId: json['actor_id'] ?? json['actorId'] ?? '',
      actorUsername: json['actor_username'] ?? json['actorUsername'] ?? 'system',
      actorRole: json['actor_role'] ?? json['actorRole'] ?? 'user',
      clientId: json['client_id'] ?? json['clientId'],
      clientName: json['client_name'] ?? json['clientName'],
      entityType: json['entity_type'] ?? json['entityType'] ?? 'general',
      entityId: json['entity_id'] ?? json['entityId'],
      operation: json['operation'] ?? '',
      outcome: json['outcome'] ?? 'success',
      beforeState: json['before_state'] ?? json['beforeState'],
      afterState: json['after_state'] ?? json['afterState'],
      details: json['details'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class AuditLogsTabWidget extends StatefulWidget {
  const AuditLogsTabWidget({super.key});

  @override
  State<AuditLogsTabWidget> createState() => _AuditLogsTabWidgetState();
}

class _AuditLogsTabWidgetState extends State<AuditLogsTabWidget> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  List<AuditLogEntry> _logs = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  DateTimeRange? _dateRange;

  final List<String> _categories = [
    'All',
    'Users',
    'Clients',
    'Auth',
    'Readings',
    'Reports',
    'Settings'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, String>{};
      if (_selectedCategory != 'All') {
        queryParams['category'] = _selectedCategory.toLowerCase();
      }
      if (_searchCtrl.text.trim().isNotEmpty) {
        queryParams['search'] = _searchCtrl.text.trim();
      }
      if (_dateRange != null) {
        queryParams['startDate'] = _dateRange!.start.toIso8601String();
        queryParams['endDate'] = _dateRange!.end.toIso8601String();
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/audit-logs').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = await _apiClient.get(
        uri.path + (uri.hasQuery ? '?${uri.query}' : ''),
      );

      final List<dynamic> list = data['logs'] ?? [];
      setState(() {
        _logs = list.map((e) => AuditLogEntry.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _fetchAuditLogs();
    }
  }

  String _formatJson(dynamic val) {
    if (val == null) return 'None (Null)';
    if (val is String) return val;
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(val);
    } catch (_) {
      return val.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'System Audit Trail & State History',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.primary),
                tooltip: 'Refresh Audit Logs',
                onPressed: _fetchAuditLogs,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Track user actions, configuration changes, and state transitions (From -> To state).',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Filters Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by actor, operation, or ID...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetchAuditLogs();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _fetchAuditLogs(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dateRange != null ? AppTheme.primary : AppTheme.surface,
                  foregroundColor: _dateRange != null ? Colors.white : AppTheme.textPrimary,
                ),
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _dateRange == null
                      ? 'Date Range'
                      : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.danger, size: 18),
                  tooltip: 'Clear Date Range Filter',
                  onPressed: () {
                    setState(() => _dateRange = null);
                    _fetchAuditLogs();
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primary.withAlpha(76),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                      _fetchAuditLogs();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Log List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No Audit Log Records Found',
                          style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, idx) {
                          final log = _logs[idx];
                          final isSuper = log.actorRole.toLowerCase() == 'super admin';
                          final isSuccess = log.outcome == 'success';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSuccess ? AppTheme.primary.withAlpha(38) : AppTheme.danger.withAlpha(38),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSuccess ? Icons.verified_user_outlined : Icons.warning_amber_outlined,
                                  color: isSuccess ? AppTheme.primary : AppTheme.danger,
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    log.operation.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSuper ? AppTheme.primary.withAlpha(51) : AppTheme.accent.withAlpha(51),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      log.actorRole.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSuper ? AppTheme.primary : AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'By @${log.actorUsername} • Entity: ${log.entityType} (${log.entityId ?? 'N/A'}) • ${log.timestamp}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              children: [
                                const Divider(height: 1, color: AppTheme.border),
                                const SizedBox(height: 12),

                                // State Transition Box (From State -> To State)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // FROM STATE (Before)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.danger.withAlpha(20),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.danger.withAlpha(76)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.history, color: AppTheme.danger, size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'From State (Before)',
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: AppTheme.danger,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            SelectableText(
                                              _formatJson(log.beforeState),
                                              style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // TO STATE (After)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withAlpha(20),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.primary.withAlpha(76)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.update, color: AppTheme.primary, size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'To State (After)',
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            SelectableText(
                                              _formatJson(log.afterState),
                                              style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

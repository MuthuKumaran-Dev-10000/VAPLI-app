import 'package:flutter/material.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../tanks/data/models/tank_model.dart';
import '../../../tanks/data/models/tank_node_model.dart';
import '../../../tanks/data/repositories/tank_repository.dart';
import '../../../tanks/data/repositories/tank_tree_repository.dart';
import 'report_format_config_screen.dart';

class AdminSettingsPage extends StatefulWidget {
  final Future<void> Function({
    required bool noTimeout,
    required int minutes,
  })? onSettingsSaved;
  final bool canEdit;

  const AdminSettingsPage({
    super.key,
    this.onSettingsSaved,
    this.canEdit = true,
  });

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _loading = true;
  bool _noTimeout = false;
  int _minutes = 60;
  bool _saving = false;
  List<TankModel> _tanks = [];
  List<TankNode> _allNodes = [];
  String _clientName = 'Client';
  Map<String, List<TankModel>> _tanksByFolderPath = {};

  final _tankRepo = TankRepository();
  final _treeRepo = TankTreeRepository();

  bool _showInspectionValues = true;
  bool _showCompletedAlerts = true;
  bool _showActiveAlerts = true;
  bool _showInspectionCompliance = true;

  final _reportEmailsCtrl = TextEditingController();
  final _alertsEmailsCtrl = TextEditingController();
  final _missingTanksEmailsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reportEmailsCtrl.dispose();
    _alertsEmailsCtrl.dispose();
    _missingTanksEmailsCtrl.dispose();
    super.dispose();
  }

  Map<String, List<TankModel>> _buildTanksByFolderPath(
    List<TankModel> tanks,
    List<TankNode> allNodes,
    String clientName,
  ) {
    final Map<String, TankNode> nodeMapByTankId = {};
    final Map<String, TankNode> nodeMapById = {};
    for (final node in allNodes) {
      nodeMapById[node.id] = node;
      if (node.tankId != null && node.tankId!.isNotEmpty) {
        nodeMapByTankId[node.tankId!] = node;
      }
    }

    final Map<String, List<TankModel>> grouped = {};

    for (final tank in tanks) {
      TankNode? leafNode = nodeMapByTankId[tank.id] ?? nodeMapById[tank.id];
      if (leafNode == null) {
        try {
          leafNode = allNodes.firstWhere(
            (n) =>
                n.tankId == tank.id ||
                n.id == tank.id ||
                (n.isLeaf && n.name.toLowerCase() == tank.tankName.toLowerCase()) ||
                (n.tankId != null && n.tankId == tank.tankCode),
          );
        } catch (_) {}
      }

      final List<String> folderNames = [];

      if (leafNode != null) {
        String? parentId = leafNode.parentId;
        final Set<String> visited = {};
        while (parentId != null &&
            parentId.isNotEmpty &&
            parentId != 'null' &&
            !visited.contains(parentId)) {
          visited.add(parentId);
          final parentNode = nodeMapById[parentId];
          if (parentNode != null) {
            folderNames.add(parentNode.name);
            parentId = parentNode.parentId;
          } else {
            break;
          }
        }
      }

      final List<String> reversedFolderNames = folderNames.reversed.toList();

      String path;
      if (reversedFolderNames.isEmpty) {
        path = '$clientName/';
      } else {
        path = '$clientName / ${reversedFolderNames.join(' / ')} /';
      }

      grouped.putIfAbsent(path, () => []).add(tank);
    }

    return grouped;
  }

  Future<void> _load() async {
    final timeout = await AppSettingsService.getSessionTimeout();
    final tanks = await _tankRepo.getAllTanks();
    final allNodes = await _treeRepo.fetchAll();
    final activeClientName = await SessionManager.getActiveClientName();
    final clientName = (activeClientName != null && activeClientName.trim().isNotEmpty)
        ? activeClientName.trim()
        : 'Client';

    final dashSettings = await AppSettingsService.getDashboardDisplaySettings();

    final reportEmailsData = await AppSettingsService.getSetting('report_receivers');
    final alertsEmailsData = await AppSettingsService.getSetting('alerts_receivers');
    final missingTanksEmailsData = await AppSettingsService.getSetting('missing_tanks_receivers');

    String parseEmails(dynamic data) {
      if (data == null) return '';
      if (data is Map && data['emailids'] != null) {
        final val = data['emailids'];
        if (val is List) {
          return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).join(', ');
        }
        return val.toString();
      }
      if (data is List) {
        return data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).join(', ');
      }
      return data.toString();
    }

    final reportEmailsStr = parseEmails(reportEmailsData);
    final alertsEmailsStr = parseEmails(alertsEmailsData);
    final missingTanksEmailsStr = parseEmails(missingTanksEmailsData);

    final tanksByFolderPath = _buildTanksByFolderPath(tanks, allNodes, clientName);

    if (!mounted) return;
    setState(() {
      _noTimeout = timeout == null;
      _minutes = timeout?.inMinutes ?? 60;
      _tanks = tanks;
      _allNodes = allNodes;
      _clientName = clientName;
      _tanksByFolderPath = tanksByFolderPath;
      _showInspectionValues = dashSettings['show_inspection_values'] ?? true;
      _showCompletedAlerts = dashSettings['show_completed_alerts'] ?? true;
      _showActiveAlerts = dashSettings['show_active_alerts'] ?? true;
      _showInspectionCompliance = dashSettings['show_inspection_compliance'] ?? true;
      _reportEmailsCtrl.text = reportEmailsStr;
      _alertsEmailsCtrl.text = alertsEmailsStr;
      _missingTanksEmailsCtrl.text = missingTanksEmailsStr;
      _loading = false;
    });
  }

  String _freqLabel(TankModel t) {
    switch (t.inspectionFrequencyType) {
      case 'weekly_once':
        return 'Weekly once';
      case 'weekly_thrice':
        return 'Weekly thrice';
      case 'custom_days':
        return 'Custom (${t.inspectionFrequencyDays} day${t.inspectionFrequencyDays == 1 ? '' : 's'})';
      default:
        return 'Daily';
    }
  }

  Future<void> _setFreq(TankModel t, String v) async {
    int days = 1;
    if (v == 'weekly_once') days = 7;
    if (v == 'weekly_thrice') days = 2;
    if (v == 'custom_days') {
      final ctrl = TextEditingController(text: t.inspectionFrequencyDays.toString());
      final picked = await showDialog<int>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Custom days'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Days'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text.trim()) ?? 1),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (picked == null) return;
      days = picked < 1 ? 1 : picked;
    }
    await _tankRepo.updateInspectionFrequency(tankId: t.id, type: v, days: days);
    try {
      final freqSetting = await AppSettingsService.getSetting('tank_inspection_frequencies');
      final Map<String, dynamic> freqMap = freqSetting is Map ? Map<String, dynamic>.from(freqSetting) : {};
      freqMap[t.id] = {'type': v, 'days': days};
      await AppSettingsService.setSetting('tank_inspection_frequencies', freqMap);
    } catch (_) {}
    await _load();
  }

  Future<void> _saveEmailsSilent(String key, String rawText) async {
    final emails = rawText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    try {
      await AppSettingsService.setSetting(key, {'emailids': emails});
    } catch (_) {}
  }

  Future<void> _saveEmails(String key, String rawText) async {
    final emails = rawText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    try {
      await AppSettingsService.setSetting(key, {'emailids': emails});
      if (mounted) {
        if (key == 'report_receivers') {
          _reportEmailsCtrl.clear();
        } else if (key == 'alerts_receivers') {
          _alertsEmailsCtrl.clear();
        } else if (key == 'missing_tanks_receivers') {
          _missingTanksEmailsCtrl.clear();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emails saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save emails: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _viewEmails(String title, String key) async {
    final data = await AppSettingsService.getSetting(key);
    List<String> emails = [];
    if (data != null) {
      if (data is Map && data['emailids'] != null) {
        final val = data['emailids'];
        if (val is List) {
          emails = val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } else if (data is List) {
        emails = data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: emails.isEmpty
            ? const Text('No email addresses stored.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: emails.length,
                  itemBuilder: (ctx, idx) => ListTile(
                    leading: const Icon(Icons.email_outlined, color: Color(0xFFCB8C3E)),
                    title: Text(emails[idx]),
                    dense: true,
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSettingsField({
    required String label,
    required TextEditingController controller,
    required String settingKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'e.g. user1@email.com, user2@email.com',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                enabled: widget.canEdit,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Color(0xFFCB8C3E)),
              tooltip: 'View Emails',
              onPressed: () => _viewEmails(label, settingKey),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.save_outlined, color: Colors.blue),
              tooltip: 'Save',
              onPressed: widget.canEdit ? () => _saveEmails(settingKey, controller.text) : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AppSettingsService.setSessionTimeout(
      noTimeout: _noTimeout,
      minutes: _minutes,
    );
    await AppSettingsService.setDashboardDisplaySettings(
      showInspectionValues: _showInspectionValues,
      showCompletedAlerts: _showCompletedAlerts,
      showActiveAlerts: _showActiveAlerts,
      showInspectionCompliance: _showInspectionCompliance,
    );

    await _saveEmailsSilent('report_receivers', _reportEmailsCtrl.text);
    await _saveEmailsSilent('alerts_receivers', _alertsEmailsCtrl.text);
    await _saveEmailsSilent('missing_tanks_receivers', _missingTanksEmailsCtrl.text);

    _reportEmailsCtrl.clear();
    _alertsEmailsCtrl.clear();
    _missingTanksEmailsCtrl.clear();

    await widget.onSettingsSaved?.call(
      noTimeout: _noTimeout,
      minutes: _minutes,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('No Session Timeout'),
            value: _noTimeout,
            onChanged: widget.canEdit ? (v) => setState(() => _noTimeout = v) : null,
          ),
          const SizedBox(height: 8),
          if (!_noTimeout)
            DropdownButtonFormField<int>(
              value: _minutes,
              items: const [
                DropdownMenuItem(value: 60, child: Text('60 minutes')),
                DropdownMenuItem(value: 120, child: Text('120 minutes')),
                DropdownMenuItem(value: 240, child: Text('240 minutes')),
                DropdownMenuItem(value: 480, child: Text('480 minutes')),
                DropdownMenuItem(value: 720, child: Text('720 minutes')),
                DropdownMenuItem(value: 1440, child: Text('1 day')),
              ],
              onChanged: widget.canEdit
                  ? (v) => setState(() => _minutes = v ?? 60)
                  : null,
              disabledHint: Text('$_minutes minutes'),
              decoration: const InputDecoration(
                labelText: 'Session timeout',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Dashboard Display Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show Inspection Averages & Last Values'),
            subtitle: const Text('Populates AVG strip and tank stats cards'),
            value: _showInspectionValues,
            onChanged: widget.canEdit
                ? (v) => setState(() => _showInspectionValues = v)
                : null,
          ),
          SwitchListTile(
            title: const Text('Display Alerts (Not Completed)'),
            subtitle: const Text('Populates Active Alerts section'),
            value: _showActiveAlerts,
            onChanged: widget.canEdit
                ? (v) => setState(() => _showActiveAlerts = v)
                : null,
          ),
          SwitchListTile(
            title: const Text('Display Alerts (Completed)'),
            subtitle: const Text('Populates Completed Tasks section'),
            value: _showCompletedAlerts,
            onChanged: widget.canEdit
                ? (v) => setState(() => _showCompletedAlerts = v)
                : null,
          ),
          SwitchListTile(
            title: const Text('Display Inspection Compliance'),
            subtitle: const Text('Populates compliance checklist'),
            value: _showInspectionCompliance,
            onChanged: widget.canEdit
                ? (v) => setState(() => _showInspectionCompliance = v)
                : null,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportFormatConfigScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit_document),
            label: const Text('Modify Report Format'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCB8C3E),
              side: const BorderSide(color: Color(0xFFCB8C3E)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (widget.canEdit && !_saving) ? _save : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Email Automation Receivers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure email addresses for automated reports, active alerts, and missing tank schedules (separated by commas).',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildEmailSettingsField(
            label: 'Report Receivers',
            controller: _reportEmailsCtrl,
            settingKey: 'report_receivers',
          ),
          const SizedBox(height: 16),
          _buildEmailSettingsField(
            label: 'Alerts Receivers',
            controller: _alertsEmailsCtrl,
            settingKey: 'alerts_receivers',
          ),
          const SizedBox(height: 16),
          _buildEmailSettingsField(
            label: 'Missing Tanks Receivers',
            controller: _missingTanksEmailsCtrl,
            settingKey: 'missing_tanks_receivers',
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Tank Inspection Frequency',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (_tanksByFolderPath.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No active tanks found in database.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            )
          else
            ..._tanksByFolderPath.entries.expand((entry) {
              final folderPath = entry.key;
              final tankList = entry.value;
              return [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2E323A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 16, color: Color(0xFFCB8C3E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          folderPath,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFF0EEE9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...tankList.map((t) => Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ListTile(
                        dense: true,
                        title: Text('${t.tankName} (${t.tankCode})'),
                        subtitle: Text(_freqLabel(t)),
                        trailing: DropdownButton<String>(
                          value: t.inspectionFrequencyType,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly_once', child: Text('Weekly once')),
                            DropdownMenuItem(value: 'weekly_thrice', child: Text('Weekly thrice')),
                            DropdownMenuItem(value: 'custom_days', child: Text('Custom')),
                          ],
                          onChanged: (v) {
                            if (!widget.canEdit) return;
                            if (v == null) return;
                            _setFreq(t, v);
                          },
                        ),
                      ),
                    )),
              ];
            }),
        ],
      ),
    );
  }
}

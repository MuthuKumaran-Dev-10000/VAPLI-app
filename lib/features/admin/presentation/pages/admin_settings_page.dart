import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lubrication_indicator/core/services/app_settings_service.dart';
import 'package:lubrication_indicator/core/services/completion_proof_pin_service.dart';
import 'package:lubrication_indicator/core/services/email_receiver_settings.dart';
import 'package:lubrication_indicator/features/tanks/data/models/tank_model.dart';
import 'package:lubrication_indicator/features/tanks/data/repositories/tank_repository.dart';
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
  final _tankRepo = TankRepository();

  bool _showInspectionValues = true;
  bool _showCompletedAlerts = true;
  bool _showActiveAlerts = true;
  bool _showInspectionCompliance = true;
  final _completionProofPinCtrl = TextEditingController();
  bool _showCompletionPin = false;

  final _reportEmailsCtrl = TextEditingController();
  final _alertsEmailsCtrl = TextEditingController();
  final _missingTanksEmailsCtrl = TextEditingController();

  List<String> _reportEmailList = [];
  List<String> _alertsEmailList = [];
  List<String> _missingTanksEmailList = [];

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
    _completionProofPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final timeout = await AppSettingsService.getSessionTimeout();
    final tanks = await _tankRepo.getAllTanks();
    final dashSettings = await AppSettingsService.getDashboardDisplaySettings();

    List<String> reportEmails = [];
    List<String> alertsEmails = [];
    List<String> missingTanksEmails = [];
    try {
      reportEmails = await EmailReceiverSettings.loadEmails(EmailReceiverSettings.reportKey);
      alertsEmails = await EmailReceiverSettings.loadEmails(EmailReceiverSettings.alertsKey);
      missingTanksEmails =
          await EmailReceiverSettings.loadEmails(EmailReceiverSettings.missingTanksKey);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _noTimeout = timeout == null;
      _minutes = timeout?.inMinutes ?? 60;
      _tanks = tanks;
      _showInspectionValues = dashSettings['show_inspection_values'] ?? true;
      _showCompletedAlerts = dashSettings['show_completed_alerts'] ?? true;
      _showActiveAlerts = dashSettings['show_active_alerts'] ?? true;
      _showInspectionCompliance = dashSettings['show_inspection_compliance'] ?? true;
      _completionProofPinCtrl.text =
          dashSettings['completion_proof_pin']?.toString() ?? '';
      _reportEmailList = reportEmails;
      _alertsEmailList = alertsEmails;
      _missingTanksEmailList = missingTanksEmails;
      _reportEmailsCtrl.clear();
      _alertsEmailsCtrl.clear();
      _missingTanksEmailsCtrl.clear();
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
    await _load();
  }

  Future<void> _persistEmailList(String settingKey, List<String> emails) async {
    await EmailReceiverSettings.saveEmails(settingKey, emails);
  }

  Future<void> _saveEmailsForKey({
    required String label,
    required String settingKey,
    required TextEditingController controller,
    required List<String> currentList,
    required void Function(List<String>) onListUpdated,
  }) async {
    final merged = EmailReceiverSettings.mergeParsedInput(controller.text, currentList);
    if (merged.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add at least one email for $label')),
        );
      }
      return;
    }
    try {
      await _persistEmailList(settingKey, merged);
      if (!mounted) return;
      setState(() {
        onListUpdated(merged);
        controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label saved (${merged.length} address${merged.length == 1 ? '' : 'es'})')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save $label: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeEmail({
    required String label,
    required String settingKey,
    required List<String> currentList,
    required int index,
    required void Function(List<String>) onListUpdated,
  }) async {
    if (index < 0 || index >= currentList.length) return;
    final next = List<String>.from(currentList)..removeAt(index);
    try {
      await _persistEmailList(settingKey, next);
      if (!mounted) return;
      setState(() => onListUpdated(next));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $label: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _viewEmails(String title, List<String> emails) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: emails.isEmpty
            ? const Text('No email addresses stored.')
            : SizedBox(
                width: double.maxFinite,
                height: 280,
                child: ListView.builder(
                  itemCount: emails.length,
                  itemBuilder: (_, idx) => ListTile(
                    leading: const Icon(Icons.email_outlined, color: Color(0xFFCB8C3E)),
                    title: Text(emails[idx]),
                    dense: true,
                  ),
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildSavedEmailsList({
    required String settingKey,
    required String label,
    required List<String> emails,
    required void Function(List<String>) onListUpdated,
  }) {
    if (emails.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'No saved recipients yet.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 140),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        thumbVisibility: emails.length > 4,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: emails.length,
          itemBuilder: (_, idx) => ListTile(
            dense: true,
            title: Text(emails[idx], style: const TextStyle(fontSize: 13)),
            trailing: widget.canEdit
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove',
                    onPressed: () => _removeEmail(
                      label: label,
                      settingKey: settingKey,
                      currentList: emails,
                      index: idx,
                      onListUpdated: onListUpdated,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSettingsField({
    required String label,
    required String settingKey,
    required TextEditingController controller,
    required List<String> savedEmails,
    required void Function(List<String>) onListUpdated,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Add emails (comma-separated)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                enabled: widget.canEdit,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Color(0xFFCB8C3E)),
              tooltip: 'View all',
              onPressed: () => _viewEmails(label, savedEmails),
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined, color: Colors.blue),
              tooltip: 'Save',
              onPressed: widget.canEdit
                  ? () => _saveEmailsForKey(
                        label: label,
                        settingKey: settingKey,
                        controller: controller,
                        currentList: savedEmails,
                        onListUpdated: onListUpdated,
                      )
                  : null,
            ),
          ],
        ),
        _buildSavedEmailsList(
          settingKey: settingKey,
          label: label,
          emails: savedEmails,
          onListUpdated: onListUpdated,
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
      completionProofPin: _completionProofPinCtrl.text,
    );
    await CompletionProofPinService.refresh();

    try {
      if (_reportEmailsCtrl.text.trim().isNotEmpty) {
        final merged = EmailReceiverSettings.mergeParsedInput(
          _reportEmailsCtrl.text,
          _reportEmailList,
        );
        await _persistEmailList(EmailReceiverSettings.reportKey, merged);
        _reportEmailList = merged;
        _reportEmailsCtrl.clear();
      }
      if (_alertsEmailsCtrl.text.trim().isNotEmpty) {
        final merged = EmailReceiverSettings.mergeParsedInput(
          _alertsEmailsCtrl.text,
          _alertsEmailList,
        );
        await _persistEmailList(EmailReceiverSettings.alertsKey, merged);
        _alertsEmailList = merged;
        _alertsEmailsCtrl.clear();
      }
      if (_missingTanksEmailsCtrl.text.trim().isNotEmpty) {
        final merged = EmailReceiverSettings.mergeParsedInput(
          _missingTanksEmailsCtrl.text,
          _missingTanksEmailList,
        );
        await _persistEmailList(EmailReceiverSettings.missingTanksKey, merged);
        _missingTanksEmailList = merged;
        _missingTanksEmailsCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save email receivers: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

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
              // Disabled for view-only settings privilege.
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
          const SizedBox(height: 12),
          TextField(
            controller: _completionProofPinCtrl,
            enabled: widget.canEdit,
            obscureText: !_showCompletionPin,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Task completion PIN (no-photo bypass)',
              hintText: '4–8 digit PIN for supervisors',
              helperText:
                  'Stored per client in client_settings → dashboard_display. '
                  'Leave empty to disable bypass.',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _showCompletionPin ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _showCompletionPin = !_showCompletionPin),
              ),
            ),
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
            settingKey: EmailReceiverSettings.reportKey,
            controller: _reportEmailsCtrl,
            savedEmails: _reportEmailList,
            onListUpdated: (v) => _reportEmailList = v,
          ),
          const SizedBox(height: 16),
          _buildEmailSettingsField(
            label: 'Alerts Receivers',
            settingKey: EmailReceiverSettings.alertsKey,
            controller: _alertsEmailsCtrl,
            savedEmails: _alertsEmailList,
            onListUpdated: (v) => _alertsEmailList = v,
          ),
          const SizedBox(height: 16),
          _buildEmailSettingsField(
            label: 'Missing Tanks Receivers',
            settingKey: EmailReceiverSettings.missingTanksKey,
            controller: _missingTanksEmailsCtrl,
            savedEmails: _missingTanksEmailList,
            onListUpdated: (v) => _missingTanksEmailList = v,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Tank Inspection Frequency'),
          const SizedBox(height: 8),
          ..._tanks.map((t) {
            const valid = ['daily', 'weekly_once', 'weekly_thrice', 'custom_days'];
            final currentFreq = valid.contains(t.inspectionFrequencyType)
                ? t.inspectionFrequencyType
                : 'daily';
            return ListTile(
              dense: true,
              title: Text('${t.tankName} (${t.tankCode})'),
              subtitle: Text(_freqLabel(t)),
              trailing: DropdownButton<String>(
                value: currentFreq,
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
            );
          }),
        ],
      ),
    );
  }
}

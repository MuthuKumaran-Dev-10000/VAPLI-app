import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../tanks/data/models/tank_node_model.dart';
import '../../../tanks/data/models/tank_model.dart';
import '../../../tanks/data/repositories/tank_repository.dart';
import '../../../tanks/data/repositories/tank_tree_repository.dart';

// Styling Palette (Obsidian/Copper)
const _kBg = Color(0xFF0C0D0F);
const _kSurface = Color(0xFF141618);
const _kBorder = Color(0xFF252830);
const _kCopper = Color(0xFFCB8C3E);
const _kText = Color(0xFFF0EEE9);
const _kSub = Color(0xFF8A8F9C);
const _kSuccess = Color(0xFF22C55E);
const _kWarn = Color(0xFFF59E0B);

class ParamItem {
  final String key;
  final String name;
  final String type;
  final List<String> options;
  final List<TankModel> tanks;
  final bool selected;
  final int order;

  ParamItem({
    required this.key,
    required this.name,
    required this.type,
    required this.options,
    required this.tanks,
    required this.selected,
    required this.order,
  });
}

class ReportFormatConfigScreen extends StatefulWidget {
  final bool isViolationMode;
  final String? folderIdOverride;

  const ReportFormatConfigScreen({
    super.key,
    this.isViolationMode = false,
    this.folderIdOverride,
  });

  @override
  State<ReportFormatConfigScreen> createState() => _ReportFormatConfigScreenState();
}

class _ReportFormatConfigScreenState extends State<ReportFormatConfigScreen> {
  final _treeRepo = TankTreeRepository();
  final _tankRepo = TankRepository();

  List<TankNode?> _pathStack = [null];
  TankNode? get _currentFolder => _pathStack.last;

  List<TankNode> _allNodes = [];
  List<TankModel> _allTanks = [];
  String _clientName = 'Client';
  Map<String, dynamic> _configsByFolder = {}; // folderId -> config map
  bool _loading = true;

  final TextEditingController _stripTextCtrl = TextEditingController();
  final TextEditingController _pdfThresholdCtrl = TextEditingController();
  final TextEditingController _excelThresholdCtrl = TextEditingController();
  final TextEditingController _uncommonThresholdCtrl = TextEditingController();
  final TextEditingController _groupCoverageThresholdCtrl = TextEditingController();
  final TextEditingController _pendingAssetColsCtrl = TextEditingController();
  final TextEditingController _maxGroupsPerRowCtrl = TextEditingController();
  final TextEditingController _groupCardPaddingCtrl = TextEditingController();
  final TextEditingController _reportNotesCtrl = TextEditingController();
  String _stripPosition = 'start';
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _stripTextCtrl.dispose();
    _pdfThresholdCtrl.dispose();
    _excelThresholdCtrl.dispose();
    _uncommonThresholdCtrl.dispose();
    _groupCoverageThresholdCtrl.dispose();
    _pendingAssetColsCtrl.dispose();
    _maxGroupsPerRowCtrl.dispose();
    _groupCardPaddingCtrl.dispose();
    _reportNotesCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _persistConfig() async {
    try {
      await AppSettingsService.setSetting('report_format', _configsByFolder);
    } catch (e) {
      debugPrint('[ReportConfig] persist error: $e');
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final nodes = await _treeRepo.fetchAll();
      final tanks = await _tankRepo.getAllTanks();
      final activeClientName = await SessionManager.getActiveClientName();
      final clientName = (activeClientName != null && activeClientName.trim().isNotEmpty)
          ? activeClientName.trim()
          : 'Client';

      final reportFormatData = await AppSettingsService.getSetting('report_format');
      Map<String, dynamic> configs = {};
      if (reportFormatData is Map) {
        configs = Map<String, dynamic>.from(reportFormatData);
      }

      setState(() {
        _allNodes = nodes;
        _allTanks = tanks;
        _clientName = clientName;
        _configsByFolder = configs;
        if (widget.folderIdOverride != null) {
          final overrideNode = nodes.cast<TankNode?>().firstWhere(
                (n) => n != null && n.id == widget.folderIdOverride,
                orElse: () => null,
              );
          if (overrideNode != null) {
            _pathStack = [null, overrideNode];
          }
        }
        _loading = false;
      });

      _initStripControls();
    } catch (e) {
      debugPrint('[ReportConfig] load error: $e');
      setState(() => _loading = false);
    }
  }

  void _initStripControls() {
    final folderKey = _currentFolder?.id ?? 'root';
    final config = Map<String, dynamic>.from(_configsByFolder[folderKey] ?? {});

    _stripTextCtrl.text = config['strip_text']?.toString() ?? '';
    _pdfThresholdCtrl.text = (config['pdf_threshold']?.toString() ?? '6');
    _excelThresholdCtrl.text = (config['excel_threshold']?.toString() ?? '12');
    _stripPosition = config['strip_position']?.toString() ?? 'start';

    final globalThreshold = _configsByFolder['uncommon_threshold'];
    _uncommonThresholdCtrl.text = (globalThreshold?.toString() ?? '50');

    _groupCoverageThresholdCtrl.text = (_configsByFolder['group_coverage_threshold'] ?? '50').toString();
    _pendingAssetColsCtrl.text = (_configsByFolder['pending_asset_cols'] ?? '4').toString();
    _maxGroupsPerRowCtrl.text = (_configsByFolder['max_groups_per_row'] ?? '2').toString();
    _groupCardPaddingCtrl.text = (_configsByFolder['group_card_padding'] ?? '6.0').toString();
    _reportNotesCtrl.text = _configsByFolder['report_notes']?.toString() ?? 'This inspection report summarizes current asset health and lubrication parameters.';
  }

  List<TankModel> _getTanksInFolder(TankNode? folder) {
    final folderId = folder?.id;
    final childLeafNodes = _allNodes.where((n) {
      if (folderId == null) {
        return (n.parentId == null || n.parentId == 'root') && n.isLeaf;
      } else {
        return n.parentId == folderId && n.isLeaf;
      }
    });
    final tankIdSet = childLeafNodes.map((n) => n.tankId).whereType<String>().toSet();
    return _allTanks.where((t) => tankIdSet.contains(t.id)).toList();
  }

  String getParamUniqueKey(Map<String, dynamic> p) {
    final name = (p['label'] ?? p['name'] ?? '').toString().trim();
    final type = (p['type'] ?? 'text').toString().trim();
    return '${name}_${type}';
  }

  List<ParamItem> _getParamsList() {
    final folderKey = _currentFolder?.id ?? 'root';
    final config = Map<String, dynamic>.from(_configsByFolder[folderKey] ?? {});
    final selectedParams = widget.isViolationMode
        ? config['violation_params'] as Map?
        : config['selected_params'] as Map?;

    final tanks = _getTanksInFolder(_currentFolder);
    final Map<String, ParamItem> discovered = {};

    for (final tank in tanks) {
      for (final prop in tank.inspectionProperties) {
        final type = prop['type'] as String? ?? 'text';
        if (type == 'group') continue;

        final key = getParamUniqueKey(prop);
        final name = (prop['label'] ?? prop['name'] ?? '').toString();
        final options = List<String>.from(prop['options'] ?? []);

        if (discovered.containsKey(key)) {
          if (!discovered[key]!.tanks.any((t) => t.id == tank.id)) {
            discovered[key]!.tanks.add(tank);
          }
        } else {
          discovered[key] = ParamItem(
            key: key,
            name: name,
            type: type,
            options: options,
            tanks: [tank],
            selected: true,
            order: 0,
          );
        }
      }
    }

    final List<ParamItem> items = [];
    int maxDbOrder = 0;
    if (selectedParams != null) {
      selectedParams.forEach((k, v) {
        if (v is Map) {
          final sel = v['selected'] ?? true;
          final ord = (v['order'] as num?)?.toInt() ?? 0;
          if (sel == true && ord > maxDbOrder) {
            maxDbOrder = ord;
          }
        }
      });
    }

    discovered.forEach((key, item) {
      bool selected = true;
      int order = 0;
      if (selectedParams != null && selectedParams.containsKey(key)) {
        final map = selectedParams[key] as Map?;
        selected = map?['selected'] ?? true;
        order = (map?['order'] as num?)?.toInt() ?? 0;
      }
      items.add(ParamItem(
        key: item.key,
        name: item.name,
        type: item.type,
        options: item.options,
        tanks: item.tanks,
        selected: selected,
        order: order,
      ));
    });

    final selectedConfigured = items.where((i) => i.selected && i.order > 0).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final selectedUnconfigured = items.where((i) => i.selected && i.order == 0).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final unselected = items.where((i) => !i.selected).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final List<ParamItem> finalResult = [];
    finalResult.addAll(selectedConfigured);

    int nextOrder = maxDbOrder + 1;
    for (final item in selectedUnconfigured) {
      finalResult.add(ParamItem(
        key: item.key,
        name: item.name,
        type: item.type,
        options: item.options,
        tanks: item.tanks,
        selected: true,
        order: nextOrder++,
      ));
    }

    finalResult.addAll(unselected);
    return finalResult;
  }

  Future<void> _toggleParam(String paramKey, bool check) async {
    final folderKey = _currentFolder?.id ?? 'root';
    final paramPath = widget.isViolationMode ? 'violation_params' : 'selected_params';

    final config = Map<String, dynamic>.from(_configsByFolder[folderKey] ?? {});
    final selectedParams = Map<String, dynamic>.from(config[paramPath] ?? {});

    if (check) {
      int maxOrder = 0;
      selectedParams.forEach((k, v) {
        if (v is Map && v['selected'] == true) {
          final ord = (v['order'] as num?)?.toInt() ?? 0;
          if (ord > maxOrder) maxOrder = ord;
        }
      });
      selectedParams[paramKey] = {
        'selected': true,
        'order': maxOrder + 1,
      };
    } else {
      final currentMap = selectedParams[paramKey] as Map?;
      final int currentOrder = (currentMap?['order'] as num?)?.toInt() ?? 0;
      selectedParams[paramKey] = {
        'selected': false,
        'order': 0,
      };

      selectedParams.forEach((k, v) {
        if (v is Map && v['selected'] == true) {
          final ord = (v['order'] as num?)?.toInt() ?? 0;
          if (ord > currentOrder) {
            selectedParams[k] = {
              'selected': true,
              'order': ord - 1,
            };
          }
        }
      });
    }

    setState(() {
      config[paramPath] = selectedParams;
      _configsByFolder[folderKey] = config;
    });

    await _persistConfig();
  }

  Future<void> _reorderParam(String paramKey, bool up) async {
    final folderKey = _currentFolder?.id ?? 'root';
    final paramPath = widget.isViolationMode ? 'violation_params' : 'selected_params';

    final config = Map<String, dynamic>.from(_configsByFolder[folderKey] ?? {});
    final selectedParams = Map<String, dynamic>.from(config[paramPath] ?? {});

    final currentMap = selectedParams[paramKey] as Map?;
    if (currentMap == null || currentMap['selected'] != true) return;
    final int currentOrder = (currentMap['order'] as num?)?.toInt() ?? 0;

    if (up && currentOrder <= 1) return;

    final targetOrder = up ? currentOrder - 1 : currentOrder + 1;
    String? partnerKey;
    selectedParams.forEach((k, v) {
      if (v is Map && v['selected'] == true) {
        final ord = (v['order'] as num?)?.toInt() ?? 0;
        if (ord == targetOrder) {
          partnerKey = k;
        }
      }
    });

    if (partnerKey != null) {
      selectedParams[paramKey] = {
        'selected': true,
        'order': targetOrder,
      };
      selectedParams[partnerKey!] = {
        'selected': true,
        'order': currentOrder,
      };

      setState(() {
        config[paramPath] = selectedParams;
        _configsByFolder[folderKey] = config;
      });

      await _persistConfig();
    }
  }

  void _onStripTextChanged(String val) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final folderKey = _currentFolder?.id ?? 'root';
      final config = Map<String, dynamic>.from(_configsByFolder[folderKey] ?? {});
      config['strip_text'] = val;
      _configsByFolder[folderKey] = config;
      await _persistConfig();
    });
  }

  Future<void> _onStripPositionChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _stripPosition = val;
    });

    final folderKey = _currentFolder?.id ?? 'root';
    final config = Map<String, dynamic>.from(_configsByFolder[folderKey] ?? {});
    config['strip_position'] = val;
    _configsByFolder[folderKey] = config;

    await _persistConfig();
  }

  IconData _typeIconFor(String t) {
    switch (t) {
      case 'number':
        return Icons.pin_outlined;
      case 'text':
        return Icons.text_fields;
      case 'dropdown':
        return Icons.arrow_drop_down_circle_outlined;
      case 'dual_text':
        return Icons.view_column_outlined;
      case 'slider':
        return Icons.linear_scale;
      case 'multiline':
        return Icons.notes;
      default:
        return Icons.help_outline;
    }
  }

  Color _typeColorFor(String t) {
    switch (t) {
      case 'number':
        return _kCopper;
      case 'text':
        return _kSuccess;
      case 'dropdown':
        return const Color(0xFFBB86FC);
      case 'dual_text':
        return _kWarn;
      case 'slider':
        return const Color(0xFF03DAC6);
      case 'multiline':
        return const Color(0xFF7986CB);
      default:
        return _kSub;
    }
  }

  void _jumpToBreadcrumb(int index) {
    if (index >= _pathStack.length - 1) return;
    setState(() {
      _pathStack.removeRange(index + 1, _pathStack.length);
    });
    _initStripControls();
  }

  void _drillIntoFolder(TankNode folder) {
    setState(() {
      _pathStack.add(folder);
    });
    _initStripControls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        foregroundColor: _kText,
        title: Text(
          widget.isViolationMode
              ? 'Violation Columns Configuration'
              : 'Report Format Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kCopper))
          : Column(
              children: [
                Container(
                  color: _kSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_outlined, color: _kCopper, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_pathStack.length, (idx) {
                              final isLast = idx == _pathStack.length - 1;
                              final node = _pathStack[idx];
                              final label = node?.name ?? (_clientName.isNotEmpty ? _clientName : 'Client');
                              return Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => widget.isViolationMode ? null : _jumpToBreadcrumb(idx),
                                    child: Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        color: isLast ? _kText : (widget.isViolationMode ? _kSub : _kCopper),
                                        fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Icon(Icons.chevron_right, color: _kSub, size: 14),
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _kBorder),

                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (!widget.isViolationMode) ...[
                          _buildFolderBrowsingList(),
                          const SizedBox(height: 16),
                          const Divider(color: _kBorder),
                          const SizedBox(height: 8),
                          _buildTextStrippingSection(),
                          const SizedBox(height: 16),
                          const Divider(color: _kBorder),
                          const SizedBox(height: 8),
                          _buildGeneralSettingsSection(),
                          const SizedBox(height: 16),
                          const Divider(color: _kBorder),
                          const SizedBox(height: 8),
                        ] else ...[
                          Text(
                            'Configure the columns to be displayed when a constraint is violated in reports generated under this group.',
                            style: GoogleFonts.inter(color: _kSub, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: _kBorder),
                          const SizedBox(height: 16),
                        ],
                        _buildParametersConfigSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFolderBrowsingList() {
    final currentId = _currentFolder?.id;
    final childFolders = _allNodes.where((n) => n.parentId == currentId && n.isFolder).toList();

    if (childFolders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigate Deeper into Groups',
          style: GoogleFonts.inter(color: _kSub, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: childFolders.map((folder) {
            return OutlinedButton.icon(
              onPressed: () => _drillIntoFolder(folder),
              icon: const Icon(Icons.folder, size: 16, color: _kCopper),
              label: Text(
                folder.name,
                style: GoogleFonts.inter(fontSize: 13, color: _kText),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kBorder),
                backgroundColor: _kSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextStrippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repetitive Word Removal from Tank Names',
          style: GoogleFonts.inter(color: _kCopper, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Clean redundant group tags (e.g. remove "PM6" prefix to display "m701" instead of "PM6 m701").',
          style: GoogleFonts.inter(color: _kSub, fontSize: 11),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stripTextCtrl,
          onChanged: _onStripTextChanged,
          style: GoogleFonts.inter(color: _kText, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Text to remove (case-insensitive)',
            labelStyle: GoogleFonts.inter(color: _kSub, fontSize: 13),
            filled: true,
            fillColor: _kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kCopper),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Remove word at:',
              style: GoogleFonts.inter(color: _kText, fontSize: 13),
            ),
            const SizedBox(width: 16),
            Radio<String>(
              value: 'start',
              groupValue: _stripPosition,
              activeColor: _kCopper,
              onChanged: _onStripPositionChanged,
            ),
            Text('Start', style: GoogleFonts.inter(color: _kText, fontSize: 13)),
            const SizedBox(width: 16),
            Radio<String>(
              value: 'end',
              groupValue: _stripPosition,
              activeColor: _kCopper,
              onChanged: _onStripPositionChanged,
            ),
            Text('End', style: GoogleFonts.inter(color: _kText, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralSettingsSection() {
    final folderKey = _currentFolder?.id ?? 'root';
    final config = Map<String, dynamic>.from(_configsByFolder[folderKey] ?? {});
    final includeTimestamp = config['include_timestamp'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General Report Settings',
          style: GoogleFonts.inter(color: _kCopper, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  'Include Timestamp in Cells',
                  style: GoogleFonts.inter(color: _kText, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Show reading time (HH:MM AM/PM in green) below values in table cells.',
                  style: GoogleFonts.inter(color: _kSub, fontSize: 11),
                ),
                value: includeTimestamp,
                activeColor: _kCopper,
                activeTrackColor: _kCopper.withOpacity(0.3),
                inactiveThumbColor: _kSub,
                inactiveTrackColor: _kBg,
                onChanged: (val) async {
                  setState(() {
                    config['include_timestamp'] = val;
                    _configsByFolder[folderKey] = config;
                  });
                  await _persistConfig();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParametersConfigSection() {
    final paramList = _getParamsList();

    if (paramList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No inspection parameters found in this folder.',
            style: GoogleFonts.inter(color: _kSub, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inspection Parameters Column Order',
              style: GoogleFonts.inter(color: _kCopper, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Discovered: ${paramList.length}',
              style: GoogleFonts.inter(color: _kSub, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select and order the parameter columns to show in generated PDF/Excel reports.',
          style: GoogleFonts.inter(color: _kSub, fontSize: 11),
        ),
        const SizedBox(height: 12),
        ...paramList.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isFirst = idx == 0;
          final isLast = idx == paramList.length - 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: item.selected ? _kSurface : _kBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: item.selected ? _kBorder : _kBorder.withOpacity(0.5)),
            ),
            child: ListTile(
              dense: true,
              leading: Checkbox(
                value: item.selected,
                activeColor: _kCopper,
                onChanged: (val) => _toggleParam(item.key, val ?? false),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.inter(
                        color: item.selected ? _kText : _kSub,
                        fontWeight: item.selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColorFor(item.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _typeColorFor(item.type).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIconFor(item.type), size: 11, color: _typeColorFor(item.type)),
                        const SizedBox(width: 4),
                        Text(
                          item.type.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: _typeColorFor(item.type),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Used in ${item.tanks.length} asset${item.tanks.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(color: _kSub, fontSize: 11),
              ),
              trailing: item.selected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 16, color: _kCopper),
                          onPressed: isFirst ? null : () => _reorderParam(item.key, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 16, color: _kCopper),
                          onPressed: isLast ? null : () => _reorderParam(item.key, false),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        }),
        if (!widget.isViolationMode) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCopper,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final folderKey = _currentFolder?.id ?? '_root';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportFormatConfigScreen(
                      isViolationMode: true,
                      folderIdOverride: folderKey,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: Text(
                'Configure "If Constraint is Violated"',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

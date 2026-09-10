import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vapli/data/models/user_model.dart';
import 'package:vapli/features/tanks/data/models/tank_model.dart';
import 'package:vapli/features/tanks/data/models/tank_node_model.dart';
import 'package:vapli/features/tanks/data/repositories/tank_repository.dart';
import 'package:vapli/features/tanks/data/repositories/tank_tree_repository.dart';
import 'package:vapli/features/readings/presentation/pages/reading_entry_screen.dart';
import 'package:vapli/core/services/client_context_service.dart';

const _kBg = Color(0xFF080909);
const _kSurface = Color(0xFF0F1012);
const _kCard = Color(0xFF151719);
const _kBorder = Color(0xFF222529);
const _kTeal = Color(0xFF1ABCBD);
const _kText = Color(0xFFEDEBE6);
const _kSub = Color(0xFF6B7080);
const _kSuccess = Color(0xFF22C55E);

class TankInputBrowser extends StatefulWidget {
  final UserModel? currentUser;

  const TankInputBrowser({
    super.key,
    this.currentUser,
  });

  @override
  State<TankInputBrowser> createState() => _TankInputBrowserState();
}

class _TankInputBrowserState extends State<TankInputBrowser> {
  final _treeRepo = TankTreeRepository();
  final _tankRepo = TankRepository();

  final List<TankNode?> _pathStack = [null];
  TankNode? get _currentFolder => _pathStack.last;

  List<TankNode> _nodes = [];
  final Map<String, TankModel> _tankCache = {};
  StreamSubscription<List<TankNode>>? _sub;
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  String _query = '';

  TankNode? _selectedLeaf;
  TankModel? _selectedTank;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) {
        setState(() {
          _query = q;
          if (q.isNotEmpty) {
            _selectedLeaf = null;
            _selectedTank = null;
          }
        });
      }
    });
    _subscribeToCurrentFolder();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _subscribeToCurrentFolder() {
    _sub?.cancel();
    setState(() {
      _loading = true;
      _selectedLeaf = null;
      _selectedTank = null;
    });

    _sub = _treeRepo.watchChildren(_currentFolder?.id).listen((nodes) async {
      final clientName = await ClientContextService.resolveClientName();
      List<TankNode> filteredNodes = nodes;
      if (_currentFolder == null && clientName != null && clientName.trim().isNotEmpty) {
        final target = clientName.trim().toLowerCase();
        filteredNodes = nodes.where((n) {
          final z = (n.zone ?? '').trim().toLowerCase();
          return z.isEmpty || z == target;
        }).toList();
      }

      for (final n in filteredNodes) {
        if (n.isLeaf && n.tankId != null && !_tankCache.containsKey(n.tankId)) {
          final t = await _tankRepo.getTankById(n.tankId!);
          if (t != null && mounted) _tankCache[n.tankId!] = t;
        }
      }

      if (mounted) {
        setState(() {
          _nodes = filteredNodes;
          _loading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _openFolder(TankNode folder) {
    HapticFeedback.lightImpact();
    setState(() {
      _pathStack.add(folder);
      _nodes = [];
      _query = '';
      _searchCtrl.clear();
      _selectedLeaf = null;
      _selectedTank = null;
    });
    _subscribeToCurrentFolder();
  }

  void _navigateToBreadcrumb(int index) {
    if (index >= _pathStack.length - 1) return;
    setState(() {
      _pathStack.removeRange(index + 1, _pathStack.length);
      _nodes = [];
      _query = '';
      _searchCtrl.clear();
      _selectedLeaf = null;
      _selectedTank = null;
    });
    _subscribeToCurrentFolder();
  }

  Future<void> _selectLeaf(TankNode leaf) async {
    HapticFeedback.lightImpact();
    TankModel? tank = leaf.tankId != null ? _tankCache[leaf.tankId] : null;
    if (tank == null && leaf.tankId != null) {
      tank = await _tankRepo.getTankById(leaf.tankId!);
      if (tank != null && mounted) {
        _tankCache[leaf.tankId!] = tank;
      }
    }
    if (mounted) {
      setState(() {
        _selectedLeaf = leaf;
        _selectedTank = tank;
      });
    }
  }

  Future<void> _openReadingEntry(TankModel tank) async {
    final user = widget.currentUser ??
        UserModel(
          id: 'system',
          username: 'Operator',
          role: 'operator',
          fullName: 'Operator',
          roleRank: 1,
          createdAt: DateTime.now().toIso8601String(),
        );
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingEntryScreen(
          tank: tank,
          currentUser: user,
        ),
      ),
    );
    if (ok == true && mounted) {
      _subscribeToCurrentFolder();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TankNode> displayNodes = _nodes;
    if (_query.isNotEmpty) {
      displayNodes = _nodes.where((n) => n.name.toLowerCase().contains(_query)).toList();
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: _kSub, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.inter(color: _kText, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search assets & folders…',
                          hintStyle: TextStyle(color: _kSub, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: _kSub, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      ),
                  ],
                ),
              ),
            ),

            // Breadcrumb Navigation
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pathStack.length,
                separatorBuilder: (_, __) => const Icon(Icons.chevron_right, size: 16, color: _kSub),
                itemBuilder: (context, idx) {
                  final node = _pathStack[idx];
                  final isLast = idx == _pathStack.length - 1;
                  final label = idx == 0 ? 'Root' : (node?.name ?? '');

                  return GestureDetector(
                    onTap: () => _navigateToBreadcrumb(idx),
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: isLast ? _kTeal : _kSub,
                          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: _kBorder, height: 1),

            // Main Content Area
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _kTeal, strokeWidth: 2))
                  : displayNodes.isEmpty
                      ? Center(
                          child: Text(
                            _query.isNotEmpty ? 'No matches found' : 'This folder is empty',
                            style: GoogleFonts.inter(color: _kSub, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayNodes.length,
                          itemBuilder: (context, idx) {
                            final n = displayNodes[idx];
                            if (n.isFolder) {
                              return _buildFolderTile(n);
                            } else {
                              return _buildLeafTile(n);
                            }
                          },
                        ),
            ),

            // Selected Leaf Detail Drawer / Bar
            if (_selectedLeaf != null && _selectedTank != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(top: BorderSide(color: _kBorder, width: 1.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTank!.tankName,
                            style: GoogleFonts.outfit(color: _kText, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: _kSub),
                          onPressed: () => setState(() {
                            _selectedLeaf = null;
                            _selectedTank = null;
                          }),
                        ),
                      ],
                    ),
                    Text(
                      'Code: ${_selectedTank!.tankCode} | Path: ${_selectedLeaf!.path}',
                      style: GoogleFonts.inter(color: _kSub, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_note, color: Colors.black),
                        label: Text(
                          'Take Reading',
                          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () => _openReadingEntry(_selectedTank!),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTile(TankNode folder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: ListTile(
        leading: const Icon(Icons.folder_outlined, color: _kTeal, size: 24),
        title: Text(folder.name, style: GoogleFonts.inter(color: _kText, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: _kSub, size: 20),
        onTap: () => _openFolder(folder),
      ),
    );
  }

  Widget _buildLeafTile(TankNode leaf) {
    final isSelected = _selectedLeaf?.id == leaf.id;
    final tank = leaf.tankId != null ? _tankCache[leaf.tankId] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? _kCard : _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? _kTeal : _kBorder),
      ),
      child: ListTile(
        leading: const Icon(Icons.water_drop_outlined, color: _kTeal, size: 24),
        title: Text(leaf.name, style: GoogleFonts.inter(color: _kText, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          tank != null ? 'Code: ${tank.tankCode}' : 'Leaf Asset',
          style: GoogleFonts.inter(color: _kSub, fontSize: 12),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kTeal.withAlpha(51),
            foregroundColor: _kTeal,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _selectLeaf(leaf),
          child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        onTap: () => _selectLeaf(leaf),
      ),
    );
  }
}

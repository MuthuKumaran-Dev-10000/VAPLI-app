import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vapli/core/theme/app_theme.dart';
import 'package:vapli/data/models/user_model.dart';
import 'package:vapli/features/tanks/data/models/tank_model.dart';
import 'package:vapli/features/tanks/data/repositories/tank_repository.dart';
import 'package:vapli/features/readings/data/repositories/reading_repository.dart';
import 'package:vapli/features/dashboard/data/repositories/dashboard_stats_repository.dart';
import 'package:vapli/features/readings/presentation/pages/reading_entry_screen.dart';
import 'qr_scan_screen.dart';

class InputTab extends StatefulWidget {
  final UserModel? currentUser;

  const InputTab({
    super.key,
    required this.currentUser,
  });

  @override
  State<InputTab> createState() => _InputTabState();
}

class _InputTabState extends State<InputTab> {
  final TankRepository _tankRepo = TankRepository();
  List<TankModel> _tanks = [];
  TankModel? _selectedTank;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTanks();
  }

  Future<void> _fetchTanks() async {
    setState(() => _loading = true);
    try {
      final tanks = await _tankRepo.getAllTanks();
      if (mounted) {
        setState(() {
          _tanks = tanks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (result == null || result.isEmpty || !mounted) return;

    // Search tank by code or id or qr url match
    final matched = _tanks.firstWhere(
      (t) =>
          t.id == result ||
          t.tankCode.toLowerCase() == result.toLowerCase() ||
          (t.qrImageUrl != null && t.qrImageUrl!.contains(result)) ||
          (t.qrJson != null && t.qrJson!.contains(result)),
      orElse: () => _tanks.firstWhere(
        (t) => result.toLowerCase().contains(t.tankCode.toLowerCase()),
        orElse: () => _tanks.first,
      ),
    );

    if (matched.id.isNotEmpty) {
      setState(() {
        _selectedTank = matched;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected Tank: ${matched.tankName} (${matched.tankCode})'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(
            'SELECT TANK',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // Dropdown + QR row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: LinearProgressIndicator(color: AppTheme.primary),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<TankModel>(
                            value: _selectedTank,
                            isExpanded: true,
                            dropdownColor: AppTheme.surface,
                            hint: Text(
                              'Choose a tank...',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                            items: _tanks.map((t) {
                              return DropdownMenuItem<TankModel>(
                                value: t,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t.tankName,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${t.tankCode} · ${t.location ?? "—"}',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (t) {
                              setState(() => _selectedTank = t);
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              _QrButton(onPressed: _scanQr),
            ],
          ),

          const SizedBox(height: 32),

          // Tank info card (shown when selected)
          if (_selectedTank != null) ...[
            _TankInfoCard(tank: _selectedTank!),
            const SizedBox(height: 32),
          ],

          // Take Readings CTA
          Center(
            child: Column(
              children: [
                _MainActionButton(
                  enabled: _selectedTank != null,
                  onPressed: _selectedTank == null
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final from = now.subtract(const Duration(minutes: 30));
                          String duplicateReason = '';
                          bool isDuplicate = false;

                          try {
                            final stats = await DashboardStatsRepository().getStats(_selectedTank!.id);
                            if (stats.lastCapturedAt != null) {
                              final lastTime = DateTime.tryParse(stats.lastCapturedAt!);
                              if (lastTime != null) {
                                final diff = now.difference(lastTime.toLocal()).inMinutes.abs();
                                if (diff < 30) {
                                  isDuplicate = true;
                                }
                              }
                            }
                          } catch (_) {}

                          if (!isDuplicate) {
                            try {
                              final existing = await ReadingRepository().getReadingsInRange(
                                tankId: _selectedTank!.id,
                                from: from,
                                to: now,
                              );
                              if (existing.isNotEmpty) {
                                isDuplicate = true;
                              }
                            } catch (_) {}
                          }

                          if (isDuplicate && context.mounted) {
                            final proceed = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppTheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: Text(
                                  'Duplicate Reading Alert',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                content: Text(
                                  'Do you really want to take a reading for ${_selectedTank!.tankName}? A recent reading already exists.',
                                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(
                                      'NO',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(
                                      'YES',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.background,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (proceed != true) {
                              setState(() => _selectedTank = null);
                              return;
                            }

                            final reason = await showDialog<String>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                final controller = TextEditingController();
                                final formKey = GlobalKey<FormState>();
                                return AlertDialog(
                                  backgroundColor: AppTheme.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  title: Text(
                                    'Enter Duplicate Reason',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  content: Form(
                                    key: formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Please provide a mandatory reason for this duplicate reading.',
                                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: controller,
                                          maxLines: 2,
                                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: 'Reason...',
                                            hintStyle: GoogleFonts.inter(
                                                color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                                            filled: true,
                                            fillColor: AppTheme.background,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: AppTheme.border),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: AppTheme.primary),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Reason cannot be empty';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (formKey.currentState?.validate() ?? false) {
                                          Navigator.of(context).pop(controller.text.trim());
                                        }
                                      },
                                      child: Text(
                                        'Submit',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.background,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (reason == null || reason.isEmpty) {
                              setState(() => _selectedTank = null);
                              return;
                            }
                            duplicateReason = reason;
                          }

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReadingEntryScreen(
                                tank: _selectedTank!,
                                currentUser: widget.currentUser!,
                                duplicateReason: duplicateReason.isNotEmpty ? duplicateReason : null,
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedTank == null
                      ? 'Select a tank to enable readings'
                      : 'Ready to record reading for ${_selectedTank!.tankName}',
                  style: GoogleFonts.inter(
                    color: _selectedTank == null
                        ? AppTheme.textSecondary.withValues(alpha: 0.5)
                        : AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _QrButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, Color(0xFF0E7490)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner_outlined, color: Colors.white, size: 26),
      ),
    );
  }
}

class _TankInfoCard extends StatelessWidget {
  final TankModel tank;
  const _TankInfoCard({required this.tank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_outlined, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tank.tankName,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      tank.tankCode,
                      style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.inter(
                    color: AppTheme.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(icon: Icons.location_on_outlined, label: tank.location ?? '—'),
              const SizedBox(width: 10),
              _InfoChip(
                icon: Icons.straighten_outlined,
                label: 'Scale: ${tank.scaleMin.toInt()}–${tank.scaleMax.toInt()}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActionButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;
  const _MainActionButton({required this.enabled, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : AppTheme.surface,
          border: Border.all(
            color: enabled ? AppTheme.primary : AppTheme.border,
            width: 2,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_outlined,
              color: enabled ? Colors.white : AppTheme.textSecondary.withValues(alpha: 0.4),
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              'Take\nReading',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: enabled ? Colors.white : AppTheme.textSecondary.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

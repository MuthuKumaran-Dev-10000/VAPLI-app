import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lubrication_indicator/features/dashboard/presentation/widgets/completion_evidence_widgets.dart';
import 'dashboard_alerts_display_model.dart';

const _kCard = Color(0xFF1E293B);
const _kText = Color(0xFFF8FAFC);
const _kSub = Color(0xFF94A3B8);
const _kBorder = Color(0xFF334155);
const _kSuccess = Color(0xFF22C55E);

class CompletedAlertLeafCard extends StatefulWidget {
  final DashboardAlertDisplayItem item;

  const CompletedAlertLeafCard({super.key, required this.item});

  @override
  State<CompletedAlertLeafCard> createState() => _CompletedAlertLeafCardState();
}

class _CompletedAlertLeafCardState extends State<CompletedAlertLeafCard> {
  bool _expanded = false;

  String _fmtTs(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final alertCaptures =
        item.imageUrl.isNotEmpty ? [item.imageUrl] : <String>[];
    final proofs = item.completedPhotoUrls.isNotEmpty
        ? item.completedPhotoUrls
        : (item.completedPhotoUrl.isNotEmpty ? [item.completedPhotoUrl] : <String>[]);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kSuccess.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: _kSuccess, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.alertTitle,
                          style: GoogleFonts.dmSans(
                            color: _kText,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.tankName} · ${item.paramLabel}',
                          style: GoogleFonts.dmSans(color: _kSub, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _kSub,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Message', item.message),
                  _row('Value', item.paramValue),
                  _row('Completed at', _fmtTs(item.timestamp)),
                  if (item.completedBy.isNotEmpty)
                    _row('Completed by', item.completedBy),
                  if (item.completedDescription.isNotEmpty)
                    _row('Resolution', item.completedDescription),
                  if (alertCaptures.isNotEmpty || proofs.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    CompletionEvidenceSpans(
                      alertCaptureUrls: alertCaptures,
                      proofUrls: proofs,
                      slideAlert: item,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              '$label:',
              style: GoogleFonts.dmSans(
                color: _kSub,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(color: _kText, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

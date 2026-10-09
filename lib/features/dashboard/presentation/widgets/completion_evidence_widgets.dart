import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lubrication_indicator/core/utils/media_url_resolver.dart';
import 'package:lubrication_indicator/features/dashboard_folders/dashboard_alerts_display_model.dart';
import 'package:lubrication_indicator/features/dashboard_folders/fanned_card_layout.dart';

const _kText = Color(0xFFF0EEE9);
const _kSub = Color(0xFF8A8F9C);
const _kSuccess = Color(0xFF22C55E);
const _kDanger = Color(0xFFEF4444);
const _kCopper = Color(0xFFCB8C3E);

class CompletionEvidenceSpans extends StatelessWidget {
  const CompletionEvidenceSpans({
    super.key,
    required this.alertCaptureUrls,
    required this.proofUrls,
    this.slideAlert,
  });

  final List<String> alertCaptureUrls;
  final List<String> proofUrls;
  final DashboardAlertDisplayItem? slideAlert;

  @override
  Widget build(BuildContext context) {
    final captures = MediaUrlResolver.resolveList(alertCaptureUrls);
    final proofs = MediaUrlResolver.resolveList(proofUrls);

    if (captures.isEmpty && proofs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (captures.isNotEmpty)
          _EvidenceSpan(
            label: 'ALERT CAPTURE',
            color: _kDanger,
            urls: captures,
            slideTag: 'COMPLAINT IMAGE',
            slideAlert: slideAlert,
          ),
        if (captures.isNotEmpty && proofs.isNotEmpty) const SizedBox(height: 10),
        if (proofs.isNotEmpty)
          _EvidenceSpan(
            label: 'COMPLETION PROOF',
            color: _kSuccess,
            urls: proofs,
            slideTag: 'COMPLETED PROOF',
            slideAlert: slideAlert,
          ),
      ],
    );
  }
}

class _EvidenceSpan extends StatelessWidget {
  const _EvidenceSpan({
    required this.label,
    required this.color,
    required this.urls,
    required this.slideTag,
    this.slideAlert,
  });

  final String label;
  final Color color;
  final List<String> urls;
  final String slideTag;
  final DashboardAlertDisplayItem? slideAlert;

  @override
  Widget build(BuildContext context) {
    final slides = urls
        .map((u) => SlideImageItem(url: u, categoryTag: slideTag, alert: slideAlert))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF141618),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                slideTag == 'COMPLAINT IMAGE'
                    ? Icons.warning_amber_rounded
                    : Icons.verified_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${urls.length} photo${urls.length > 1 ? 's' : ''}',
                style: GoogleFonts.dmSans(color: _kSub, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final url = urls[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => FullScreenSlideViewer(
                          slides: slides,
                          initialIndex: i,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFF1A1C20),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: _kCopper,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFF1A1C20),
                          child: const Icon(Icons.broken_image_rounded, color: _kSub),
                        ),
                      ),
                    ),
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

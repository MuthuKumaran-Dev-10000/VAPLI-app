import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class PlaceholderTabWidget extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderTabWidget({
    super.key,
    required this.title,
    this.icon = Icons.construction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withAlpha(76)),
            ),
            child: Text(
              'Under Construction • Planned for Next Domain Migration Slice',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lubrication_indicator/core/services/completion_proof_pin_service.dart';

const _kCard = Color(0xFF1A1C20);
const _kText = Color(0xFFF0EEE9);
const _kSub = Color(0xFF8A8F9C);
const _kBorder = Color(0xFF252830);
const _kSurface = Color(0xFF141618);
const _kCopper = Color(0xFFCB8C3E);
const _kDanger = Color(0xFFEF4444);

/// Returns true when the configured completion PIN matches.
Future<bool> showCompletionProofPinDialog(BuildContext context) async {
  final configured = await CompletionProofPinService.configuredPin();
  if (configured == null || configured.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo bypass PIN is not configured for this client.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: _kDanger,
        ),
      );
    }
    return false;
  }

  final pinCtrl = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.pin_outlined, color: _kCopper, size: 20),
          const SizedBox(width: 8),
          Text(
            'Admin PIN',
            style: GoogleFonts.dmSans(
              color: _kText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter PIN to complete without verification photos.',
            style: GoogleFonts.dmSans(color: _kSub, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.dmSans(color: _kText, fontSize: 16, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: '••••',
              filled: true,
              fillColor: _kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder),
              ),
            ),
            onSubmitted: (_) async {
              final ok = await CompletionProofPinService.verify(pinCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx, ok);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: GoogleFonts.dmSans(color: _kSub)),
        ),
        TextButton(
          onPressed: () async {
            final ok = await CompletionProofPinService.verify(pinCtrl.text);
            if (ctx.mounted) Navigator.pop(ctx, ok);
          },
          child: Text('Confirm', style: GoogleFonts.dmSans(color: _kCopper, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  Future.delayed(const Duration(milliseconds: 300), pinCtrl.dispose);
  if (result != true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Incorrect PIN.', style: GoogleFonts.dmSans()),
        backgroundColor: _kDanger,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  return result == true;
}

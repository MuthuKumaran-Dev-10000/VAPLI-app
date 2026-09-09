import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/client_model.dart';
import '../controllers/admin_controller.dart';

class ClientFormScreen extends StatefulWidget {
  final ClientModel? clientToEdit;

  const ClientFormScreen({
    super.key,
    this.clientToEdit,
  });

  bool get isEditMode => clientToEdit != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dbKeyCtrl;
  late final TextEditingController _descCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.clientToEdit;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _dbKeyCtrl = TextEditingController(text: c?.dbKey ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dbKeyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final adminCtrl = context.read<AdminController>();

    bool success = false;
    if (widget.isEditMode) {
      success = await adminCtrl.updateClient(
        widget.clientToEdit!.id,
        _nameCtrl.text,
        _descCtrl.text,
      );
    } else {
      success = await adminCtrl.createClient(
        _nameCtrl.text,
        _descCtrl.text,
      );
    }

    if (mounted) setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Client organization "${_nameCtrl.text.trim()}" updated successfully!'
                : 'Client organization "${_nameCtrl.text.trim()}" created successfully!',
          ),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          widget.isEditMode ? 'Edit Client: ${widget.clientToEdit!.name}' : 'New Client Organization',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isEditMode ? 'Client Organization Settings' : 'Client Profile Details',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Client Name
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Organization Name *',
                      prefixIcon: Icon(Icons.domain, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Client name is compulsory' : null,
                  ),
                  const SizedBox(height: 14),

                  // DB Key / Code (Read only in edit mode)
                  if (widget.isEditMode)
                    TextFormField(
                      controller: _dbKeyCtrl,
                      enabled: false,
                      style: const TextStyle(color: AppTheme.textSecondary),
                      decoration: const InputDecoration(
                        labelText: 'Client DB Key (Code)',
                        prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.textSecondary),
                      ),
                    ),
                  if (widget.isEditMode) const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Description / Notes',
                      prefixIcon: Icon(Icons.description_outlined, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              widget.isEditMode ? 'Save Client Changes' : 'Create Client Organization',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

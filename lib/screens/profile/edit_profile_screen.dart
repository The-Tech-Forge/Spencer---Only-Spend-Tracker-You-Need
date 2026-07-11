import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../model/user_model.dart';
import '../../provider/user_provider.dart';

/// Full edit profile screen — allows editing name, DOB, and profile picture.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  DateTime? _selectedDob;
  String? _profilePicturePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).value;
    if (user != null) _populateFromUser(user);
  }

  void _populateFromUser(UserModel user) {
    _firstNameCtrl.text = user.firstname;
    _middleNameCtrl.text = user.middlename ?? '';
    _lastNameCtrl.text = user.lastname;
    _selectedDob = DateTime.tryParse(user.dob);
    _profilePicturePath = user.profilePicturePath;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null || !mounted) return;

    // Save to app documents directory for persistence
    final docsDir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory(p.join(docsDir.path, 'avatars'));
    await avatarDir.create(recursive: true);
    final destPath = p.join(avatarDir.path, 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(file.path).copy(destPath);

    setState(() => _profilePicturePath = destPath);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF00BCD4)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date of birth', style: GoogleFonts.outfit())),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = ref.read(userProvider).value;
      if (user == null) return;

      final updated = user.copyWith(
        firstname: _firstNameCtrl.text.trim(),
        middlename: _middleNameCtrl.text.trim().isEmpty ? null : _middleNameCtrl.text.trim(),
        lastname: _lastNameCtrl.text.trim(),
        dob: DateFormatter.toIso(_selectedDob!),
        profilePicturePath: _profilePicturePath,
      );

      await ref.read(userRepositoryProvider).updateUser(updated);
      ref.invalidate(userProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated!', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF00BCD4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF00BCD4))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar ──────────────────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                      backgroundImage: _profilePicturePath != null
                          ? FileImage(File(_profilePicturePath!))
                          : null,
                      child: _profilePicturePath == null
                          ? Text(
                              (_firstNameCtrl.text.isNotEmpty
                                  ? _firstNameCtrl.text[0]
                                  : '?').toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF00BCD4),
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BCD4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const Gap(8),
              Text(
                'Tap to change photo',
                style: GoogleFonts.outfit(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              if (_profilePicturePath != null) ...[
                const Gap(4),
                TextButton(
                  onPressed: () => setState(() => _profilePicturePath = null),
                  child: Text('Remove photo', style: GoogleFonts.outfit(fontSize: 12, color: Colors.red)),
                ),
              ],
              const Gap(28),

              // ── Name Fields ──────────────────────────────────────────────────
              _section('Personal Information', colorScheme),
              const Gap(12),
              _nameField(_firstNameCtrl, 'First Name', Icons.person_outline, required: true),
              const Gap(12),
              _nameField(_middleNameCtrl, 'Middle Name (optional)', Icons.person_outline),
              const Gap(12),
              _nameField(_lastNameCtrl, 'Last Name', Icons.person_outline, required: true),
              const Gap(20),

              // ── DOB ──────────────────────────────────────────────────────────
              _section('Date of Birth', colorScheme),
              const Gap(12),
              InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surface.withValues(alpha: 0.5)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake_outlined, color: const Color(0xFF00BCD4), size: 20),
                      const Gap(12),
                      Text(
                        _selectedDob != null
                            ? DateFormat('dd MMMM yyyy').format(_selectedDob!)
                            : 'Select Date of Birth',
                        style: GoogleFonts.outfit(
                          color: _selectedDob != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              ),
              const Gap(40),

              // ── Save Button ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label, ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF00BCD4),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _nameField(TextEditingController ctrl, String label, IconData icon, {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.outfit(),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return '${label.replaceAll(' (optional)', '')} is required';
              return null;
            }
          : null,
    );
  }
}

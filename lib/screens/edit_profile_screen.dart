import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/profile_state.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _goalController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _emailController = TextEditingController(text: widget.profile.email);
    _goalController = TextEditingController(text: widget.profile.goalTitle);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.profile.copyWith(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        goalTitle: _goalController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
        backgroundColor: EcoColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EcoColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: EcoColors.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: EcoColors.surfaceVariant),
        ),
      ),
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            _PhotoSection(photoUrl: widget.profile.photoUrl),
            const SizedBox(height: 32),
            _ProfileTextField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 20),
            _ProfileTextField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _ProfileTextField(
              label: 'Current Goal',
              controller: _goalController,
              icon: Icons.flag_outlined,
              maxLines: 3,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your goal' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final String? photoUrl;

  const _PhotoSection({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: EcoColors.surface, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text(
            'Change Photo',
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: EcoColors.primary,
            backgroundColor: EcoColors.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: EcoColors.secondaryContainer,
      child: const Icon(Icons.person, size: 48, color: EcoColors.secondary),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: EcoColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(color: EcoColors.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: EcoColors.onSurfaceVariant),
            filled: true,
            fillColor: EcoColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EcoColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EcoColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EcoColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

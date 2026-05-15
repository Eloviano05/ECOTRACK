import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/profile_state.dart';
import '../services/user_preferences.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile; // Keeping for goalTitle backwards compatibility

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _goalController;
  late final TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  
  String _avatarPath = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserPreferences.instance.userName.value);
    _emailController = TextEditingController(text: UserPreferences.instance.userEmail.value);
    _goalController = TextEditingController(text: UserPreferences.instance.userGoal.value);
    _passwordController = TextEditingController();
    _avatarPath = UserPreferences.instance.avatarPath.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _goalController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });
    }
  }

  bool _isNetworkPhotoUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newGoal = _goalController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to save.')),
        );
      }
      return;
    }

    // Firebase only accepts network URLs for photoURL; keep local paths offline-only.
    final newAvatarPath =
        _avatarPath.isNotEmpty && _isNetworkPhotoUrl(_avatarPath)
            ? _avatarPath
            : user.photoURL;

    try {
      await user.updateProfile(
        displayName: newName,
        photoURL: newAvatarPath,
      );
      await user.reload();

      if (user.email != newEmail) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      final newPassword = _passwordController.text.trim();
      if (newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null) {
        await UserPreferences.instance.syncWithFirebase(refreshed);
      }

      await UserPreferences.instance.setUserGoal(newGoal);
      if (_avatarPath.isNotEmpty && !_isNetworkPhotoUrl(_avatarPath)) {
        await UserPreferences.instance.setAvatarPath(_avatarPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context);
    }
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
            _PhotoSection(
              avatarPath: _avatarPath,
              onChangePhoto: _pickImage,
            ),
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
            const SizedBox(height: 20),
            _ProfileTextField(
              label: 'New Password (Optional)',
              controller: _passwordController,
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EcoColors.primary,
                  foregroundColor: Colors.white,
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
  final String avatarPath;
  final VoidCallback onChangePhoto;

  const _PhotoSection({required this.avatarPath, required this.onChangePhoto});

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
              child: avatarPath.isNotEmpty
                  ? Image.file(
                      File(avatarPath),
                      fit: BoxFit.cover,
                    )
                  : _fallback(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onChangePhoto,
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
  final bool obscureText;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
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
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
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

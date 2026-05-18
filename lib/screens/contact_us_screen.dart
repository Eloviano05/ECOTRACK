import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  
  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Bug Report',
    'Feature Request',
    'Feedback',
    'General inquiry',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await FirestoreService.instance.submitInquiry(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        category: _selectedCategory ?? 'General inquiry',
        message: _messageController.text.trim(),
        userId: userId,
      );

      if (!mounted) return;

      // Show beautiful Swiss success dialog
      _showSuccessDialog();
      
      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
      setState(() {
        _selectedCategory = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send inquiry: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: EcoColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: EcoColors.primary, width: 2),
          ),
          elevation: 8,
          backgroundColor: EcoColors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F5E9), // Soft green
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), // Deep green
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Inquiry Submitted!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: EcoColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Thank you for reaching out. Our team will review your inquiry and get back to you shortly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: EcoColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to Home
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: EcoColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: EcoColors.primary,
                    ),
                    child: Text(
                      'Go Back',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
        backgroundColor: EcoColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: EcoColors.onSurface),
        ),
        title: Text(
          'Contact Us',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: EcoColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EcoColors.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EcoColors.primaryContainer.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: EcoColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Have a question or feedback? Drop us a line below and we\'ll get right back to you.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: EcoColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 15, color: EcoColors.onSurface),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    label: 'Name',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 18),
                // Email Field
                TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.inter(fontSize: 15, color: EcoColors.onSurface),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegExp.hasMatch(value.trim())) {
                      return 'Please enter a valid email (e.g. name@domain.com)';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: GoogleFonts.inter(fontSize: 15, color: EcoColors.onSurface),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an inquiry category';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    label: 'Inquiry Category',
                    icon: Icons.category_outlined,
                  ),
                  dropdownColor: EcoColors.surfaceContainerLowest,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: EcoColors.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                // Message Field
                TextFormField(
                  controller: _messageController,
                  style: GoogleFonts.inter(fontSize: 15, color: EcoColors.onSurface),
                  maxLines: 5,
                  maxLength: 250,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a message';
                    }
                    if (value.trim().length < 15) {
                      return 'Message must be at least 15 characters (currently ${value.trim().length})';
                    }
                    if (value.trim().length > 250) {
                      return 'Message cannot exceed 250 characters';
                    }
                    return null;
                  },
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) {
                    return Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$currentLength / $maxLength',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: currentLength >= 230
                              ? EcoColors.error
                              : EcoColors.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    );
                  },
                  decoration: _buildInputDecoration(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                ),
                const SizedBox(height: 28),
                // Submit Button
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: EcoColors.primary,
                      foregroundColor: EcoColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: EcoColors.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit Inquiry',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: EcoColors.onSurfaceVariant, fontSize: 14),
      prefixIcon: Icon(icon, color: EcoColors.onSurfaceVariant.withOpacity(0.8), size: 20),
      filled: true,
      fillColor: EcoColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      counterText: '', // Hide standard counter to use custom buildCounter
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EcoColors.outlineVariant, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EcoColors.outlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EcoColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EcoColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EcoColors.error, width: 1.5),
      ),
    );
  }
}

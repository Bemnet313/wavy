import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      final phone = '+251${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';
      ref.read(authProvider.notifier).setPhone(phone); // Store temporarily
      ref.read(authProvider.notifier).registerWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.fbUser != null && previous?.fbUser == null) {
        // If we have a phone number stored in state, update the user profile
        if (next.phone != null) {
           ref.read(apiServiceProvider).updateUser(next.fbUser!.uid, {'phone': next.phone});
        }
        context.go('/preferences');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/signin'),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/wavy_logo_new.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                (locale == 'am' ? 'ይመዝገቡ' : 'REGISTER').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
              ),
              const SizedBox(height: 12),
              Text(
                (locale == 'am' 
                  ? 'የWAVY ተጠቃሚ ይሁኑ' 
                  : 'JOIN THE COMMUNITY.').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1,
                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
              ),
              const SizedBox(height: 48),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      label: locale == 'am' ? 'ኢሜይል' : 'EMAIL',
                      hint: 'user@wavy.app',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 24),
                     _buildTextField(
                      controller: _phoneController,
                      label: locale == 'am' ? 'ስልክ ቁጥር' : 'PHONE NUMBER',
                      hint: '9XXXXXXXX',
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Phone required';
                        // Strip non-digits
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        // Ethiopian mobile: 9 digits starting with 7 or 9
                        if (!RegExp(r'^[79]\d{8}$').hasMatch(digits)) {
                          return locale == 'am'
                              ? 'ትክክለኛ ስልክ ቁጥር ያስገቡ (9 ዲጂት)'
                              : 'Enter a valid Ethiopian number (9 digits)';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        locale == 'am'
                            ? 'ማሳሰቢያ: ስልክ ቁጥር በOTP ይረጋገጣል ሲያትም'
                            : 'Verified via OTP when you publish a listing',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.2),
                          fontWeight: FontWeight.w600,
                        ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _passwordController,
                      label: locale == 'am' ? 'የይለፍ ቃል' : 'PASSWORD',
                      hint: '••••••••',
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: locale == 'am' ? 'የይለፍ ቃል ያረጋግጡ' : 'CONFIRM PASSWORD',
                      hint: '••••••••',
                      obscureText: true,
                      validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          (locale == 'am' ? 'ተመዝገቡ' : 'CREATE ACCOUNT').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locale == 'am' ? 'ቀደም ብለው ተመዝግበዋል? ' : "ALREADY HAVE ACCOUNT? ",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/signin'),
                    child: Text(
                      (locale == 'am' ? 'ይግቡ' : 'SIGN IN').toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.5,
          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          cursorColor: Colors.white,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

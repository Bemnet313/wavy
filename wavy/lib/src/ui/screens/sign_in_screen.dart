import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).loginWithEmail(
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
      if (next.fbUser != null && !next.isLoading) {
        if (next.user != null) {
          context.go('/feed');
        } else {
          context.go('/preferences');
        }
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
                    onTap: () => context.go('/language'),
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
                (locale == 'am' ? 'ይግቡ' : 'SIGN IN').toUpperCase(),
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
                  ? 'እንኳን ደህና መጡ' 
                  : 'DISCOVER THRIFT REVOLUTION.').toUpperCase(),
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
                      controller: _passwordController,
                      label: locale == 'am' ? 'የይለፍ ቃል' : 'PASSWORD',
                      hint: '••••••••',
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 1. Sign In button — white filled
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text(
                          (locale == 'am' ? 'ይግቡ' : 'SIGN IN').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Continue with Google — outlined
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: authState.isLoading ? null : () => ref.read(authProvider.notifier).loginWithGoogle(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        (locale == 'am' ? 'በጉግል ይግቡ' : 'CONTINUE WITH GOOGLE').toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Create Account — outlined, same style as Google
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: authState.isLoading ? null : () => context.go('/signup'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    (locale == 'am' ? 'ተመዝገቡ' : 'CREATE ACCOUNT').toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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

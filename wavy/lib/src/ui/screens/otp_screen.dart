import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == 6;

  Future<void> _verify() async {
    if (!_isComplete) return;
    final success = await ref.read(authProvider.notifier).verifyOtp(_otp);
    if (success && mounted) {
      context.go('/preferences');
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {}); // rebuild to enable/disable verify button
    if (_isComplete) {
      _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        // Top Logo & Back Button
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.go('/phone'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 24),
                              ),
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
                          (locale == 'am' ? 'ቁጥርዎን ያረጋግጡ' : 'VERIFY IDENTITY').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 10, 
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.3),
                                letterSpacing: 1,
                                height: 1.5).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                            children: [
                              TextSpan(
                                text: (locale == 'am'
                                    ? 'ወደ '
                                    : '6-DIGIT ENCRYPTION KEY SENT TO ').toUpperCase(),
                              ),
                              TextSpan(
                                text: widget.phone,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // OTP boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) {
                            return _OtpBox(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              onChanged: (v) => _onDigitChanged(i, v),
                            );
                          }),
                        ),

                        const SizedBox(height: 32),

                        // Demo hint (Minimalist Glass)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: GlassDecoration.dark(opacity: 0.05),
                          child: Row(children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 12),
                            Text(
                              (locale == 'am'
                                  ? 'ለማሳያ: ማንኛውንም 6-ቁጥር ያስገቡ'
                                  : 'DEBUG MODE: ANY SEQUENCE ACCEPTED').toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9, 
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.3),
                                letterSpacing: 1,
                              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                            ),
                          ]),
                        ),

                        const Spacer(),

                        // Verify button (Neon Magenta)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isComplete && !_isLoading ? _verify : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    (locale == 'am' ? 'አረጋግጥ' : 'VERIFY').toUpperCase(),
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

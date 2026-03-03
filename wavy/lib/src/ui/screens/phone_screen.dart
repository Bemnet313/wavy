import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _isValid = value.replaceAll(RegExp(r'\D'), '').length >= 9;
    });
  }

  void _continue() {
    final phone = '+251${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';
    ref.read(authProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    // Listen for verification ID to navigate to OTP screen
    ref.listen(authProvider, (previous, next) {
      if (next.verificationId != null && previous?.verificationId == null) {
        context.push('/otp', extra: next.phone);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

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
                              onTap: () => context.go('/language'),
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
                          (locale == 'am' ? 'ስልክ ቁጥርዎን ያስገቡ' : 'ENTER PHONE').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (locale == 'am'
                              ? 'ዕቃ ለመሸጥ ከፈለጉ ብቻ እናረጋግጣለን'
                              : "SYSTEM REQUIRES PHONE FOR NETWORK IDENTITY.").toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.3),
                            letterSpacing: 1,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                        const SizedBox(height: 48),

                        // Phone input (Minimalist Glass)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _isValid
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            boxShadow: _isValid
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Country code
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🇪🇹', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+251',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  onChanged: _onChanged,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                  ),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    hintText: '9XX XXX XXXX',
                                    hintStyle: GoogleFonts.spaceGrotesk(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Continue button (Neon Magenta)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isValid ? _continue : null,
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
                            child: Text(
                              (locale == 'am' ? 'ቀጥል' : 'CONTINUE').toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
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
            },
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedSize = 'M';
  String _selectedCondition = 'Good';
  String _selectedCategory = 'Tops';
  bool _hasImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset('assets/wavy_logo_new.png', fit: BoxFit.contain),
        ),
        title: Text(
          (locale == 'am' ? 'ዕቃ ይሸጡ' : 'DROP ITEM').toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo upload area (Neon Cyan)
            GestureDetector(
              onTap: () => setState(() => _hasImage = !_hasImage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasImage ? Colors.white : Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: _hasImage ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 20,
                    )
                  ] : null,
                ),
                child: _hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    color: Colors.white, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  (locale == 'am' ? 'ፎቶ ታክሏል ✓' : 'ASSET CAPTURED').toUpperCase(),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _hasImage = false),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: GlassDecoration.dark(opacity: 0.2),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            (locale == 'am' ? 'ፎቶ ያክሉ' : 'UPLOAD VISUALS').toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 1,
                            ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // Title field
            _FormLabel(label: locale == 'am' ? 'ርዕስ' : 'ITEM DESIGNATION'),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: locale == 'am'
                    ? 'ለምሳሌ: ቪንቴጅ ጅንስ ጃኬት'
                    : 'e.g. VINTAGE TECHWEAR',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.02),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Price field
            _FormLabel(label: locale == 'am' ? 'ዋጋ (ብር)' : 'VALUATION (ETB)'),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white.withValues(alpha: 0.1)),
                prefixText: 'ETB ',
                prefixStyle: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.02),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Size selector
            _FormLabel(label: locale == 'am' ? 'መጠን' : 'SPECIFICATIONS (SIZE)'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['XS', 'S', 'M', 'L', 'XL', 'XXL'].map((size) {
                final isSelected = _selectedSize == size;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = size),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        size,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Condition selector
            _FormLabel(label: locale == 'am' ? 'ሁኔታ' : 'CONDITION STATUS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['New', 'Like New', 'Good', 'Fair'].map((cond) {
                final isSelected = _selectedCondition == cond;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCondition = cond),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      cond.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),

            // Publish button (Neon Magenta)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  final isVerified = ref.read(authProvider).isVerified;
                  if (!isVerified) {
                    final phone = ref.read(authProvider).phone ?? '+251900000000';
                    final wantsToVerify = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        title: Text(
                          (locale == 'am' ? 'የስልክ ማረጋገጫ' : 'VERIFICATION REQUIRED').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        content: Text(
                          locale == 'am' 
                            ? 'ዕቃ ለማተም ስልክዎን ማረጋገጥ አለብን። አሁን ኮድ እንላክ?' 
                            : 'PHONE VERIFICATION MANDATORY FOR NETWORK PUBLISHING. INITIATE NOW?',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              (locale == 'am' ? 'ይቅር' : 'ABORT').toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text(
                              (locale == 'am' ? 'ኮድ ላክ' : 'PROCEED').toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    );
                    
                    if (wantsToVerify == true) {
                      ref.read(authProvider.notifier).sendOtp(phone);
                      final verified = await context.push<bool>('/otp', extra: phone);
                      if (verified != true) {
                        return;
                      }
                    } else {
                      return;
                    }
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          (locale == 'am' ? '✅ ዕቃ ታትሟል!' : 'DROP SUCCESSFUL').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context.go('/feed');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  (locale == 'am' ? 'ይለቁ 🚀' : 'INITIALIZE DROP').toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.white.withValues(alpha: 0.3),
        letterSpacing: 1.5,
      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
    );
  }
}


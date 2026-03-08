import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../theme/app_theme.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedSize = 'M';
  String _selectedCondition = 'Good';
  final String _selectedCategory = 'Tops';
  final List<File> _images = [];
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // Restore any saved draft (persists tab switches)
    final draft = ref.read(sellDraftProvider);
    _titleController.text = draft.title;
    _priceController.text = draft.price;
    _selectedSize = draft.size;
    _selectedCondition = draft.condition;
    // Restore image files from paths
    for (final path in draft.imagePaths) {
      final f = File(path);
      if (f.existsSync()) _images.add(f);
    }
    // Keep draft in sync with text controllers
    _titleController.addListener(() {
      ref.read(sellDraftProvider.notifier).updateTitle(_titleController.text);
    });
    _priceController.addListener(() {
      ref.read(sellDraftProvider.notifier).updatePrice(_priceController.text);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        // Check size (< 10MB)
        if (file.lengthSync() > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('IMAGE EXCEEDS 10MB LIMIT.')),
            );
          }
          return;
        }

        setState(() {
          _images.add(file);
        });
        ref.read(sellDraftProvider.notifier).addImage(file.path);
      }
    } catch (e) {
      // Error handling without debugPrint in production
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    ref.read(sellDraftProvider.notifier).removeImage(index);
  }

  Future<void> _publish() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PLEASE UPLOAD AT LEAST ONE VISUAL.')),
      );
      return;
    }

    if (_images.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MAXIMUM 5 VISUALS ALLOWED.')),
      );
      return;
    }

    final price = int.tryParse(_priceController.text) ?? 0;
    if (price < 50 || price > 25000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PRICE MUST BE BETWEEN 50 AND 25,000 ETB.')),
      );
      return;
    }

    final authState = ref.read(authProvider);

    setState(() => _isPublishing = true);

    try {
      final api = ref.read(apiServiceProvider);
      final List<String> imageUrls = [];

      // Pre-generate the Item ID so we can pass it as metadata to storage
      final itemId = api.generateId();

      // 1. Upload Images
      final sellerId = ref.read(authProvider).user?.id ?? 'anonymous';
      for (int i = 0; i < _images.length; i++) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'items/$sellerId/$itemId/${timestamp}_$i.jpg';
        final url = await api.uploadImage(
          _images[i], 
          path, 
          customMetadata: {'itemId': itemId, 'sellerId': sellerId},
        );
        imageUrls.add(url);
      }

      // 2. Publish Item
      final itemData = {
        'id': itemId, // Explicitly use our pre-generated ID
        'title': _titleController.text,
        'price': price,
        'size': _selectedSize,
        'condition': _selectedCondition.toLowerCase(),
        'category': _selectedCategory.toLowerCase(),
        'images': imageUrls,
        'seller_id': authState.fbUser?.uid ?? 'anonymous',
        'tag_id': 'default',
        'status': 'active',
        'swipe_count': 0,
        'interest_count': 0,
      };

      await api.publishItem(itemData);

      final userId = authState.fbUser?.uid;
      if (userId != null) {
        api.logEvent(WavyEvent(
          userId: userId,
          itemId: itemId,
          type: 'item_published',
          action: 'publish',
          timestamp: DateTime.now().toUtc().toIso8601String(),
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drop posted successfully')),
        );
        ref.read(sellDraftProvider.notifier).clear();
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('POST_LIMIT_REACHED')) {
          _showPremiumUpsell();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to post drop: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _showPremiumUpsell() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: WavyTheme.neonCyan, width: 2),
        ),
        title: Text(
          'POST LIMIT REACHED',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Subscribe to Premium to post 10 items per day (300/month) for only 200 Birr/month.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WavyTheme.neonCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final api = ref.read(apiServiceProvider);
                await api.requestPremium();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request sent! We will contact you, or call us at 0942123939.'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(
              'SUBSCRIBE',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
          (locale == 'am' ? 'አዲስ ዕቃ ይልቀቁ' : 'Create a Drop').toUpperCase(),
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
            if (_images.isEmpty)
              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        (locale == 'am' ? 'ፎቶዎችን ያጫኑ' : 'ADD VISUALS').toUpperCase(),
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
              )
            else
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      return GestureDetector(
                        onTap: _images.length >= 5 ? null : _pickImage,
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _images.length >= 5 
                                  ? Colors.red.withValues(alpha: 0.3) 
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _images.length >= 5 ? Icons.block_rounded : Icons.add_rounded, 
                                color: _images.length >= 5 ? Colors.red : Colors.white, 
                                size: 32,
                              ),
                              if (_images.length >= 5) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'LIMIT (5)',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 20,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 40),

            // Title field
            _FormLabel(label: locale == 'am' ? 'የዕቃው ስም' : 'Name your item'),
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
            _FormLabel(label: locale == 'am' ? 'ዋጋ (በብር)' : 'Price (ETB)'),
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
            _FormLabel(label: locale == 'am' ? 'ሳይዝ' : 'Size'),
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
            _FormLabel(label: locale == 'am' ? 'የዕቃው ሁኔታ' : 'Condition'),
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
                onPressed: _isPublishing ? null : () async {
                  // Directly publish — no OTP verification required
                  await _publish();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: _isPublishing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(
                      (locale == 'am' ? 'ይልቀቁ' : 'Post Drop').toUpperCase(),
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


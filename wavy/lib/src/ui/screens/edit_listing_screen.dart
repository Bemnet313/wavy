import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';


class EditListingScreen extends ConsumerStatefulWidget {
  final String itemId;
  const EditListingScreen({super.key, required this.itemId});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedSize = 'M';
  String _selectedCondition = 'Good';

  WavyItem? _original;
  bool _isLoading = true;
  bool _isSaving = false;

  static const _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _conditions = ['New', 'Like New', 'Good', 'Fair'];

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    try {
      final api = ref.read(apiServiceProvider);
      final item = await api.getItem(widget.itemId);
      _original = item;
      _titleController.text = item.title;
      _priceController.text = item.price.toString();
      _selectedSize = item.size;
      // Capitalize condition for dropdown matching
      _selectedCondition = _conditions.firstWhere(
        (c) => c.toLowerCase() == item.condition.toLowerCase(),
        orElse: () => 'Good',
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load item: $e')),
        );
        context.pop();
      }
    }
  }

  Future<void> _save() async {
    final price = int.tryParse(_priceController.text) ?? 0;
    if (price < 50 || price > 25000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PRICE MUST BE BETWEEN 50 AND 25,000 ETB.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiServiceProvider);
      final updates = <String, dynamic>{};

      if (_titleController.text != _original!.title) updates['title'] = _titleController.text;
      if (price != _original!.price) updates['price'] = price;
      if (_selectedSize != _original!.size) updates['size'] = _selectedSize;
      if (_selectedCondition.toLowerCase() != _original!.condition.toLowerCase()) {
        updates['condition'] = _selectedCondition.toLowerCase();
      }

      if (updates.isNotEmpty) {
        await api.updateItem(widget.itemId, updates);
        ref.invalidate(feedProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ LISTING UPDATED')),
        );
        context.pop(true); // Signal refresh to MyListingsScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('UPDATE FAILED: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('DELETE LISTING', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Remove "${_original?.title}"? This cannot be undone.',
            style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(apiServiceProvider).deleteItem(widget.itemId);
      ref.invalidate(feedProvider);
      final uid = ref.read(authProvider).user?.id ?? '';
      if (uid.isNotEmpty) ref.invalidate(sellerListingsProvider(uid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LISTING DELETED')),
        );
        context.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.instance.tr;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tr('edit_listing_title'),
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _delete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview (read-only)
                  if (_original != null && _original!.images.isNotEmpty) ...[
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _original!.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _original!.images[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Title
                  _FormLabel(text: tr('sell_title_label')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price
                  _FormLabel(text: tr('sell_price_label')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Size
                  _FormLabel(text: tr('sell_size_label')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _sizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedSize = size),
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        labelStyle: GoogleFonts.spaceGrotesk(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.w800,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Condition
                  _FormLabel(text: tr('sell_condition_label')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _conditions.map((cond) {
                      final isSelected = _selectedCondition == cond;
                      return ChoiceChip(
                        label: Text(cond.toUpperCase()),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCondition = cond),
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        labelStyle: GoogleFonts.spaceGrotesk(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white30,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(
                              tr('cta_save_changes'),
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, letterSpacing: 2),
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
  final String text;
  const _FormLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.white.withValues(alpha: 0.4),
        letterSpacing: 2,
      ),
    );
  }
}

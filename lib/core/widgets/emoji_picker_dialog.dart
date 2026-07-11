import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

/// A nice searchable emoji picker dialog.
/// Returns the selected emoji string via [Navigator.pop].
class EmojiPickerDialog extends StatefulWidget {
  const EmojiPickerDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const EmojiPickerDialog(),
    );
  }

  @override
  State<EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends State<EmojiPickerDialog> {
  static const _categories = [
    _EmojiCategory(
      name: 'Finance',
      emojis: ['💰', '💸', '💳', '🏦', '💵', '💴', '💶', '💷', '🪙', '📈', '📉', '🧾', '💹', '🤑', '🏧'],
    ),
    _EmojiCategory(
      name: 'Food',
      emojis: ['🍔', '🍕', '🍣', '🍜', '🍱', '🥗', '🍦', '☕', '🧋', '🍺', '🍷', '🥤', '🍰', '🥐', '🌮', '🍛', '🍚', '🥘'],
    ),
    _EmojiCategory(
      name: 'Transport',
      emojis: ['✈️', '🚗', '🚕', '🚌', '🚂', '🛵', '🚲', '⛽', '🛻', '🚁', '🚢', '🛺', '🚦', '🅿️'],
    ),
    _EmojiCategory(
      name: 'Shopping',
      emojis: ['🛒', '👕', '👗', '👠', '👜', '💄', '💍', '🛍️', '👟', '🧣', '👒', '🎒', '💎', '🪞'],
    ),
    _EmojiCategory(
      name: 'Health',
      emojis: ['🏥', '💊', '🩺', '🩹', '💉', '🧬', '🏋️', '🧘', '🏃', '🩻', '🫀', '🌡️', '🧠', '👁️'],
    ),
    _EmojiCategory(
      name: 'Entertainment',
      emojis: ['🎮', '🎬', '🎵', '🎸', '🎲', '🎯', '🎭', '🎪', '🎢', '🎡', '🏀', '⚽', '🎤', '📺', '🎹'],
    ),
    _EmojiCategory(
      name: 'Education',
      emojis: ['📚', '📖', '✏️', '🎓', '🖊️', '📓', '📝', '📐', '🔬', '🔭', '💻', '🖥️', '📡', '🧪'],
    ),
    _EmojiCategory(
      name: 'Home',
      emojis: ['🏠', '🛋️', '🪑', '🛏️', '🪴', '🧹', '🔧', '🔑', '💡', '🪟', '🚿', '🛁', '🪣', '🧺'],
    ),
    _EmojiCategory(
      name: 'Misc',
      emojis: ['📦', '🎁', '💌', '📅', '🗺️', '⚙️', '🔖', '📌', '🧩', '🗑️', '🪝', '🧲', '🪄', '⭐'],
    ),
  ];

  String _searchQuery = '';
  int _selectedTab = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredEmojis {
    if (_searchQuery.isEmpty) {
      return _categories[_selectedTab].emojis;
    }
    return _categories
        .expand((c) => c.emojis)
        .where((e) => e.contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        width: double.infinity,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pick an Emoji',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  if (v.isNotEmpty) _selectedTab = 0;
                }),
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search emojis…',
                  hintStyle: GoogleFonts.outfit(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? colorScheme.surface.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ),
            const Gap(12),

            // Category Tabs
            if (_searchQuery.isEmpty)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedTab == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00BCD4)
                              : (isDark ? const Color(0xFF2A2F3F) : colorScheme.surfaceContainerHighest),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _categories[index].name,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Gap(8),

            // Emoji Grid
            Expanded(
              child: _filteredEmojis.isEmpty
                  ? Center(
                      child: Text(
                        'No emojis found',
                        style: GoogleFonts.outfit(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: _filteredEmojis.length,
                      itemBuilder: (context, index) {
                        final emoji = _filteredEmojis[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.pop(context, emoji),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCategory {
  final String name;
  final List<String> emojis;
  const _EmojiCategory({required this.name, required this.emojis});
}

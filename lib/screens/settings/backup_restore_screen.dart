import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../provider/backup_provider.dart';

const _kLastBackupKey = 'last_backup_date';

/// Backup & Restore screen — export and import Spencer JSON backups.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  Future<void> _loadLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lastBackupDate = prefs.getString(_kLastBackupKey));
  }

  Future<void> _saveLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    await prefs.setString(_kLastBackupKey, str);
    setState(() => _lastBackupDate = str);
  }

  Future<void> _handleExport() async {
    // Let user pick directory
    String? selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir == null) return;

    final fileName =
        'spencer_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    final fullPath = p.join(selectedDir, fileName);

    if (!mounted) return;
    final notifier = ref.read(backupProvider.notifier);
    await notifier.exportBackup(fullPath);

    if (!mounted) return;
    final result = ref.read(backupProvider);
    if (result is AsyncError) {
      _showError(result.error.toString());
    } else {
      await _saveLastBackupDate();
      _showSuccessDialog(
        title: 'Backup Exported!',
        message: 'Your backup has been saved to:\n\n$fullPath',
        icon: '✅',
      );
    }
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final filePath = result.files.single.path!;

    if (!mounted) return;

    // Show merge vs replace dialog
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Import Backup',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'How would you like to import this backup?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00BCD4)),
            ),
            child: Text(
              'Merge',
              style: GoogleFonts.outfit(color: const Color(0xFF00BCD4)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Replace All', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    final notifier = ref.read(backupProvider.notifier);
    await notifier.importBackup(filePath, replaceExisting: choice);

    if (!mounted) return;
    final state = ref.read(backupProvider);
    if (state is AsyncError) {
      _showError(state.error.toString());
    } else {
      final summary = state.value;
      if (summary != null) {
        _showSuccessDialog(
          title: 'Import Complete!',
          icon: '🎉',
          message:
              'Successfully imported:\n\n'
              '• ${summary['users']} User\n'
              '• ${summary['categories']} Categories\n'
              '• ${summary['expenses']} Expenses',
        );
      } else {
        _showSuccessDialog(
          title: 'Import Complete!',
          icon: '🎉',
          message: 'Data imported successfully.',
        );
      }
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('❌ ', style: TextStyle(fontSize: 20)),
            Text(
              'Error',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(msg, style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.outfit(color: const Color(0xFF00BCD4)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required String icon,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const Gap(8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backupState = ref.watch(backupProvider);
    final isLoading = backupState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Backup & Restore',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(
                    0xFF00BCD4,
                  ).withValues(alpha: isDark ? 0.25 : 0.1),
                  const Color(
                    0xFF0097A7,
                  ).withValues(alpha: isDark ? 0.1 : 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 28)),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Backup',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00BCD4),
                        ),
                      ),
                      Text(
                        'All data stays on your device. Export to a JSON file you can restore anytime.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const Gap(24),

          // Backup Card
          _ActionCard(
            icon: Icons.cloud_upload_outlined,
            emoji: '📤',
            title: 'Export Backup',
            subtitle: 'Save all your data to a JSON file',
            actionLabel: 'Export Now',
            actionColor: const Color(0xFF00BCD4),
            isDark: isDark,
            isLoading: isLoading,
            onTap: _handleExport,
            index: 0,
          ),
          const Gap(12),

          // Restore Card
          _ActionCard(
            icon: Icons.cloud_download_outlined,
            emoji: '📥',
            title: 'Import Backup',
            subtitle: 'Restore data from a JSON backup file',
            actionLabel: 'Import File',
            actionColor: const Color(0xFF7C3AED),
            isDark: isDark,
            isLoading: isLoading,
            onTap: _handleImport,
            index: 1,
          ),
          const Gap(24),

          // Info Section
          Material(
            color: isDark ? const Color(0xFF252A3A) : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isDark
                  ? BorderSide.none
                  : BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
            ),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Last Backup',
                  value: _lastBackupDate ?? 'Never',
                  icon: Icons.history_rounded,
                ),
                const Divider(height: 1),
                _InfoRow(
                  label: 'App Version',
                  value: 'v${AppConstants.appVersion}',
                  icon: Icons.info_outline_rounded,
                ),
                const Divider(height: 1),
                _InfoRow(
                  label: 'Backup Format',
                  value: 'JSON v2',
                  icon: Icons.code_rounded,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const Gap(32),

          // Merge vs Replace description
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 16)),
                    const Gap(8),
                    Text(
                      'Import Modes',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Text(
                  '• Merge: Adds new records, skips duplicates\n• Replace All: Wipes existing data and replaces it completely',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color actionColor;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;
  final int index;

  const _ActionCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionColor,
    required this.isDark,
    required this.isLoading,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
          color: isDark ? const Color(0xFF252A3A) : Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isDark
                ? BorderSide.none
                : BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: InkWell(
            onTap: isLoading ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: actionColor,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + index * 80),
          duration: 400.ms,
        )
        .slideY(begin: 0.05, end: 0);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00BCD4)),
          const Gap(12),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

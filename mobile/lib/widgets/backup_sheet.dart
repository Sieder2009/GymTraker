import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../state/toast_provider.dart';
import '../theme/app_colors.dart';

const int _kBackupFormatVersion = 1;

/// Local-only backup/restore: everything the app has stored gets bundled
/// into one JSON blob the user copies out via the clipboard (no account,
/// no server — matches the app's "100% on this device" model) and can
/// paste back in, on this device or another, to restore it.
Future<void> showBackupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _BackupSheet(),
  );
}

class _BackupSheet extends StatefulWidget {
  const _BackupSheet();

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  final TextEditingController _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final storage = context.read<StorageService>();
    final payload = jsonEncode({
      'app': 'ironpeak',
      'version': _kBackupFormatVersion,
      'data': storage.exportAll(),
    });
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    context.read<ToastProvider>().show(AppLocalizations.of(context)!.toastCopiedToClipboard);
  }

  Future<void> _restore() async {
    final t = AppLocalizations.of(context)!;
    final toast = context.read<ToastProvider>();
    final Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(_importController.text.trim());
      if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
        throw const FormatException('missing data');
      }
      parsed = (decoded['data'] as Map).cast<String, dynamic>();
    } catch (_) {
      toast.show(t.toastRestoreInvalid);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.restoreConfirmTitle),
        content: Text(t.restoreConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.actionCancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.actionRestore, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<StorageService>().importAll(parsed);
    if (!mounted) return;
    toast.show(t.toastRestoreDone);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.titleBackup, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(t.backupExportHint, style: TextStyle(color: colors.mut)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: Text(t.actionCopyToClipboard),
                ),
              ),
              const SizedBox(height: 24),
              Text(t.backupImportHint, style: TextStyle(color: colors.mut)),
              const SizedBox(height: 8),
              TextField(
                controller: _importController,
                maxLines: 4,
                decoration: InputDecoration(hintText: t.hintBackupPaste),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _restore, child: Text(t.actionRestore)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

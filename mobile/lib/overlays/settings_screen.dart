import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_version.dart';
import '../services/update_service.dart';
import '../state/appearance_provider.dart';
import '../theme/app_colors.dart';

const String _kHelpEmail = 'thomasjohann09@gmail.com';
const String _kHelpPhone = '3914126668';

const List<Color> _kColorPresets = [
  Color(0xFF2F6FEB),
  Color(0xFF5588FF),
  Color(0xFF0EA884),
  Color(0xFF1FD6A8),
  Color(0xFF6D5CE8),
  Color(0xFF9585FF),
  Color(0xFFC98A10),
  Color(0xFFE0A83A),
  Color(0xFF1FA76A),
  Color(0xFF35C98A),
  Color(0xFFE24B4A),
  Color(0xFFD4537E),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checking = false;
  UpdateCheckResult? _result;

  Future<void> _checkForUpdate() async {
    setState(() => _checking = true);
    final result = await UpdateService.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  Future<void> _openRelease(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _sendEmail() async {
    final uri = Uri(scheme: 'mailto', path: _kHelpEmail);
    await launchUrl(uri);
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _kHelpPhone);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final appearance = context.watch<AppearanceProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Einstellungen'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('APP-VERSION', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Installiert: $kAppVersion'),
                    if (_result != null) ...[
                      const SizedBox(height: 10),
                      if (_result!.hasUpdate)
                        Text(
                          'Neue Version verfügbar: ${_result!.latestVersion}',
                          style: TextStyle(color: colors.green, fontWeight: FontWeight.w700),
                        )
                      else if (_result!.error != null)
                        Text(_result!.error!, style: TextStyle(color: colors.mut))
                      else
                        Text('Du hast die neueste Version.', style: TextStyle(color: colors.mut)),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _checking ? null : _checkForUpdate,
                          child: Text(_checking ? 'Suche …' : 'Nach Updates suchen'),
                        ),
                        if (_result?.hasUpdate == true && _result?.releaseUrl != null) ...[
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _openRelease(_result!.releaseUrl!),
                            child: const Text('Herunterladen'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('FARBEN', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Primärfarbe', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    _ColorSwatchRow(
                      selected: appearance.accent ?? colors.accent,
                      onSelect: (c) => context.read<AppearanceProvider>().setAccent(c),
                    ),
                    const SizedBox(height: 20),
                    Text('Sekundärfarbe', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    _ColorSwatchRow(
                      selected: appearance.secondary ?? colors.secondary,
                      onSelect: (c) => context.read<AppearanceProvider>().setSecondary(c),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.read<AppearanceProvider>().reset(),
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('HILFE', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('E-Mail'),
                    subtitle: const Text(_kHelpEmail),
                    onTap: _sendEmail,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.call_outlined),
                    title: const Text('Anrufen'),
                    subtitle: const Text(_kHelpPhone),
                    onTap: _call,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({required this.selected, required this.onSelect});

  final Color selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in _kColorPresets)
          GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: selected == c ? Border.all(color: colors.txt, width: 3) : null,
              ),
            ),
          ),
      ],
    );
  }
}

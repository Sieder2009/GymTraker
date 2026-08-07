import 'dart:convert';
import 'dart:io';

import '../data/app_version.dart';

const String _kReleasesLatestUrl =
    'https://api.github.com/repos/Sieder2009/GymTraker/releases/latest';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.releaseUrl,
    this.error,
  });

  final bool hasUpdate;
  final String? latestVersion;
  final String? releaseUrl;
  final String? error;
}

/// Checks GitHub's "latest release" API against [kAppVersion]. Only finds
/// anything once a real version-tagged release exists (the CI workflow only
/// creates a GitHub Release — not just a build artifact — when triggered by
/// a `vX.Y.Z` tag push).
class UpdateService {
  static Future<UpdateCheckResult> checkForUpdate() async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse(_kReleasesLatestUrl))
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.userAgentHeader, 'ironpeak-fitness-app');
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return const UpdateCheckResult(
          hasUpdate: false,
          error: 'Es gibt noch keine veröffentlichte Version zum Vergleichen.',
        );
      }
      if (response.statusCode != 200) {
        return UpdateCheckResult(
          hasUpdate: false,
          error: 'GitHub antwortete mit Status ${response.statusCode}.',
        );
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final releaseUrl = json['html_url'] as String?;
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;

      if (latest.isEmpty) {
        return const UpdateCheckResult(hasUpdate: false, error: 'Antwort enthielt keine Versionsnummer.');
      }

      return UpdateCheckResult(
        hasUpdate: _isNewer(latest, kAppVersion),
        latestVersion: latest,
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      return const UpdateCheckResult(
        hasUpdate: false,
        error: 'Verbindung zu GitHub fehlgeschlagen. Hast du Internet?',
      );
    } finally {
      client.close();
    }
  }

  static bool _isNewer(String remote, String local) {
    final r = _parseVersion(remote);
    final l = _parseVersion(local);
    for (var i = 0; i < 3; i++) {
      if (r[i] != l[i]) return r[i] > l[i];
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}

// Probe for Flutter/OneDrive file-lock issues — appends NDJSON to debug-2b2511.log
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() {
  // #region agent log
  final root = Directory.current.path.toLowerCase();
  final symlinkDir = Directory('windows/flutter/ephemeral/.plugin_symlinks');
  Map<String, Object?> data({
    required String hypothesisId,
    Map<String, Object?> extra = const {},
  }) =>
      <String, Object?>{
        'sessionId': '2b2511',
        'runId': Platform.environment['ECOTRACK_RUN_ID'] ?? 'probe',
        'hypothesisId': hypothesisId,
        'location': 'tool/sync_lock_probe.dart',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'message': 'cloud_sync_lock_probe',
        'data': <String, Object?>{
          'cwd': root.replaceAll(RegExp(r'[^\w\\/]'), '_'),
          'pathLooksOneDrive':
              root.contains('onedrive') || root.contains('icloud'),
          'pluginSymlinksExists': symlinkDir.existsSync(),
          ...extra,
        },
      };

  void emit(String hypothesisId,
      [Map<String, Object?> extra = const {}]) {
    final path = '${Directory.current.path}/debug-2b2511.log';
    File(path).writeAsStringSync(
        '${jsonEncode(data(hypothesisId: hypothesisId, extra: extra))}\n',
        mode: FileMode.append);
  }

  // F: sync path + symlink dir state
  try {
    emit('F', {});
  } catch (_) {
    stderr.writeln('sync_lock_probe: could not emit F');
  }

  // F-bis: directory listing / readability
  var listOk = false;
  var entryCount = 0;
  var listError = '';
  if (symlinkDir.existsSync()) {
    try {
      entryCount = symlinkDir.listSync().length;
      listOk = true;
    } catch (e, st) {
      listOk = false;
      listError = '${e.runtimeType}:${e.toString().split('\n').first}';
      stderr.writeln('sync_lock_probe: list symlink dir failed:\n$st');
    }
  }
  emit('F', {
    'symlinksListOk': listOk,
    'symlinksChildCount': entryCount,
    if (listError.isNotEmpty)
      'symlinksError': listError.length > 240
          ? listError.substring(0, 240)
          : listError,
  });

  // J: concurrent flutter dart process hint (cheap check)
  var dartProcesses = -1;
  try {
    if (Platform.isWindows) {
      final r = Process.runSync('tasklist.exe', ['/FI', 'IMAGENAME eq dart.exe', '/FO', 'CSV']);
      final out = '${r.stdout}';
      dartProcesses =
          LineSplitter.split(out).length - (out.trim().isEmpty ? 1 : 1);
      if (dartProcesses < 0) dartProcesses = 0;
    }
  } catch (_) {
    dartProcesses = -1;
  }
  emit('J', {'tasklistDartRowEstimate': dartProcesses});

  stdout.writeln('sync_lock_probe: wrote NDJSON lines to debug-2b2511.log');
// #endregion
}

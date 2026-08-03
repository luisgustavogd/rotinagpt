import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../domain/backup/backup_manifest.dart';
import '../../domain/backup/import_diff_service.dart';
import '../../domain/backup/import_preview.dart';
import '../remote/firestore_paths.dart';
import 'backup_service.dart' show kBackupFormatVersion;

class BackupCorruptedException implements Exception {
  BackupCorruptedException(this.message);
  final String message;
  @override
  String toString() => 'BackupCorruptedException: $message';
}

class BackupVersionMismatchException implements Exception {
  BackupVersionMismatchException(this.foundVersion);
  final String foundVersion;
  @override
  String toString() =>
      'BackupVersionMismatchException: formato $foundVersion não suportado '
      '(esperado $kBackupFormatVersion)';
}

class ParsedBackup {
  const ParsedBackup({required this.manifest, required this.data});

  final BackupManifest manifest;
  final Map<String, dynamic> data;
}

/// Coleções que são uma lista de documentos (todas exceto `profile`, que é um
/// documento único).
const _listCollections = [
  'goalHistory',
  'foods',
  'meals',
  'weightEntries',
  'bodyMeasureEntries',
  'medicationPlans',
  'medicationEntries',
  'activityPlans',
  'activityEntries',
  'labResults',
  'reminders',
];

/// RF-084/RN-010 — lê e valida um arquivo de backup (versão + checksum
/// sha256), calcula um resumo do que vai mudar antes de aplicar, e só então
/// escreve — nunca sobrescreve dados sem essa confirmação prévia. Escreve em
/// lotes (`WriteBatch`) de até 500 operações (limite da API do Firestore); a
/// escrita é idempotente porque usa sempre o `id` original do documento como
/// chave, então reaplicar o mesmo backup não duplica registros.
class BackupReader {
  BackupReader({required this.firestore, required this.paths});

  final FirebaseFirestore firestore;
  final FirestorePaths paths;

  ParsedBackup parseAndValidate(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    ArchiveFile? manifestFile;
    ArchiveFile? dataFile;
    for (final file in archive.files) {
      if (file.name == 'manifest.json') manifestFile = file;
      if (file.name == 'data.json') dataFile = file;
    }
    if (manifestFile == null || dataFile == null) {
      throw BackupCorruptedException(
        'Arquivo de backup incompleto: faltando manifest.json ou data.json.',
      );
    }

    final Map<String, dynamic> manifestJson;
    final Map<String, dynamic> data;
    try {
      manifestJson =
          jsonDecode(utf8.decode(manifestFile.content as List<int>))
              as Map<String, dynamic>;
      data =
          jsonDecode(utf8.decode(dataFile.content as List<int>))
              as Map<String, dynamic>;
    } catch (e) {
      throw BackupCorruptedException('JSON inválido no arquivo de backup: $e');
    }

    final manifest = BackupManifest.fromJson(manifestJson);
    if (manifest.version != kBackupFormatVersion) {
      throw BackupVersionMismatchException(manifest.version);
    }

    final dataBytes = utf8.encode(jsonEncode(data));
    final checksum = sha256.convert(dataBytes).toString();
    if (checksum != manifest.checksumSha256) {
      throw BackupCorruptedException(
        'Checksum não confere: o arquivo de backup pode estar corrompido.',
      );
    }

    return ParsedBackup(manifest: manifest, data: data);
  }

  Future<ImportPreview> computePreview(ParsedBackup parsed) async {
    final existingByCollection = <String, Map<String, String>>{};
    final incomingByCollection = <String, Map<String, String>>{};

    for (final collection in _listCollections) {
      final path = _pathFor(collection);
      final snapshot = await firestore.collection(path).get();
      existingByCollection[collection] = {
        for (final doc in snapshot.docs) doc.id: _hashOf(doc.data()),
      };

      final incomingList = (parsed.data[collection] as List? ?? [])
          .cast<Map<String, dynamic>>();
      incomingByCollection[collection] = {
        for (final item in incomingList)
          item['id'] as String: _hashOf(item, excludeId: true),
      };
    }

    // Documento único de perfil, tratado como uma "coleção" de 1 item.
    final profileSnap = await firestore.doc(paths.profileDoc).get();
    final existingProfileHash = profileSnap.data() == null
        ? null
        : _hashOf(profileSnap.data()!);
    final incomingProfile = parsed.data['profile'] as Map<String, dynamic>?;
    existingByCollection['profile'] = existingProfileHash == null
        ? {}
        : {'main': existingProfileHash};
    incomingByCollection['profile'] = incomingProfile == null
        ? {}
        : {'main': _hashOf(incomingProfile)};

    return const ImportDiffService().computePreview(
      manifestVersion: parsed.manifest.version,
      existingByCollection: existingByCollection,
      incomingByCollection: incomingByCollection,
    );
  }

  Future<void> applyRestore(ParsedBackup parsed) async {
    final writes = <_PendingWrite>[];

    final incomingProfile = parsed.data['profile'] as Map<String, dynamic>?;
    if (incomingProfile != null) {
      writes.add(
        _PendingWrite(firestore.doc(paths.profileDoc), incomingProfile),
      );
    }

    for (final collection in _listCollections) {
      final path = _pathFor(collection);
      final incomingList = (parsed.data[collection] as List? ?? [])
          .cast<Map<String, dynamic>>();
      for (final item in incomingList) {
        final id = item['id'] as String;
        final withoutId = Map<String, dynamic>.from(item)..remove('id');
        writes.add(
          _PendingWrite(firestore.collection(path).doc(id), withoutId),
        );
      }
    }

    const batchLimit = 500;
    for (var i = 0; i < writes.length; i += batchLimit) {
      final batch = firestore.batch();
      final chunk = writes.skip(i).take(batchLimit);
      for (final w in chunk) {
        batch.set(w.reference, w.data);
      }
      await batch.commit();
    }
  }

  String _pathFor(String collection) {
    switch (collection) {
      case 'goalHistory':
        return paths.goalHistory;
      case 'foods':
        return paths.foods;
      case 'meals':
        return paths.meals;
      case 'weightEntries':
        return paths.weightEntries;
      case 'bodyMeasureEntries':
        return paths.bodyMeasureEntries;
      case 'medicationPlans':
        return paths.medicationPlans;
      case 'medicationEntries':
        return paths.medicationEntries;
      case 'activityPlans':
        return paths.activityPlans;
      case 'activityEntries':
        return paths.activityEntries;
      case 'labResults':
        return paths.labResults;
      case 'reminders':
        return paths.reminders;
      default:
        throw ArgumentError('Coleção desconhecida: $collection');
    }
  }

  String _hashOf(Map<String, dynamic> raw, {bool excludeId = false}) {
    final normalized = Map<String, dynamic>.from(_normalize(raw) as Map);
    if (excludeId) normalized.remove('id');
    final sortedKeys = normalized.keys.toList()..sort();
    final ordered = {for (final k in sortedKeys) k: normalized[k]};
    return sha1.convert(utf8.encode(jsonEncode(ordered))).toString();
  }

  dynamic _normalize(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return {for (final e in value.entries) e.key: _normalize(e.value)};
    }
    if (value is List) return value.map(_normalize).toList();
    return value;
  }
}

class _PendingWrite {
  _PendingWrite(this.reference, this.data);
  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> data;
}

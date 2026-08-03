import 'import_preview.dart';

/// RN-010 — a importação de backup nunca sobrescreve dados sem confirmação e
/// resumo prévio. Esta classe calcula, para cada coleção, quantos documentos
/// seriam criados, atualizados (mesmo id, conteúdo diferente) ou permaneceriam
/// inalterados — puramente a partir de mapas id->hash, sem tocar em Firestore.
class ImportDiffService {
  const ImportDiffService();

  ImportPreview computePreview({
    required String manifestVersion,
    required Map<String, Map<String, String>> existingByCollection,
    required Map<String, Map<String, String>> incomingByCollection,
  }) {
    final diffs = <CollectionDiff>[];
    for (final collection in incomingByCollection.keys) {
      final existing = existingByCollection[collection] ?? const {};
      final incoming = incomingByCollection[collection]!;

      var toCreate = 0;
      var toUpdate = 0;
      var unchanged = 0;
      incoming.forEach((id, hash) {
        final existingHash = existing[id];
        if (existingHash == null) {
          toCreate++;
        } else if (existingHash != hash) {
          toUpdate++;
        } else {
          unchanged++;
        }
      });

      diffs.add(
        CollectionDiff(
          collection: collection,
          toCreate: toCreate,
          toUpdate: toUpdate,
          unchanged: unchanged,
        ),
      );
    }
    return ImportPreview(diffs: diffs, manifestVersion: manifestVersion);
  }
}

/// RN-010 — resumo do que vai mudar antes de aplicar uma restauração, exibido
/// ao usuário para confirmação explícita.
class CollectionDiff {
  const CollectionDiff({
    required this.collection,
    required this.toCreate,
    required this.toUpdate,
    required this.unchanged,
  });

  final String collection;
  final int toCreate;
  final int toUpdate;
  final int unchanged;

  int get totalAffected => toCreate + toUpdate;
}

class ImportPreview {
  const ImportPreview({required this.diffs, required this.manifestVersion});

  final List<CollectionDiff> diffs;
  final String manifestVersion;

  bool get hasChanges => diffs.any((d) => d.totalAffected > 0);
}

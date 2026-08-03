import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/backup/import_diff_service.dart';

void main() {
  test(
    'RN-010: calcula criações, atualizações e itens inalterados por coleção',
    () {
      final preview = const ImportDiffService().computePreview(
        manifestVersion: '1.0',
        existingByCollection: {
          'weightEntries': {'a': 'hash-a', 'b': 'hash-b'},
        },
        incomingByCollection: {
          'weightEntries': {
            'a': 'hash-a', // inalterado
            'b': 'hash-b-changed', // atualizado
            'c': 'hash-c', // novo
          },
        },
      );

      final diff = preview.diffs.single;
      expect(diff.toCreate, 1);
      expect(diff.toUpdate, 1);
      expect(diff.unchanged, 1);
      expect(preview.hasChanges, isTrue);
    },
  );
}

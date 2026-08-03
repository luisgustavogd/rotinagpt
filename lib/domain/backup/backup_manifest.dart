/// RNF-008 — todo backup carrega versão, data e verificação básica de
/// integridade.
class BackupManifest {
  const BackupManifest({
    required this.version,
    required this.createdAt,
    required this.checksumSha256,
    required this.collectionCounts,
  });

  final String version;
  final DateTime createdAt;
  final String checksumSha256;

  /// Nome da coleção -> número de documentos, usado no resumo de importação.
  final Map<String, int> collectionCounts;

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'checksumSha256': checksumSha256,
    'collectionCounts': collectionCounts,
  };

  static BackupManifest fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      version: json['version'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      checksumSha256: json['checksumSha256'] as String,
      collectionCounts: Map<String, int>.from(json['collectionCounts'] as Map),
    );
  }
}

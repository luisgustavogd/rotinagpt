import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di/providers.dart';
import '../../data/backup/backup_reader.dart';
import '../../data/backup/csv_exporters.dart';
import '../../data/backup/pdf_report_builder.dart';
import '../../domain/notifications/reminder.dart';
import '../../domain/reports/weekly_summary_calculator.dart';

final _profileProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});

final _remindersProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(reminderRepositoryProvider).watchAll();
});

/// RF-004 (edição de perfil), RF-060/061/062 (lembretes), RF-082 a RF-085
/// (exportação, backup, restauração, exclusão) e privacidade (seção 8/9 do
/// documento).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_profileProvider);
    final remindersAsync = ref.watch(_remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          profileAsync.when(
            data: (profile) => ListTile(
              title: Text(profile?.name ?? 'Perfil'),
              subtitle: Text(
                profile == null
                    ? 'Nenhum perfil configurado'
                    : 'Meta: ${profile.targetWeightKg} kg · ${profile.targetProteinG} g proteína/dia',
              ),
            ),
            loading: () => const ListTile(title: Text('Carregando perfil...')),
            error: (e, _) => ListTile(title: Text('Erro: $e')),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Lembretes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          remindersAsync.when(
            data: (reminders) => Column(
              children: [
                for (final r in reminders)
                  SwitchListTile(
                    title: Text('${_typeLabel(r.type)} · ${r.time}'),
                    subtitle: Text(_recurrenceLabel(r)),
                    value: r.active,
                    onChanged: (v) async {
                      await ref
                          .read(reminderRepositoryProvider)
                          .save(
                            Reminder(
                              id: r.id,
                              type: r.type,
                              time: r.time,
                              recurrence: r.recurrence,
                              weekdays: r.weekdays,
                              active: v,
                              relatedItemId: r.relatedItemId,
                              label: r.label,
                            ),
                          );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.add_alarm),
                  title: const Text('Adicionar lembrete'),
                  onTap: () => _addReminder(context, ref),
                ),
              ],
            ),
            loading: () =>
                const ListTile(title: Text('Carregando lembretes...')),
            error: (e, _) => ListTile(title: Text('Erro: $e')),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Dados', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Exportar backup completo'),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Restaurar backup'),
            onTap: () => _restoreBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Exportar refeições/peso/atividade em CSV'),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Exportar relatório semanal em PDF'),
            onTap: () => _exportPdf(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Apagar todos os dados',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _deleteAllData(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () => ref.read(authGatewayProvider).signOut(),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Seus dados sincronizam apenas entre os aparelhos da sua própria '
              'conta, protegidos por regras de acesso restritas ao seu '
              'usuário. Nada é compartilhado com terceiros. Este app não é um '
              'dispositivo médico.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(ReminderType type) => switch (type) {
    ReminderType.meal => 'Refeição',
    ReminderType.protein => 'Proteína',
    ReminderType.activity => 'Atividade',
    ReminderType.weight => 'Peso',
    ReminderType.medication => 'Medicação',
  };

  String _recurrenceLabel(Reminder r) => switch (r.recurrence) {
    ReminderRecurrence.once => 'Uma vez',
    ReminderRecurrence.daily => 'Todos os dias',
    ReminderRecurrence.weekly => 'Semanal',
  };

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    var type = ReminderType.meal;
    var recurrence = ReminderRecurrence.daily;
    var time = const TimeOfDay(hour: 8, minute: 0);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ReminderType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: ReminderType.meal,
                    child: Text('Refeição'),
                  ),
                  DropdownMenuItem(
                    value: ReminderType.protein,
                    child: Text('Proteína'),
                  ),
                  DropdownMenuItem(
                    value: ReminderType.activity,
                    child: Text('Atividade'),
                  ),
                  DropdownMenuItem(
                    value: ReminderType.weight,
                    child: Text('Peso'),
                  ),
                  DropdownMenuItem(
                    value: ReminderType.medication,
                    child: Text('Medicação'),
                  ),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              DropdownButtonFormField<ReminderRecurrence>(
                initialValue: recurrence,
                decoration: const InputDecoration(labelText: 'Recorrência'),
                items: const [
                  DropdownMenuItem(
                    value: ReminderRecurrence.daily,
                    child: Text('Todos os dias'),
                  ),
                  DropdownMenuItem(
                    value: ReminderRecurrence.once,
                    child: Text('Uma vez'),
                  ),
                ],
                onChanged: (v) => setState(() => recurrence = v!),
              ),
              ListTile(
                title: const Text('Horário'),
                trailing: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked != null) setState(() => time = picked);
                },
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  // RF-063 — permissão só é pedida agora, ao configurar o
                  // primeiro lembrete.
                  await ref
                      .read(notificationServiceProvider)
                      .requestPermission();
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: const Text('Salvar lembrete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      await ref
          .read(reminderRepositoryProvider)
          .save(
            Reminder(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              type: type,
              time:
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              recurrence: recurrence,
              active: true,
            ),
          );
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final bytes = await ref.read(backupServiceProvider).buildBackupArchive();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/backup-rotinagpt-${DateTime.now().millisecondsSinceEpoch}.zip',
    );
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final file = result?.files.single;
    if (file == null) return;
    final bytes = await file.readAsBytes();

    final reader = ref.read(backupReaderProvider);
    try {
      final parsed = reader.parseAndValidate(bytes);
      final preview = await reader.computePreview(parsed);

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar restauração'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('As seguintes mudanças serão aplicadas:'),
                const SizedBox(height: 8),
                for (final diff in preview.diffs)
                  if (diff.totalAffected > 0)
                    Text(
                      '${diff.collection}: +${diff.toCreate} novos, ${diff.toUpdate} atualizados',
                    ),
                if (!preview.hasChanges)
                  const Text('Nenhuma mudança detectada.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await reader.applyRestore(parsed);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restaurado com sucesso.')),
          );
        }
      }
    } on BackupVersionMismatchException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este arquivo de backup é de uma versão incompatível.',
            ),
          ),
        );
      }
    } on BackupCorruptedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo de backup corrompido ou inválido.'),
          ),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final farPast = DateTime(2000);
    final farFuture = DateTime(2100);
    final meals = await ref
        .read(mealRepositoryProvider)
        .watchRange(farPast, farFuture)
        .first;
    final weights = await ref
        .read(measurementRepositoryProvider)
        .watchWeights()
        .first;
    final activities = await ref
        .read(activityRepositoryProvider)
        .watchEntries()
        .first;

    final dir = await getTemporaryDirectory();
    final mealsFile = File('${dir.path}/refeicoes.csv')
      ..writeAsStringSync(CsvExporters.meals(meals));
    final weightsFile = File('${dir.path}/pesos.csv')
      ..writeAsStringSync(CsvExporters.weights(weights));
    final activitiesFile = File('${dir.path}/atividades.csv')
      ..writeAsStringSync(CsvExporters.activities(activities));

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(mealsFile.path),
          XFile(weightsFile.path),
          XFile(activitiesFile.path),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final farPast = DateTime(2000);
    final farFuture = DateTime(2100);

    final meals = await ref
        .read(mealRepositoryProvider)
        .watchRange(farPast, farFuture)
        .first;
    final weights = await ref
        .read(measurementRepositoryProvider)
        .watchWeights()
        .first;
    final activities = await ref
        .read(activityRepositoryProvider)
        .watchEntries()
        .first;

    final summary = const WeeklySummaryCalculator().build(
      weekStart: weekStart,
      meals: meals,
      weights: weights,
      activities: activities,
    );
    final bytes = await const PdfReportBuilder().buildWeeklyReport(summary);
    await Printing.sharePdf(bytes: bytes, filename: 'resumo-semanal.pdf');
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar todos os dados'),
        content: const Text(
          'Esta ação é irreversível e vai apagar permanentemente todos os '
          'seus dados de perfil, refeições, peso, medicação, atividade e '
          'exames. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final paths = ref.read(firestorePathsProvider)!;
    final firestore = ref.read(firestoreProvider);
    final collections = [
      paths.goalHistory,
      paths.foods,
      paths.meals,
      paths.weightEntries,
      paths.bodyMeasureEntries,
      paths.medicationPlans,
      paths.medicationEntries,
      paths.activityPlans,
      paths.activityEntries,
      paths.labResults,
      paths.reminders,
      paths.dailyChecks,
    ];
    for (final path in collections) {
      final snap = await firestore.collection(path).get();
      for (var i = 0; i < snap.docs.length; i += 500) {
        final batch = firestore.batch();
        for (final doc in snap.docs.skip(i).take(500)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await firestore.doc(paths.profileDoc).delete();
    await firestore.doc(paths.settingsDoc).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os dados foram apagados.')),
      );
    }
  }
}

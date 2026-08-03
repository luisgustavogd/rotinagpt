import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/labs/lab_result.dart';
import '../../domain/medication/dose_consistency_checker.dart';
import '../../domain/medication/medication_duplicate_guard.dart';
import '../../domain/medication/medication_entry.dart';
import '../../domain/medication/medication_plan.dart';

const _weekdayLabels = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// RF-040 a RF-046 (medicação) e RF-070 a RF-073 (exames). O app nunca
/// sugere alterar dose (RF-044) e nunca interpreta sintomas/resultados como
/// diagnóstico (RN-006/RF-073).
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saúde'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Medicação'),
              Tab(text: 'Plano'),
              Tab(text: 'Exames'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MedicationEntriesTab(),
            _MedicationPlansTab(),
            _LabResultsTab(),
          ],
        ),
      ),
    );
  }
}

final _medicationPlansProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(medicationRepositoryProvider).watchPlans();
});

final _medicationEntriesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(medicationRepositoryProvider).watchEntries();
});

final _labResultsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(labRepositoryProvider).watchAll();
});

class _MedicationPlansTab extends ConsumerWidget {
  const _MedicationPlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(_medicationPlansProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editPlan(context, ref),
        child: const Icon(Icons.add),
      ),
      body: plansAsync.when(
        data: (plans) => plans.isEmpty
            ? const Center(child: Text('Nenhum plano de medicação cadastrado.'))
            : ListView(
                children: [
                  for (final plan in plans)
                    ListTile(
                      title: Text(plan.name),
                      subtitle: Text(
                        '${plan.prescribedDose} · ${plan.frequency} · ${plan.time} · '
                        '${plan.weekdays.map((w) => _weekdayLabels[w - 1]).join(', ')}',
                      ),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _editPlan(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final freqController = TextEditingController(text: 'semanal');
    var weekday = 1;
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome (ex.: Mounjaro/Tirzepatida)',
                ),
              ),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(
                  labelText: 'Dose prescrita (ex.: 5mg)',
                ),
              ),
              TextField(
                controller: freqController,
                decoration: const InputDecoration(
                  labelText: 'Frequência (ex.: semanal)',
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: const InputDecoration(labelText: 'Dia da semana'),
                items: [
                  for (var i = 0; i < 7; i++)
                    DropdownMenuItem(
                      value: i + 1,
                      child: Text(_weekdayLabels[i]),
                    ),
                ],
                onChanged: (v) => setState(() => weekday = v!),
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
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(medicationRepositoryProvider)
          .savePlan(
            MedicationPlan(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: nameController.text.trim(),
              prescribedDose: doseController.text.trim(),
              frequency: freqController.text.trim(),
              weekdays: [weekday],
              time:
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            ),
          );
    }
  }
}

class _MedicationEntriesTab extends ConsumerWidget {
  const _MedicationEntriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(_medicationEntriesProvider);
    final plansAsync = ref.watch(_medicationPlansProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _registerApplication(context, ref, plansAsync.valueOrNull ?? []),
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        data: (entries) => entries.isEmpty
            ? const Center(child: Text('Nenhuma aplicação registrada.'))
            : ListView(
                children: [
                  for (final e in entries.reversed)
                    ListTile(
                      title: Text('${e.dose} · ${e.applicationSite}'),
                      subtitle: Text(e.dateTime.toString()),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _registerApplication(
    BuildContext context,
    WidgetRef ref,
    List<MedicationPlan> plans,
  ) async {
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um plano de medicação primeiro.'),
        ),
      );
      return;
    }

    var plan = plans.first;
    final doseController = TextEditingController(text: plan.prescribedDose);
    final siteController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
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
              DropdownButtonFormField<MedicationPlan>(
                initialValue: plan,
                decoration: const InputDecoration(labelText: 'Medicação'),
                items: [
                  for (final p in plans)
                    DropdownMenuItem(value: p, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() {
                  plan = v!;
                  doseController.text = plan.prescribedDose;
                }),
              ),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(labelText: 'Dose aplicada'),
              ),
              TextField(
                controller: siteController,
                decoration: const InputDecoration(
                  labelText: 'Local de aplicação',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Registrar aplicação'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final now = DateTime.now();
    final existingEntries =
        ref.read(_medicationEntriesProvider).valueOrNull ?? [];

    // RF-045 — dose divergente exige confirmação (nunca sugere qual está certa).
    if (const DoseConsistencyChecker().needsConfirmation(
      plan: plan,
      registeredDose: doseController.text,
    )) {
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar dose diferente da cadastrada'),
          content: Text(
            'A dose informada (${doseController.text}) é diferente da dose '
            'cadastrada no plano (${plan.prescribedDose}). Deseja confirmar '
            'mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    // RN-005 — aplicação muito próxima de outra é sinalizada antes de salvar.
    if (const MedicationDuplicateGuard().isLikelyDuplicate(
      existingEntries: existingEntries,
      planId: plan.id,
      candidateDateTime: now,
    )) {
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Possível aplicação duplicada'),
          content: const Text(
            'Já existe uma aplicação registrada há pouco tempo para esta '
            'medicação. Deseja registrar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    await ref
        .read(medicationRepositoryProvider)
        .saveEntry(
          MedicationEntry(
            id: now.microsecondsSinceEpoch.toString(),
            planId: plan.id,
            dateTime: now,
            dose: doseController.text.trim(),
            applicationSite: siteController.text.trim(),
          ),
        );
  }
}

class _LabResultsTab extends ConsumerWidget {
  const _LabResultsTab();

  static const _commonMarkers = [
    'Colesterol total',
    'LDL',
    'HDL',
    'Triglicerídeos',
    'Glicemia',
    'Hemoglobina glicada',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(_labResultsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addResult(context, ref),
        child: const Icon(Icons.add),
      ),
      body: resultsAsync.when(
        data: (results) => results.isEmpty
            ? const Center(child: Text('Nenhum exame cadastrado.'))
            : ListView(
                children: [
                  for (final r in results.reversed)
                    ListTile(
                      title: Text('${r.markerName}: ${r.result} ${r.unit}'),
                      subtitle: Text(
                        '${r.date.day}/${r.date.month}/${r.date.year}'
                        '${r.reference != null ? ' · ref.: ${r.reference}' : ''}',
                      ),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _addResult(BuildContext context, WidgetRef ref) async {
    var marker = _commonMarkers.first;
    final resultController = TextEditingController();
    final unitController = TextEditingController();
    final referenceController = TextEditingController();

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
              DropdownButtonFormField<String>(
                initialValue: marker,
                decoration: const InputDecoration(labelText: 'Exame'),
                items: [
                  for (final m in _commonMarkers)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (v) => setState(() => marker = v!),
              ),
              TextField(
                controller: resultController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Resultado'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unidade (ex.: mg/dL)',
                ),
              ),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Referência (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );

    final result = double.tryParse(resultController.text.replaceAll(',', '.'));
    if (saved == true && result != null) {
      await ref
          .read(labRepositoryProvider)
          .save(
            LabResult(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              date: DateTime.now(),
              markerName: marker,
              result: result,
              unit: unitController.text.trim(),
              reference: referenceController.text.trim().isEmpty
                  ? null
                  : referenceController.text.trim(),
            ),
          );
    }
  }
}

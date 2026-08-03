import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/activity/activity_entry.dart';
import '../../domain/activity/activity_plan.dart';
import '../../domain/activity/activity_type.dart';

const _weekdayLabels = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// RF-050 — plano semanal de atividades (agenda semanal completa de
/// refeições/hábitos/lembretes fica distribuída entre Alimentação e
/// Ajustes; aqui concentra-se o plano de atividade física, que é o núcleo
/// da tela "Rotina").
class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(_activityPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rotina')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editPlan(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Text('Nenhum plano de atividade ainda.'),
            );
          }
          final sorted = [...plans]
            ..sort((a, b) => a.weekday.compareTo(b.weekday));
          return ListView(
            children: [
              for (final plan in sorted)
                ListTile(
                  title: Text(
                    '${_weekdayLabels[plan.weekday - 1]} · ${_typeLabel(plan.type)}',
                  ),
                  subtitle: Text(
                    '${plan.durationMin} min · esforço ${plan.perceivedIntensity}/10',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: 'Registrar execução',
                        onPressed: () => _registerExecution(context, ref, plan),
                      ),
                      Switch(
                        value: plan.active,
                        onChanged: (v) => ref
                            .read(activityRepositoryProvider)
                            .savePlan(plan.copyWith(active: v)),
                      ),
                    ],
                  ),
                  onTap: () => _editPlan(context, ref, plan),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Não foi possível carregar a rotina: $e')),
      ),
    );
  }

  String _typeLabel(ActivityType type) => switch (type) {
    ActivityType.strength => 'Força',
    ActivityType.bike => 'Bicicleta',
    ActivityType.walk => 'Caminhada',
    ActivityType.mobility => 'Mobilidade',
    ActivityType.other => 'Outra',
  };

  Future<void> _editPlan(
    BuildContext context,
    WidgetRef ref,
    ActivityPlan? existing,
  ) async {
    final result = await showModalBottomSheet<ActivityPlan>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ActivityPlanForm(existing: existing),
    );
    if (result != null) {
      await ref.read(activityRepositoryProvider).savePlan(result);
    }
  }

  /// RF-051/RF-052 — registro rápido de execução (total, parcial ou não
  /// realizada) e esforço percebido (0-10). RF-053 — duração/intensidade só
  /// mudam se o usuário alterar manualmente aqui; o app nunca aumenta o
  /// treino sozinho.
  Future<void> _registerExecution(
    BuildContext context,
    WidgetRef ref,
    ActivityPlan plan,
  ) async {
    final durationController = TextEditingController(
      text: '${plan.durationMin}',
    );
    var effort = plan.perceivedIntensity.toDouble();
    var status = ActivityStatus.completed;

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
              Text(
                '${_typeLabel(plan.type)} · ${_weekdayLabels[plan.weekday - 1]}',
              ),
              const SizedBox(height: 8),
              SegmentedButton<ActivityStatus>(
                segments: const [
                  ButtonSegment(
                    value: ActivityStatus.completed,
                    label: Text('Completa'),
                  ),
                  ButtonSegment(
                    value: ActivityStatus.partial,
                    label: Text('Parcial'),
                  ),
                  ButtonSegment(
                    value: ActivityStatus.notDone,
                    label: Text('Não realizada'),
                  ),
                ],
                selected: {status},
                onSelectionChanged: (s) => setState(() => status = s.first),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração realizada (min)',
                ),
              ),
              Text('Esforço percebido: ${effort.round()}/10'),
              Slider(
                value: effort,
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (v) => setState(() => effort = v),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;
    await ref
        .read(activityRepositoryProvider)
        .saveEntry(
          ActivityEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            planId: plan.id,
            dateTime: DateTime.now(),
            type: plan.type,
            durationMin:
                int.tryParse(durationController.text) ?? plan.durationMin,
            perceivedEffort: effort.round(),
            status: status,
          ),
        );
  }
}

final _activityPlansProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(activityRepositoryProvider).watchPlans();
});

class _ActivityPlanForm extends StatefulWidget {
  const _ActivityPlanForm({this.existing});
  final ActivityPlan? existing;

  @override
  State<_ActivityPlanForm> createState() => _ActivityPlanFormState();
}

class _ActivityPlanFormState extends State<_ActivityPlanForm> {
  late int _weekday = widget.existing?.weekday ?? 1;
  late ActivityType _type = widget.existing?.type ?? ActivityType.walk;
  late final _durationController = TextEditingController(
    text: '${widget.existing?.durationMin ?? 30}',
  );
  late double _intensity = (widget.existing?.perceivedIntensity ?? 5)
      .toDouble();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          DropdownButtonFormField<int>(
            initialValue: _weekday,
            decoration: const InputDecoration(labelText: 'Dia da semana'),
            items: [
              for (var i = 0; i < 7; i++)
                DropdownMenuItem(value: i + 1, child: Text(_weekdayLabels[i])),
            ],
            onChanged: (v) => setState(() => _weekday = v!),
          ),
          DropdownButtonFormField<ActivityType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const [
              DropdownMenuItem(
                value: ActivityType.strength,
                child: Text('Força'),
              ),
              DropdownMenuItem(
                value: ActivityType.bike,
                child: Text('Bicicleta'),
              ),
              DropdownMenuItem(
                value: ActivityType.walk,
                child: Text('Caminhada'),
              ),
              DropdownMenuItem(
                value: ActivityType.mobility,
                child: Text('Mobilidade'),
              ),
              DropdownMenuItem(value: ActivityType.other, child: Text('Outra')),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duração (min)'),
          ),
          Text('Esforço percebido: ${_intensity.round()}/10'),
          Slider(
            value: _intensity,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => setState(() => _intensity = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                ActivityPlan(
                  id:
                      widget.existing?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  weekday: _weekday,
                  type: _type,
                  durationMin: int.tryParse(_durationController.text) ?? 30,
                  perceivedIntensity: _intensity.round(),
                  active: widget.existing?.active ?? true,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

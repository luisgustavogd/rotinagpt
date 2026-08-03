import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../domain/notifications/daily_check.dart';
import '../../domain/nutrition/meal_entry.dart';
import '../../domain/nutrition/protein_calculator.dart';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

const _defaultHabits = [
  'Café da manhã',
  'Almoço',
  'Jantar',
  'Hidratação',
  'Atividade física',
];

final _profileProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});

final _todayMealsProvider = StreamProvider.autoDispose((ref) {
  final today = _startOfDay(DateTime.now());
  return ref
      .watch(mealRepositoryProvider)
      .watchRange(today, today.add(const Duration(days: 1)));
});

final _latestWeightProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(measurementRepositoryProvider).watchWeights();
});

final _medicationEntriesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(medicationRepositoryProvider).watchEntries();
});

final _dailyChecksProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(dailyCheckRepositoryProvider).watchForDate(DateTime.now());
});

/// RF-010 a RF-014 — "Hoje primeiro": responde imediatamente "o que falta
/// fazer hoje?".
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_profileProvider);
    final mealsAsync = ref.watch(_todayMealsProvider);
    final weightsAsync = ref.watch(_latestWeightProvider);
    final medicationAsync = ref.watch(_medicationEntriesProvider);
    final checksAsync = ref.watch(_dailyChecksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoje'),
        actions: [
          IconButton(
            icon: const Icon(Icons.nightlight_outlined),
            tooltip: 'Resumo noturno',
            onPressed: () => _showNightSummary(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final targetProtein = profile?.targetProteinG ?? 0;
          final meals = mealsAsync.valueOrNull ?? const <MealEntry>[];
          final consumed = const ProteinCalculator().consumedProteinForDay(
            meals,
            DateTime.now(),
          );
          final remaining = const ProteinCalculator().remainingProtein(
            targetProteinG: targetProtein,
            consumedProteinG: consumed,
          );
          final progress = targetProtein <= 0
              ? 0.0
              : (consumed / targetProtein).clamp(0, 1).toDouble();

          final weights = weightsAsync.valueOrNull ?? const [];
          final latestWeight = weights.isEmpty ? null : weights.last;
          final medicationEntries = medicationAsync.valueOrNull ?? const [];
          final lastMedication = medicationEntries.isEmpty
              ? null
              : medicationEntries.last;

          final hasAnyPlanning =
              meals.isNotEmpty || medicationEntries.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Proteína hoje',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, minHeight: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '${consumed.toStringAsFixed(0)}g de ${targetProtein.toStringAsFixed(0)}g '
                '(faltam ${remaining.toStringAsFixed(0)}g · ${(progress * 100).toStringAsFixed(0)}%)',
              ),
              const SizedBox(height: 4),
              const Text(
                'Meta configurada manualmente — valide com um profissional de saúde.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peso mais recente: ${latestWeight == null ? '—' : '${latestWeight.weightKg} kg'}',
                      ),
                      Text(
                        'Última aplicação de medicação: ${lastMedication == null ? '—' : '${lastMedication.dose} em ${lastMedication.dateTime.day}/${lastMedication.dateTime.month}'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Checklist de hoje',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              checksAsync.when(
                data: (checks) => _ChecklistCard(checks: checks),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erro: $e'),
              ),
              const SizedBox(height: 24),
              if (!hasAnyPlanning)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Nenhum planejamento para hoje ainda.'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton(
                              onPressed: () => context.go('/nutrition'),
                              child: const Text('Registrar refeição'),
                            ),
                            OutlinedButton(
                              onPressed: () => context.go('/progress'),
                              child: const Text('Registrar peso'),
                            ),
                            OutlinedButton(
                              onPressed: () => context.push('/more/health'),
                              child: const Text('Registrar aplicação'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _showNightSummary(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(_profileProvider).valueOrNull;
    final meals =
        ref.read(_todayMealsProvider).valueOrNull ?? const <MealEntry>[];
    final checks =
        ref.read(_dailyChecksProvider).valueOrNull ?? const <DailyCheck>[];
    final consumed = const ProteinCalculator().consumedProteinForDay(
      meals,
      DateTime.now(),
    );
    final done = checks.where((c) => c.status == DailyCheckStatus.done).length;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumo do dia'),
        content: Text(
          'Proteína: ${consumed.toStringAsFixed(0)}g de ${(profile?.targetProteinG ?? 0).toStringAsFixed(0)}g\n'
          'Itens do checklist concluídos: $done de ${checks.length}\n\n'
          'Tudo bem se o dia não ficou 100% completo — o que importa é a '
          'constância ao longo da semana.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends ConsumerWidget {
  const _ChecklistCard({required this.checks});
  final List<DailyCheck> checks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byLabel = {for (final c in checks) c.habitLabel: c};
    final today = _startOfDay(DateTime.now());

    return Card(
      child: Column(
        children: [
          for (final habit in _defaultHabits)
            CheckboxListTile(
              title: Text(habit),
              value: byLabel[habit]?.status == DailyCheckStatus.done,
              onChanged: (checked) {
                final existing = byLabel[habit];
                final updated = DailyCheck(
                  id: existing?.id ?? '${today.millisecondsSinceEpoch}-$habit',
                  date: today,
                  habitLabel: habit,
                  status: checked == true
                      ? DailyCheckStatus.done
                      : DailyCheckStatus.pending,
                  completedAt: checked == true ? DateTime.now() : null,
                );
                ref.read(dailyCheckRepositoryProvider).save(updated);
              },
            ),
        ],
      ),
    );
  }
}

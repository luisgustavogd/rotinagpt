import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/measurements/body_measure_entry.dart';
import '../../domain/measurements/weekly_average.dart';
import '../../domain/measurements/weight_entry.dart';
import '../../domain/reports/weekly_summary_calculator.dart';

final _weightsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(measurementRepositoryProvider).watchWeights();
});

final _bodyMeasuresProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(measurementRepositoryProvider).watchBodyMeasures();
});

final _mealsForSummaryProvider = StreamProvider.autoDispose((ref) {
  final start = DateTime.now().subtract(const Duration(days: 35));
  return ref
      .watch(mealRepositoryProvider)
      .watchRange(start, DateTime.now().add(const Duration(days: 1)));
});

final _activitiesForSummaryProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(activityRepositoryProvider).watchEntries();
});

DateTime _mondayOfCurrentWeek() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - 1));
}

/// RF-030 a RF-034 (peso/cintura/tendência/metas) e RF-080/081 (gráficos e
/// resumo semanal).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightsAsync = ref.watch(_weightsProvider);
    final measuresAsync = ref.watch(_bodyMeasuresProvider);
    final mealsAsync = ref.watch(_mealsForSummaryProvider);
    final activitiesAsync = ref.watch(_activitiesForSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMeasurement(context, ref),
        child: const Icon(Icons.add),
      ),
      body: weightsAsync.when(
        data: (weights) {
          final points = const WeeklyAverageCalculator().movingAverage(weights);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tendência de peso (média móvel semanal)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: points.length < 2
                    ? const Center(
                        child: Text(
                          'Registre ao menos 2 pesos para ver o gráfico.',
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              dotData: const FlDotData(show: false),
                              spots: [
                                for (var i = 0; i < points.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    points[i].movingAverageKg,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                'Resumo semanal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              mealsAsync.when(
                data: (meals) => activitiesAsync.when(
                  data: (activities) {
                    final summary = const WeeklySummaryCalculator().build(
                      weekStart: _mondayOfCurrentWeek(),
                      meals: meals,
                      weights: weights,
                      activities: activities,
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proteína média diária: ${summary.averageProteinG.toStringAsFixed(1)} g',
                            ),
                            Text(
                              'Variação de peso: ${summary.weightVariationKg == null ? '—' : '${summary.weightVariationKg!.toStringAsFixed(1)} kg'}',
                            ),
                            Text(
                              'Atividade: ${summary.activityMinutes} min (${summary.completedActivities} completas, ${summary.partialActivities} parciais)',
                            ),
                            Text(
                              'Dias com refeições confirmadas: ${summary.daysWithMealsConfirmed} de 7',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Erro: $e'),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erro: $e'),
              ),
              const SizedBox(height: 24),
              Text('Cintura', style: Theme.of(context).textTheme.titleMedium),
              measuresAsync.when(
                data: (measures) => measures.isEmpty
                    ? const Text('Nenhuma medida registrada.')
                    : Column(
                        children: [
                          for (final m in measures.reversed.take(10))
                            ListTile(
                              title: Text('${m.waistCm} cm'),
                              subtitle: Text(
                                '${m.date.day}/${m.date.month}/${m.date.year}',
                              ),
                            ),
                        ],
                      ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erro: $e'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _addMeasurement(BuildContext context, WidgetRef ref) async {
    final weightController = TextEditingController();
    final waistController = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Peso (kg, opcional)',
              ),
            ),
            TextField(
              controller: waistController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cintura (cm, opcional)',
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
    );

    if (saved != true) return;
    final now = DateTime.now();
    final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
    final waist = double.tryParse(waistController.text.replaceAll(',', '.'));

    if (weight != null) {
      await ref
          .read(measurementRepositoryProvider)
          .saveWeight(
            WeightEntry(
              id: now.microsecondsSinceEpoch.toString(),
              dateTime: now,
              weightKg: weight,
            ),
          );
    }
    if (waist != null) {
      await ref
          .read(measurementRepositoryProvider)
          .saveBodyMeasure(
            BodyMeasureEntry(
              id: '${now.microsecondsSinceEpoch}-w',
              date: now,
              waistCm: waist,
            ),
          );
    }
  }
}

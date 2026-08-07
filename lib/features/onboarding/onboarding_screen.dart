import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/profile/bmi_calculator.dart';
import '../../domain/profile/goal_history_entry.dart';
import '../../domain/profile/protein_target_calculator.dart';
import '../../domain/profile/user_profile.dart';

/// RF-001/RF-002/RF-003 — onboarding: só o essencial, sem cadastro
/// obrigatório de terceiros (a conta Firebase já identifica o usuário).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _targetProteinController = TextEditingController();
  final _restrictionsController = TextEditingController();

  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);
  bool _saving = false;

  // A meta de peso é sugerida automaticamente (IMC central 21,75) assim que
  // peso e altura são informados. Deixa de ser sugerida no momento em que o
  // usuário edita o campo manualmente — a partir daí o valor é só dele.
  bool _targetWeightAutoFilled = true;
  bool _isProgrammaticTargetWeightUpdate = false;

  // A meta de proteína é sugerida a partir do peso e do nível de atividade
  // escolhido (ver docs/NUTRICAO.md). Some/deixa de recalcular pela mesma
  // regra da meta de peso: editar o campo manualmente desliga a sugestão.
  ProteinActivityLevel? _proteinActivityLevel;
  bool _targetProteinAutoFilled = false;
  bool _isProgrammaticTargetProteinUpdate = false;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightOrHeightChanged);
    _heightController.addListener(_onWeightOrHeightChanged);
    _targetWeightController.addListener(_onTargetWeightChanged);
    _targetProteinController.addListener(_onTargetProteinChanged);
  }

  void _onTargetWeightChanged() {
    if (_isProgrammaticTargetWeightUpdate) return;
    if (_targetWeightAutoFilled) {
      setState(() => _targetWeightAutoFilled = false);
    }
  }

  void _onTargetProteinChanged() {
    if (_isProgrammaticTargetProteinUpdate) return;
    if (_targetProteinAutoFilled) {
      setState(() => _targetProteinAutoFilled = false);
    }
  }

  void _onWeightOrHeightChanged() {
    final weightKg = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );

    if (_targetWeightAutoFilled) {
      final heightCm = double.tryParse(
        _heightController.text.replaceAll(',', '.'),
      );
      final suggestedWeight = weightKg == null
          ? null
          : BmiCalculator.suggestedTargetWeightKg(heightCm);
      if (suggestedWeight != null) {
        _isProgrammaticTargetWeightUpdate = true;
        _targetWeightController.text = suggestedWeight.toStringAsFixed(1);
        _isProgrammaticTargetWeightUpdate = false;
      }
    }

    _recomputeProteinSuggestion(weightKg);
    setState(() {});
  }

  void _onProteinActivityLevelChanged(ProteinActivityLevel? level) {
    setState(() {
      _proteinActivityLevel = level;
      if (level != null) _targetProteinAutoFilled = true;
    });
    final weightKg = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    _recomputeProteinSuggestion(weightKg);
  }

  void _recomputeProteinSuggestion(double? weightKg) {
    if (!_targetProteinAutoFilled || _proteinActivityLevel == null) return;
    if (weightKg == null) return;
    final suggested = ProteinTargetCalculator.suggestedTargetProteinG(
      weightKg,
      _proteinActivityLevel!,
    );
    _isProgrammaticTargetProteinUpdate = true;
    _targetProteinController.text = suggested.toStringAsFixed(1);
    _isProgrammaticTargetProteinUpdate = false;
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isWake) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isWake ? _wakeTime : _sleepTime,
    );
    if (picked == null) return;
    setState(() => isWake ? _wakeTime = picked : _sleepTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final profile = UserProfile(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      initialWeightKg: double.parse(
        _weightController.text.replaceAll(',', '.'),
      ),
      heightCm: _heightController.text.trim().isEmpty
          ? null
          : double.parse(_heightController.text.replaceAll(',', '.')),
      targetWeightKg: double.parse(
        _targetWeightController.text.replaceAll(',', '.'),
      ),
      targetProteinG: double.parse(
        _targetProteinController.text.replaceAll(',', '.'),
      ),
      proteinActivityLevel: _proteinActivityLevel,
      wakeTime: _fmt(_wakeTime),
      sleepTime: _fmt(_sleepTime),
      restrictions: _restrictionsController.text.trim().isEmpty
          ? const []
          : _restrictionsController.text
                .split(',')
                .map((s) => s.trim())
                .toList(),
    );

    const uuid = Uuid();
    final profileRepo = ref.read(profileRepositoryProvider);
    await profileRepo.saveProfile(profile);
    final now = DateTime.now();
    await profileRepo.addGoalHistoryEntry(
      GoalHistoryEntry(
        id: uuid.v4(),
        kind: GoalKind.weight,
        value: profile.targetWeightKg,
        effectiveDate: now,
      ),
    );
    await profileRepo.addGoalHistoryEntry(
      GoalHistoryEntry(
        id: uuid.v4(),
        kind: GoalKind.protein,
        value: profile.targetProteinG,
        effectiveDate: now,
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    // O GoRouter só reavalia o redirect quando o auth state muda, não quando
    // o perfil é criado no Firestore — por isso navegamos explicitamente.
    context.go('/today');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _targetProteinController.dispose();
    _restrictionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weightKg = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final heightCm = double.tryParse(
      _heightController.text.replaceAll(',', '.'),
    );
    final bmi = weightKg == null ? null : BmiCalculator.bmi(weightKg, heightCm);

    return Scaffold(
      appBar: AppBar(title: const Text('Vamos configurar seu app')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Peso atual (kg)'),
                validator: (v) =>
                    (v == null ||
                        double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Informe um número válido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Altura em cm (opcional)',
                ),
              ),
              if (bmi != null) ...[
                const SizedBox(height: 4),
                Text(
                  'IMC: ${bmi.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetWeightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Meta de peso (kg)',
                  helperText: _targetWeightAutoFilled
                      ? 'Valor calculado baseado na faixa central do IMC'
                      : null,
                  helperMaxLines: 2,
                ),
                validator: (v) =>
                    (v == null ||
                        double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Informe um número válido'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProteinActivityLevel?>(
                initialValue: _proteinActivityLevel,
                decoration: const InputDecoration(
                  labelText: 'Nível de atividade (calcula a meta de proteína)',
                ),
                items: [
                  const DropdownMenuItem<ProteinActivityLevel?>(
                    child: Text('Não calcular automaticamente'),
                  ),
                  for (final level in ProteinActivityLevel.values)
                    DropdownMenuItem(value: level, child: Text(level.label)),
                ],
                onChanged: _onProteinActivityLevelChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetProteinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Meta diária de proteína (g)',
                  helperText: _targetProteinAutoFilled
                      ? 'Valor calculado baseado no estudo referenciado em '
                            'docs/NUTRICAO.md. Ainda assim, valide com um '
                            'profissional de saúde.'
                      : 'Esse valor deve ser validado por um profissional de saúde.',
                  helperMaxLines: 3,
                ),
                validator: (v) =>
                    (v == null ||
                        double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Informe um número válido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _restrictionsController,
                decoration: const InputDecoration(
                  labelText:
                      'Restrições/preferências (opcional, separadas por vírgula)',
                  hintText: 'ex.: refluxo, evitar frituras',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Horário habitual de acordar'),
                trailing: Text(_fmt(_wakeTime)),
                onTap: () => _pickTime(true),
              ),
              ListTile(
                title: const Text('Horário habitual de dormir'),
                trailing: Text(_fmt(_sleepTime)),
                onTap: () => _pickTime(false),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Concluir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

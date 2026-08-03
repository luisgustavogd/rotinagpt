import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/profile/goal_history_entry.dart';
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

    if (mounted) setState(() => _saving = false);
    // A guarda de rota detecta o perfil recém-criado e navega sozinha.
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetWeightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Meta de peso (kg)',
                ),
                validator: (v) =>
                    (v == null ||
                        double.tryParse(v.replaceAll(',', '.')) == null)
                    ? 'Informe um número válido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetProteinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Meta diária de proteína (g)',
                  helperText:
                      'Esse valor deve ser validado por um profissional de saúde.',
                  helperMaxLines: 2,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/profile/goal_history_entry.dart';
import '../../domain/profile/user_profile.dart';

/// RF-004 — edição do perfil a qualquer momento (corrigir dados informados
/// errado no onboarding). Metas de peso/proteína seguem RN-008: uma mudança
/// nelas soma uma nova entrada ao histórico, nunca reescreve o passado.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.profile.name ?? '',
  );
  late final _weightController = TextEditingController(
    text: _fmtNum(widget.profile.initialWeightKg),
  );
  late final _heightController = TextEditingController(
    text: widget.profile.heightCm == null
        ? ''
        : _fmtNum(widget.profile.heightCm!),
  );
  late final _targetWeightController = TextEditingController(
    text: _fmtNum(widget.profile.targetWeightKg),
  );
  late final _targetProteinController = TextEditingController(
    text: _fmtNum(widget.profile.targetProteinG),
  );
  late final _restrictionsController = TextEditingController(
    text: widget.profile.restrictions.join(', '),
  );

  late TimeOfDay _wakeTime = _parseTime(widget.profile.wakeTime);
  late TimeOfDay _sleepTime = _parseTime(widget.profile.sleepTime);
  bool _saving = false;

  static String _fmtNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

    final targetWeightKg = double.parse(
      _targetWeightController.text.replaceAll(',', '.'),
    );
    final targetProteinG = double.parse(
      _targetProteinController.text.replaceAll(',', '.'),
    );

    final updated = widget.profile.copyWith(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      initialWeightKg: double.parse(
        _weightController.text.replaceAll(',', '.'),
      ),
      heightCm: _heightController.text.trim().isEmpty
          ? null
          : double.parse(_heightController.text.replaceAll(',', '.')),
      targetWeightKg: targetWeightKg,
      targetProteinG: targetProteinG,
      wakeTime: _fmt(_wakeTime),
      sleepTime: _fmt(_sleepTime),
      restrictions: _restrictionsController.text.trim().isEmpty
          ? const []
          : _restrictionsController.text
                .split(',')
                .map((s) => s.trim())
                .toList(),
    );

    final profileRepo = ref.read(profileRepositoryProvider);
    await profileRepo.saveProfile(updated);

    const uuid = Uuid();
    final now = DateTime.now();
    if (targetWeightKg != widget.profile.targetWeightKg) {
      await profileRepo.addGoalHistoryEntry(
        GoalHistoryEntry(
          id: uuid.v4(),
          kind: GoalKind.weight,
          value: targetWeightKg,
          effectiveDate: now,
        ),
      );
    }
    if (targetProteinG != widget.profile.targetProteinG) {
      await profileRepo.addGoalHistoryEntry(
        GoalHistoryEntry(
          id: uuid.v4(),
          kind: GoalKind.protein,
          value: targetProteinG,
          effectiveDate: now,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
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
      appBar: AppBar(title: const Text('Editar perfil')),
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
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

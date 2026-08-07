import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/profile/bmi_calculator.dart';
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

  // Diferente do onboarding, aqui a meta já existe e foi escolhida pelo
  // usuário — só passamos a sugerir de novo (e mostrar o aviso) se ele
  // editar o campo manualmente e o deixar em branco, ou seja, pedir uma
  // nova sugestão. Editar peso/altura sozinho não deve sobrescrever uma
  // meta que ele já definiu.
  bool _targetWeightAutoFilled = false;
  bool _isProgrammaticTargetWeightUpdate = false;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightOrHeightChanged);
    _heightController.addListener(_onWeightOrHeightChanged);
    _targetWeightController.addListener(_onTargetWeightChanged);
  }

  void _onTargetWeightChanged() {
    if (_isProgrammaticTargetWeightUpdate) return;
    if (_targetWeightController.text.trim().isEmpty) {
      setState(() => _targetWeightAutoFilled = true);
      return;
    }
    if (_targetWeightAutoFilled) {
      setState(() => _targetWeightAutoFilled = false);
    }
  }

  void _onWeightOrHeightChanged() {
    if (!_targetWeightAutoFilled) {
      setState(() {});
      return;
    }
    final heightCm = double.tryParse(
      _heightController.text.replaceAll(',', '.'),
    );
    final weightKg = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final suggested = weightKg == null
        ? null
        : BmiCalculator.suggestedTargetWeightKg(heightCm);
    setState(() {
      if (suggested != null) {
        _isProgrammaticTargetWeightUpdate = true;
        _targetWeightController.text = suggested.toStringAsFixed(1);
        _isProgrammaticTargetWeightUpdate = false;
      }
    });
  }

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
    final weightKg = double.tryParse(
      _weightController.text.replaceAll(',', '.'),
    );
    final heightCm = double.tryParse(
      _heightController.text.replaceAll(',', '.'),
    );
    final bmi = weightKg == null ? null : BmiCalculator.bmi(weightKg, heightCm);

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

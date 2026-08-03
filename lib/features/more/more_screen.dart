import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Área "Mais" (seção 5.1) — agrupa Rotina, Saúde e Ajustes para reduzir
/// poluição visual sem esconder as funções de uso diário.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Rotina'),
            subtitle: const Text('Agenda semanal de atividades'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/more/routine'),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Saúde'),
            subtitle: const Text('Medicação, sintomas e exames'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/more/health'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Ajustes'),
            subtitle: const Text(
              'Perfil, metas, notificações, backup e privacidade',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/more/settings'),
          ),
        ],
      ),
    );
  }
}

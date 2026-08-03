import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navegação recomendada (seção 5.1 do documento): barra inferior com quatro
/// itens — Hoje, Alimentação, Progresso e Mais. "Mais" agrupa Rotina, Saúde
/// e Ajustes, para reduzir poluição visual sem esconder as funções de uso
/// diário.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = [
    ('/today', Icons.today_outlined, Icons.today, 'Hoje'),
    ('/nutrition', Icons.restaurant_outlined, Icons.restaurant, 'Alimentação'),
    ('/progress', Icons.show_chart_outlined, Icons.show_chart, 'Progresso'),
    ('/more', Icons.more_horiz_outlined, Icons.more_horiz, 'Mais'),
  ];

  int get _currentIndex {
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].$1),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.$2),
              selectedIcon: Icon(tab.$3),
              label: tab.$4,
            ),
        ],
      ),
    );
  }
}

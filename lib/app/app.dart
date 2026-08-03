import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import 'router.dart';
import 'theme.dart';

class RotinaGptApp extends ConsumerStatefulWidget {
  const RotinaGptApp({super.key});

  @override
  ConsumerState<RotinaGptApp> createState() => _RotinaGptAppState();
}

class _RotinaGptAppState extends ConsumerState<RotinaGptApp> {
  @override
  Widget build(BuildContext context) {
    // RF-064/RN-009 — reagenda os lembretes locais deste aparelho sempre que
    // a lista sincronizada mudar (edição local ou vinda do outro aparelho).
    ref.listen(remindersStreamProvider, (previous, next) {
      final reminders = next.valueOrNull;
      if (reminders != null) {
        ref.read(notificationServiceProvider).rescheduleAll(reminders);
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Minha Rotina de Saúde',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

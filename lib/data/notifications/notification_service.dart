import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notifications/reminder.dart';
import '../../domain/notifications/reminder_scheduler.dart';
import '../../domain/notifications/silence_window.dart';

/// RF-060 a RF-064 — agenda notificações locais a partir da definição
/// sincronizada de [Reminder]s. A definição do lembrete sincroniza entre
/// aparelhos via Firestore, mas o agendamento do SO é sempre local a este
/// aparelho: cada dispositivo escuta o stream de lembretes e chama
/// [rescheduleAll] a cada mudança (local ou vinda do outro aparelho),
/// cobrindo RN-009 (cancelar/reagendar) mesmo para mudanças remotas.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this.windowDays = 14,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final int windowDays;
  static const _scheduler = ReminderScheduler();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Usuário-alvo do MVP está no fuso America/Sao_Paulo (mesmo fuso do
    // protótipo web anterior deste projeto); se o app vier a ser usado em
    // outro fuso, troque por detecção via `flutter_timezone` ou similar.
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    _initialized = true;
  }

  /// RF-063 — a permissão é pedida só quando o usuário configura o primeiro
  /// lembrete, nunca na abertura inicial do app.
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final androidGranted = await android?.requestNotificationsPermission();

    return (iosGranted ?? true) && (androidGranted ?? true);
  }

  /// RN-009 — cancela tudo e reagenda a partir do zero a cada mudança na
  /// lista de lembretes (local ou sincronizada). Simples e sempre correto,
  /// ao custo de recalcular a janela inteira; para o volume de lembretes
  /// pessoais deste app, o custo é desprezível.
  Future<void> rescheduleAll(
    List<Reminder> reminders, {
    SilenceWindow? silenceWindow,
  }) async {
    await initialize();
    await _plugin.cancelAll();

    final occurrences = _scheduler.computeOccurrences(
      reminders: reminders,
      from: DateTime.now(),
      days: windowDays,
      silenceWindow: silenceWindow,
    );

    for (final occurrence in occurrences) {
      await _scheduleOne(occurrence);
    }
  }

  Future<void> _scheduleOne(ReminderOccurrence occurrence) async {
    final id = _stableId(occurrence);
    final scheduledDate = tz.TZDateTime.from(occurrence.dateTime, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: _titleFor(occurrence.reminder),
      body: occurrence.reminder.label,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Lembretes',
          channelDescription:
              'Lembretes de refeições, proteína, atividade, '
              'peso e medicação',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  String _titleFor(Reminder reminder) {
    switch (reminder.type) {
      case ReminderType.meal:
        return 'Hora da refeição';
      case ReminderType.protein:
        return 'Lembrete de proteína';
      case ReminderType.activity:
        return 'Hora da atividade física';
      case ReminderType.weight:
        return 'Lembrete de peso';
      case ReminderType.medication:
        return 'Lembrete de medicação';
    }
  }

  int _stableId(ReminderOccurrence occurrence) {
    final key =
        '${occurrence.reminder.id}-${occurrence.dateTime.toIso8601String()}';
    return key.hashCode & 0x7fffffff;
  }
}

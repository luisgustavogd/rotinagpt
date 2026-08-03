import 'reminder.dart';
import 'silence_window.dart';

class ReminderOccurrence {
  const ReminderOccurrence({required this.reminder, required this.dateTime});

  final Reminder reminder;
  final DateTime dateTime;
}

/// RF-060/RF-062/RF-064/RN-009 — calcula as próximas ocorrências concretas de
/// cada lembrete ativo dentro de uma janela de dias, já filtrando o horário
/// de silêncio. Não agenda notificações do SO diretamente (isso é
/// responsabilidade de `data/notifications/notification_service.dart`) —
/// esta classe só faz a expansão de recorrência, para ser testável sem
/// nenhuma dependência de plugin.
class ReminderScheduler {
  const ReminderScheduler();

  List<ReminderOccurrence> computeOccurrences({
    required List<Reminder> reminders,
    required DateTime from,
    int days = 14,
    SilenceWindow? silenceWindow,
  }) {
    final occurrences = <ReminderOccurrence>[];
    final startDay = DateTime(from.year, from.month, from.day);

    for (final reminder in reminders.where((r) => r.active)) {
      final timeParts = reminder.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      for (var i = 0; i < days; i++) {
        final day = startDay.add(Duration(days: i));
        if (!_matchesDay(reminder, day)) continue;

        final occurrenceTime = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          minute,
        );
        if (occurrenceTime.isBefore(from)) continue;
        if (silenceWindow != null && silenceWindow.contains(occurrenceTime)) {
          continue;
        }
        occurrences.add(
          ReminderOccurrence(reminder: reminder, dateTime: occurrenceTime),
        );

        if (reminder.recurrence == ReminderRecurrence.once) break;
      }
    }

    occurrences.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return occurrences;
  }

  bool _matchesDay(Reminder reminder, DateTime day) {
    switch (reminder.recurrence) {
      case ReminderRecurrence.once:
        return true;
      case ReminderRecurrence.daily:
        return true;
      case ReminderRecurrence.weekly:
        return reminder.weekdays.contains(day.weekday);
    }
  }
}

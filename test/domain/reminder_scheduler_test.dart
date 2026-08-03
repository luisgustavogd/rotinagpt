import 'package:flutter_test/flutter_test.dart';
import 'package:rotinagpt/domain/notifications/reminder.dart';
import 'package:rotinagpt/domain/notifications/reminder_scheduler.dart';
import 'package:rotinagpt/domain/notifications/silence_window.dart';

void main() {
  const scheduler = ReminderScheduler();

  test(
    'RF-060: lembrete diário gera uma ocorrência por dia dentro da janela',
    () {
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.medication,
        time: '08:00',
        recurrence: ReminderRecurrence.daily,
        active: true,
      );

      final occurrences = scheduler.computeOccurrences(
        reminders: [reminder],
        from: DateTime(2026, 8, 3, 0, 0),
        days: 3,
      );

      expect(occurrences.length, 3);
      expect(occurrences.first.dateTime, DateTime(2026, 8, 3, 8, 0));
    },
  );

  test(
    'RF-060: lembrete semanal só ocorre nos dias da semana configurados',
    () {
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.activity,
        time: '07:00',
        recurrence: ReminderRecurrence.weekly,
        weekdays: const [1, 3], // segunda e quarta
        active: true,
      );

      final occurrences = scheduler.computeOccurrences(
        reminders: [reminder],
        from: DateTime(2026, 8, 3, 0, 0), // segunda-feira
        days: 7,
      );

      expect(occurrences.length, 2);
    },
  );

  test('RN-009: lembrete inativo não gera nenhuma ocorrência', () {
    final reminder = Reminder(
      id: 'r1',
      type: ReminderType.weight,
      time: '08:00',
      recurrence: ReminderRecurrence.daily,
      active: false,
    );

    final occurrences = scheduler.computeOccurrences(
      reminders: [reminder],
      from: DateTime(2026, 8, 3),
      days: 5,
    );

    expect(occurrences, isEmpty);
  });

  test('RF-062: ocorrência dentro do horário de silêncio é filtrada', () {
    final reminder = Reminder(
      id: 'r1',
      type: ReminderType.meal,
      time: '23:00',
      recurrence: ReminderRecurrence.daily,
      active: true,
    );

    final occurrences = scheduler.computeOccurrences(
      reminders: [reminder],
      from: DateTime(2026, 8, 3),
      days: 2,
      silenceWindow: const SilenceWindow(start: '22:00', end: '06:00'),
    );

    expect(occurrences, isEmpty);
  });
}

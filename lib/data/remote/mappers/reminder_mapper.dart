import '../../../domain/notifications/reminder.dart';

class ReminderMapper {
  const ReminderMapper._();

  static Map<String, dynamic> toMap(Reminder reminder) => {
    'type': reminder.type.name,
    'time': reminder.time,
    'recurrence': reminder.recurrence.name,
    'weekdays': reminder.weekdays,
    'active': reminder.active,
    'relatedItemId': reminder.relatedItemId,
    'label': reminder.label,
  };

  static Reminder fromMap(String id, Map<String, dynamic> map) => Reminder(
    id: id,
    type: ReminderType.values.byName(map['type'] as String),
    time: map['time'] as String,
    recurrence: ReminderRecurrence.values.byName(map['recurrence'] as String),
    weekdays: List<int>.from(map['weekdays'] as List? ?? []),
    active: map['active'] as bool? ?? true,
    relatedItemId: map['relatedItemId'] as String?,
    label: map['label'] as String?,
  );
}

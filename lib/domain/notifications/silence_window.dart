/// RF-062 — janela de silêncio configurada pelo usuário; nenhuma notificação
/// deve ser entregue dentro dela.
class SilenceWindow {
  const SilenceWindow({required this.start, required this.end});

  /// "HH:mm".
  final String start;
  final String end;

  bool contains(DateTime dateTime) {
    final minutesOfDay = dateTime.hour * 60 + dateTime.minute;
    final startMin = _toMinutes(start);
    final endMin = _toMinutes(end);
    if (startMin == endMin) return false;
    if (startMin < endMin) {
      return minutesOfDay >= startMin && minutesOfDay < endMin;
    }
    // Janela atravessa a meia-noite (ex.: 22:00-06:00).
    return minutesOfDay >= startMin || minutesOfDay < endMin;
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

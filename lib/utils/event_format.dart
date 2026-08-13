import '../models/event.dart';

const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

String _pad(int n) => n.toString().padLeft(2, '0');

/// Wandelt in die lokale Zeitzone des Geräts um — Nutzer sehen also ihre
/// eigene Ortszeit, nicht die des Austragungsorts.
String formatMatchDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final weekday = _weekdays[local.weekday - 1];
  return '$weekday, ${_pad(local.day)}.${_pad(local.month)}. · ${_pad(local.hour)}:${_pad(local.minute)} Uhr';
}

String formatDateRange(DateTime start, DateTime end) {
  final s = start.toLocal();
  final e = end.toLocal();
  final startStr = '${_pad(s.day)}.${_pad(s.month)}.';
  if (s.year == e.year && s.month == e.month && s.day == e.day) {
    return '$startStr${e.year}';
  }
  return '$startStr–${_pad(e.day)}.${_pad(e.month)}.${e.year}';
}

String formatEventFormat(EventFormat format) {
  switch (format) {
    case EventFormat.knockout:
      return 'K.-o.-System';
    case EventFormat.roundRobin:
      return 'Gruppenphase';
  }
}

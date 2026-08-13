String relativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'gerade eben';
  if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
  if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
  return 'vor ${diff.inDays} Tg';
}

String _pad(int n) => n.toString().padLeft(2, '0');

/// Für News: relative Zeit nur für wirklich Aktuelles (<48 Std.), sonst ein
/// echtes Datum — sorgt dafür, dass ältere Meldungen nicht fälschlich als
/// "gerade eben" wirken, nur weil der Agent sie erst heute gefunden hat.
String newsDate(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inHours < 48) return relativeTime(dateTime);
  final local = dateTime.toLocal();
  return '${_pad(local.day)}.${_pad(local.month)}.${local.year}';
}

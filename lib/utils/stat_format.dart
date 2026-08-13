/// 0 steht für „noch nicht erfasst" (siehe scripts/seed/seed.mjs), nicht für
/// einen echten Messwert — wird daher als „–" statt als falsche Zahl gezeigt.
String formatAverage(double value) => value == 0 ? '–' : value.toStringAsFixed(1);

String formatPercentage(double value) => value == 0 ? '–' : '${value.toStringAsFixed(1)}%';

String formatCount(int value) => value == 0 ? '–' : '$value';

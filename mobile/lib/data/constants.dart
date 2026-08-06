import 'package:intl/intl.dart';

const List<String> kWeekdays = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

const List<String> kWeekdaysShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

final NumberFormat _deFmt = NumberFormat.decimalPattern('de_DE');
final NumberFormat _deFmt1 = NumberFormat('0.0', 'de_DE');

/// German-locale number formatting (comma decimal separator), pendant to the
/// original `n.toLocaleString('de-DE')`.
String fmt(num n) => _deFmt.format(n);

/// Same as [fmt] but always shows exactly one decimal place.
String fmt1(num n) => _deFmt1.format(n);

/// Weekday-mode "today" index (0=Montag..6=Sonntag); falls back to the given
/// rotation-mode `currentDayIdx` when `mode != 'weekday'`.
int todayIndexForProgram({required String mode, required int currentDayIdx}) {
  if (mode == 'weekday') {
    // JS Date.getDay(): Sun=0..Sat=6, mapped via (js+6)%7 -> Mon=0..Sun=6.
    final jsWeekday = DateTime.now().weekday % 7; // Dart Mon=1..Sun=7 -> Sun=0..Sat=6
    return (jsWeekday + 6) % 7;
  }
  return currentDayIdx;
}

/// Whole days elapsed since an ISO 'YYYY-MM-DD' date string (floor, min 0).
int daysSince(String isoDate) {
  final start = DateTime.parse(isoDate);
  final startMidnight = DateTime(start.year, start.month, start.day);
  final now = DateTime.now();
  final nowMidnight = DateTime(now.year, now.month, now.day);
  final diff = nowMidnight.difference(startMidnight).inDays;
  return diff < 0 ? 0 : diff;
}

/// Today's date as 'YYYY-MM-DD'.
String todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// Today's date as an unpadded 'D.M' label — matches the original
/// `addEntry()` which pushes `{l: 'D.M', v}` onto a lift's history.
String todayShortLabel() {
  final now = DateTime.now();
  return '${now.day}.${now.month}';
}

/// ISO 'YYYY-MM-DD' -> 'DD.MM.YYYY', used for displaying PR dates.
String fmtDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}.${parts[1]}.${parts[0]}';
}

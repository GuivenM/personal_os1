import '../models/schedule_model.dart';

const _exportDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Parses pasted spreadsheet cells (TSV) or a CSV file into rows of cells.
///
/// The delimiter is guessed from the first non-empty line: a tab (cells
/// copied from Google Sheets / Excel), otherwise `;` (French Excel CSV) if
/// it appears more often than `,`, otherwise `,`. Double-quoted cells (with
/// `""` as an escaped quote) are supported. Empty lines are kept on purpose
/// so the server's "Line N" errors match the line numbers in the text box;
/// only trailing empty lines are dropped.
List<List<String>> parseDelimited(String input) {
  final text = input.replaceFirst('\uFEFF', '');
  if (text.trim().isEmpty) return [];

  final firstLine = text.split(RegExp(r'\r?\n')).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final tabs = '\t'.allMatches(firstLine).length;
  final semicolons = ';'.allMatches(firstLine).length;
  final commas = ','.allMatches(firstLine).length;
  final delimiter = tabs > 0 ? '\t' : (semicolons > commas ? ';' : ',');

  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;

  void endCell() {
    row.add(cell.toString().trim());
    cell.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"' && cell.isEmpty) {
      inQuotes = true;
    } else if (ch == delimiter) {
      endCell();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endCell();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  endCell();
  rows.add(row);

  while (rows.isNotEmpty && rows.last.every((c) => c.isEmpty)) {
    rows.removeLast();
  }
  return rows;
}

/// The whole week as tab-separated text (one block per row), ready to paste
/// into Google Sheets / Excel. Re-importing it gives the same schedule.
String buildScheduleTsv(WeekScheduleResponse week) {
  String clean(String v) => v.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();
  String hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  final out = StringBuffer('Day\tStart\tEnd\tName\tDescription\n');
  final days = [...week.days]..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  for (final day in days) {
    for (final block in day.blocks) {
      out.writeln([
        _exportDays[day.dayOfWeek],
        hhmm(block.timeStart),
        hhmm(block.timeEnd),
        clean(block.name),
        clean(block.description),
      ].join('\t'));
    }
  }
  return out.toString();
}

/// The backend occasionally returns numeric aggregates (SQL `SUM()`,
/// `COUNT()`) as strings instead of JSON numbers (a common PHP/mysqli
/// quirk). These helpers parse either shape safely instead of crashing
/// with a failed `as int` cast.
int asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  return fallback;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}

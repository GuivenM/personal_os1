import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recap_model.dart';
import '../../../core/services/auth_service.dart';

/// The month currently selected on the Recap screen, as `YYYY-MM`.
/// Defaults to the current month.
final selectedRecapMonthProvider = StateProvider.autoDispose<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

/// Fetches the recap for whatever month is currently selected. Backed by
/// a single slow-ish GET (server does DB aggregation + an LLM call), so
/// re-fetches whenever the selected month changes rather than trying to
/// keep every month's recap around.
final recapProvider = FutureProvider.autoDispose<MonthlyRecap>((ref) async {
  final month = ref.watch(selectedRecapMonthProvider);
  final api = ref.read(recapApiProvider);
  return api.getRecap(month: month);
});

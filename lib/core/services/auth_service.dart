import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/books_api.dart';
import '../api/dashboard_api.dart';
import '../api/health_api.dart';
import '../api/journal_api.dart';
import '../api/learning_api.dart';
import '../api/music_api.dart';
import '../api/recap_api.dart';
import '../api/schedule_api.dart';
import '../api/spiritual_api.dart';
import '../api/vision_api.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// --- Core providers -------------------------------------------------

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(storageService: ref.watch(storageServiceProvider));
  ref.onDispose(() {});
  return client;
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(apiClientProvider));
});

final scheduleApiProvider = Provider<ScheduleApi>((ref) {
  return ScheduleApi(ref.watch(apiClientProvider));
});

final booksApiProvider = Provider<BooksApi>((ref) {
  return BooksApi(ref.watch(apiClientProvider));
});

final healthApiProvider = Provider<HealthApi>((ref) {
  return HealthApi(ref.watch(apiClientProvider));
});

final journalApiProvider = Provider<JournalApi>((ref) {
  return JournalApi(ref.watch(apiClientProvider));
});

final learningApiProvider = Provider<LearningApi>((ref) {
  return LearningApi(ref.watch(apiClientProvider));
});

final musicApiProvider = Provider<MusicApi>((ref) {
  return MusicApi(ref.watch(apiClientProvider));
});

final visionApiProvider = Provider<VisionApi>((ref) {
  return VisionApi(ref.watch(apiClientProvider));
});

final spiritualApiProvider = Provider<SpiritualApi>((ref) {
  return SpiritualApi(ref.watch(apiClientProvider));
});

final recapApiProvider = Provider<RecapApi>((ref) {
  return RecapApi(ref.watch(apiClientProvider));
});

/// --- Auth state -------------------------------------------------------

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Holds authentication state, persists the JWT token, and reacts to
/// 401 responses from [ApiClient] by forcing a logout.
class AuthService extends StateNotifier<AuthState> {
  AuthService(this._authApi, this._storage, this._apiClient) : super(const AuthState()) {
    _apiClient.onUnauthorized = _forceLogout;
    restoreSession();
  }

  final AuthApi _authApi;
  final StorageService _storage;
  final ApiClient _apiClient;

  /// Checks for a stored token on app start and validates it against
  /// `GET /auth/me`. Falls back to the unauthenticated state on any error.
  Future<void> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _authApi.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _storage.deleteToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _authApi.login(username: username, password: password);
      await _storage.saveToken(result.token);
      await _storage.saveUsername(result.user.username);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> register({required String username, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _authApi.register(username: username, password: password);
      await _storage.saveToken(result.token);
      await _storage.saveUsername(result.user.username);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // Best-effort: we still clear local state even if the network call fails.
    }
    await _storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _forceLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authServiceProvider = StateNotifierProvider<AuthService, AuthState>((ref) {
  return AuthService(
    ref.watch(authApiProvider),
    ref.watch(storageServiceProvider),
    ref.watch(apiClientProvider),
  );
});

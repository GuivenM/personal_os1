import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/services/auth_service.dart';
import 'core/services/lock_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/lock_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/pin_setup_screen.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Requests the notification permission on first launch and sets up the
  // local timezone; scheduling itself happens once the Dashboard loads
  // today's blocks (see dashboard_screen.dart).
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: PersonalOsApp()));
}

/// Bridges Riverpod's auth + lock state changes to go_router's
/// [Listenable]-based refresh mechanism, so navigation reacts immediately
/// to login/logout/401/lock events.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    ref.listen<AuthState>(authServiceProvider, (_, __) => notifyListeners());
    ref.listen<PinLockState>(lockServiceProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authServiceProvider);
      final lock = ref.read(lockServiceProvider);
      final loc = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return loc == '/login' ? null : '/login';
        case AuthStatus.locked:
          return loc == '/lock' ? null : '/lock';
        case AuthStatus.authenticated:
          // First login on this device: offer to set a PIN (once).
          final needsSetup = lock.loaded && !lock.hasPin && !lock.setupPrompted;
          if (needsSetup) return loc == '/setup-pin' ? null : '/setup-pin';
          if (loc == '/login' || loc == '/splash' || loc == '/lock' || loc == '/setup-pin') {
            return '/';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      GoRoute(path: '/setup-pin', builder: (context, state) => const PinSetupScreen(isFirstRun: true)),
      GoRoute(path: '/', builder: (context, state) => const MainShell()),
    ],
  );
});

class PersonalOsApp extends ConsumerStatefulWidget {
  const PersonalOsApp({super.key});

  @override
  ConsumerState<PersonalOsApp> createState() => _PersonalOsAppState();
}

class _PersonalOsAppState extends ConsumerState<PersonalOsApp> with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-lock when the app comes back after [kRelockAfter] in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt == null) return;
      if (ref.read(lockServiceProvider.notifier).isPrompting) return;
      if (DateTime.now().difference(pausedAt) >= kRelockAfter) {
        ref.read(authServiceProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Personal OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.violet),
      ),
    );
  }
}

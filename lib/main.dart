import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Requests the notification permission on first launch and sets up the
  // local timezone; scheduling itself happens once the Dashboard loads
  // today's blocks (see dashboard_screen.dart).
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: PersonalOsApp()));
}

/// Bridges Riverpod's [authServiceProvider] changes to go_router's
/// [Listenable]-based refresh mechanism, so navigation reacts immediately
/// to login/logout/401 events.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    ref.listen<AuthState>(authServiceProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authServiceProvider);
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';

      if (authState.status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        return loggingIn ? null : '/login';
      }

      // Authenticated
      if (loggingIn || onSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const MainShell()),
    ],
  );
});

class PersonalOsApp extends ConsumerWidget {
  const PersonalOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

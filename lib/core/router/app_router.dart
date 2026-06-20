import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/state_providers.dart';
import '../../features/ui_screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final keyCustody = ref.watch(keyCustodyProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';
      
      if (isSplash) return null;

      if (!loggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // If authenticated in Supabase but local vault is locked, force vault unlock
      final isUnlockingVault = state.matchedLocation == '/unlock';
      if (!keyCustody.isUnlocked) {
        return isUnlockingVault ? null : '/unlock';
      }

      // If logged in and unlocked, prevent access to login/unlock routes
      if (isLoggingIn || isUnlockingVault) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const VaultUnlockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigationScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/vault',
            builder: (context, state) => const VaultScreen(),
          ),
          GoRoute(
            path: '/timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const GalleryScreen(),
          ),
          GoRoute(
            path: '/period',
            builder: (context, state) => const PeriodTrackerScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/life_planner',
            builder: (context, state) => const LifePlannerScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/focus',
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: '/memories',
            builder: (context, state) => const MemoriesScreen(),
          ),
          GoRoute(
            path: '/quotes',
            builder: (context, state) => const QuotesScreen(),
          ),
          GoRoute(
            path: '/preferences',
            builder: (context, state) => const PreferencesScreen(),
          ),
          GoRoute(
            path: '/social_matrix',
            builder: (context, state) => const SocialMatrixScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

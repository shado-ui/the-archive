import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/colors.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/security/session_lock.dart';
import 'core/providers/state_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase SDK
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: TheKrishaArchive(),
    ),
  );
}

class TheKrishaArchive extends ConsumerWidget {
  const TheKrishaArchive({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final keyCustody = ref.watch(keyCustodyProvider);

    return SessionLockGate(
      keyCustody: keyCustody,
      timeout: const Duration(minutes: 5), // Auto-lock vault key after 5 minutes of inactivity
      onLocked: () {
        // Clear Riverpod vault key state
        ref.read(vaultKeyProvider.notifier).state = null;
        // Redirect back to Vault Unlock gate
        router.go('/unlock');
      },
      child: MaterialApp.router(
        title: 'The Krisha Archive',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.roseSpark,
            secondary: AppColors.auroraCyan,
            surface: AppColors.spaceDark,
            error: AppColors.errorRed,
          ),
          scaffoldBackgroundColor: AppColors.spaceDark,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          cardTheme: CardTheme(
            color: AppColors.cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.cardBg,
            labelStyle: const TextStyle(color: Colors.white),
            side: const BorderSide(color: AppColors.glassBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          navigationRailTheme: const NavigationRailThemeData(
            backgroundColor: AppColors.nebulaViolet,
            selectedIconTheme: IconThemeData(color: AppColors.roseSpark),
            unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
            selectedLabelTextStyle: TextStyle(color: AppColors.roseSpark),
            unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}

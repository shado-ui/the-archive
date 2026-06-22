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
      child: TheArchive(),
    ),
  );
}

class TheArchive extends ConsumerWidget {
  const TheArchive({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final keyCustody = ref.watch(keyCustodyProvider);
    final appTheme = ref.watch(themeProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return SessionLockGate(
      keyCustody: keyCustody,
      timeout: const Duration(minutes: 5),
      onLocked: () {
        keyCustody.lockVault();
        router.go('/unlock');
      },
      child: MaterialApp.router(
        title: 'The Archive',
        debugShowCheckedModeBanner: false,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.light(
            primary: AppColors.getAccent(appTheme),
            secondary: AppColors.roseSpark,
            surface: AppColors.getSurface(appTheme, false),
            error: AppColors.errorRed,
          ),
          scaffoldBackgroundColor: AppColors.getBackground(appTheme, false),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.getTextPrimary(false)),
            titleTextStyle: TextStyle(color: AppColors.getTextPrimary(false), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          cardTheme: CardTheme(
            color: AppColors.getSurface(appTheme, false),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.getGlassBorder(false)),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.getSurface(appTheme, false),
            labelStyle: TextStyle(color: AppColors.getTextPrimary(false)),
            side: BorderSide(color: AppColors.getGlassBorder(false)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          navigationRailTheme: NavigationRailThemeData(
            backgroundColor: AppColors.getSurface(appTheme, false),
            selectedIconTheme: IconThemeData(color: AppColors.getAccent(appTheme)),
            unselectedIconTheme: IconThemeData(color: AppColors.getTextMuted(false)),
            selectedLabelTextStyle: TextStyle(color: AppColors.getAccent(appTheme)),
            unselectedLabelTextStyle: TextStyle(color: AppColors.getTextMuted(false)),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: AppColors.getAccent(appTheme),
            secondary: AppColors.roseSpark,
            surface: AppColors.getSurface(appTheme, true),
            error: AppColors.errorRed,
          ),
          scaffoldBackgroundColor: AppColors.getBackground(appTheme, true),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.getTextPrimary(true)),
            titleTextStyle: TextStyle(color: AppColors.getTextPrimary(true), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          cardTheme: CardTheme(
            color: AppColors.cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.getGlassBorder(true)),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.cardBg,
            labelStyle: TextStyle(color: AppColors.getTextPrimary(true)),
            side: BorderSide(color: AppColors.getGlassBorder(true)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          navigationRailTheme: NavigationRailThemeData(
            backgroundColor: AppColors.getSurface(appTheme, true),
            selectedIconTheme: IconThemeData(color: AppColors.getAccent(appTheme)),
            unselectedIconTheme: IconThemeData(color: AppColors.getTextMuted(true)),
            selectedLabelTextStyle: TextStyle(color: AppColors.getAccent(appTheme)),
            unselectedLabelTextStyle: TextStyle(color: AppColors.getTextMuted(true)),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../security/key_custody.dart';
import '../repositories/repositories.dart';
import '../models/dart_models.dart';
import '../constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --------------------------------------------------------------------
// 1. Core Services Providers
// --------------------------------------------------------------------

// Theme Providers
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

final isDarkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(AppTheme.cosmicDark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('app_theme') ?? 0;
    state = AppTheme.values[themeIndex];
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme', theme.index);
  }
}

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(true) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') ?? true;
  }

  Future<void> setDarkMode(bool isDark) async {
    state = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  void toggleDarkMode() {
    setDarkMode(!state);
  }
}
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final keyCustodyProvider = Provider<KeyCustodyService>((ref) {
  return KeyCustodyService();
});

// --------------------------------------------------------------------
// 2. Encryption Key State Providers
// --------------------------------------------------------------------
final vaultKeyProvider = StateProvider<List<int>?>((ref) {
  final custody = ref.watch(keyCustodyProvider);
  return custody.vaultKey;
});

final vaultLockedProvider = StateProvider<bool>((ref) {
  final key = ref.watch(vaultKeyProvider);
  return key == null;
});

// --------------------------------------------------------------------
// 3. Database Repositories Providers
// --------------------------------------------------------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final partnerProfileRepositoryProvider = Provider<PartnerProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PartnerProfileRepository(client);
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return VaultRepository(client);
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MemoryRepository(client);
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TimelineRepository(client);
});

final periodTrackerRepositoryProvider = Provider<PeriodTrackerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PeriodTrackerRepository(client);
});

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return QuoteRepository(client);
});

final conflictRepositoryProvider = Provider<ConflictRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ConflictRepository(client);
});

final giftRepositoryProvider = Provider<GiftRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GiftRepository(client);
});

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PreferenceRepository(client);
});

final healthWellnessRepositoryProvider = Provider<HealthWellnessRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HealthWellnessRepository(client);
});

final timeBlockRepositoryProvider = Provider<TimeBlockRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TimeBlockRepository(client);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TaskRepository(client);
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GoalRepository(client);
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HabitRepository(client);
});

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RoutineRepository(client);
});

final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FocusSessionRepository(client);
});

final dailyReflectionRepositoryProvider = Provider<DailyReflectionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DailyReflectionRepository(client);
});

final timeLogRepositoryProvider = Provider<TimeLogRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TimeLogRepository(client);
});

// --------------------------------------------------------------------
// 4. Session & Auth Stream Providers
// --------------------------------------------------------------------
final authSessionProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

// --------------------------------------------------------------------
// 5. Reactive Data Query Providers (Fetches & Caching)
// --------------------------------------------------------------------

/// Partner Profile (Krisha Details)
final partnerProfileProvider = FutureProvider<PartnerProfile?>((ref) async {
  final repo = ref.watch(partnerProfileRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return await repo.getPartnerProfile(user.id);
});

/// Secure Platform Credentials (requires vault unlocked)
final vaultCredentialsProvider = FutureProvider<List<PlatformCredential>>((ref) async {
  final isLocked = ref.watch(vaultLockedProvider);
  if (isLocked) return [];
  
  final repo = ref.watch(vaultRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getCredentials(user.id);
});

/// Memories Timeline List
final memoriesListProvider = FutureProvider<List<Memory>>((ref) async {
  final repo = ref.watch(memoryRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getMemories(user.id);
});

/// Global Unified Activity Feed Timeline
final globalTimelineProvider = FutureProvider<List<TimelineEvent>>((ref) async {
  final repo = ref.watch(timelineRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getTimeline(user.id);
});

/// Period Logs List
final periodRecordsProvider = FutureProvider<List<PeriodRecord>>((ref) async {
  final repo = ref.watch(periodTrackerRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getPeriods(user.id);
});

/// Quotes List
final quotesListProvider = FutureProvider<List<Quote>>((ref) async {
  final repo = ref.watch(quoteRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getQuotes(user.id);
});

/// Conflict Logs List
final conflictLogsProvider = FutureProvider<List<ConflictLog>>((ref) async {
  final repo = ref.watch(conflictRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getConflicts(user.id);
});

/// Gift Database List
final giftsListProvider = FutureProvider<List<Gift>>((ref) async {
  final repo = ref.watch(giftRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getGifts(user.id);
});

/// Preferences List
final preferencesListProvider = FutureProvider<List<Preference>>((ref) async {
  final repo = ref.watch(preferenceRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getPreferences(user.id);
});

/// Social Matrix List
final socialMatrixProvider = FutureProvider<List<SocialPerson>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final response = await client
      .from('social_matrix')
      .select()
      .eq('user_id', user.id)
      .order('name');
  return (response as List).map((json) => SocialPerson.fromJson(json)).toList();
});

/// Time Blocks List
final timeBlocksProvider = FutureProvider<List<TimeBlock>>((ref) async {
  final repo = ref.watch(timeBlockRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getTimeBlocks(user.id);
});

/// Tasks List
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getTasks(user.id);
});

/// Goals List
final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getGoals(user.id);
});

/// Goal Categories List
final goalCategoriesProvider = FutureProvider<List<GoalCategory>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getGoalCategories(user.id);
});

/// Habits List
final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getHabits(user.id);
});

/// Routines List
final routinesProvider = FutureProvider<List<Routine>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getRoutines(user.id);
});

/// Focus Sessions List
final focusSessionsProvider = FutureProvider<List<FocusSession>>((ref) async {
  final repo = ref.watch(focusSessionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getFocusSessions(user.id);
});

/// Daily Reflections List
final dailyReflectionsProvider = FutureProvider<List<DailyReflection>>((ref) async {
  final repo = ref.watch(dailyReflectionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getDailyReflections(user.id);
});

/// Time Logs List
final timeLogsProvider = FutureProvider<List<TimeLog>>((ref) async {
  final repo = ref.watch(timeLogRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await repo.getTimeLogs(user.id);
});

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dart_models.dart';

class BaseRepository {
  final SupabaseClient client;
  BaseRepository(this.client);
}

// --------------------------------------------------------------------
// 1. AuthRepository
// --------------------------------------------------------------------
class AuthRepository extends BaseRepository {
  AuthRepository(super.client);

  /// Authenticate user via Supabase Auth
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signup a new user account and insert the profile salt
  Future<AuthResponse> signUp(String email, String password, String saltHex) async {
    final response = await client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await client.from('profiles').insert({
        'id': response.user!.id,
        'vault_salt': saltHex,
      });
    }
    return response;
  }

  /// Retrieve the client-side vault salt for a user profile
  Future<String?> getVaultSalt(String email) async {
    // Queries public endpoint for salt to derive key before login
    try {
      final response = await client
          .from('profiles')
          .select('vault_salt')
          .limit(1)
          .maybeSingle();
      return response?['vault_salt'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}

// --------------------------------------------------------------------
// 2. PartnerProfileRepository (Krisha Profile details)
// --------------------------------------------------------------------
class PartnerProfileRepository extends BaseRepository {
  PartnerProfileRepository(super.client);

  Future<PartnerProfile?> getPartnerProfile(String userId) async {
    final response = await client
        .from('partner_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return PartnerProfile.fromJson(response);
  }

  Future<void> upsertPartnerProfile(PartnerProfile profile) async {
    await client.from('partner_profiles').upsert(profile.toJson());
  }
}

// --------------------------------------------------------------------
// 3. VaultRepository (Credentials Vault)
// --------------------------------------------------------------------
class VaultRepository extends BaseRepository {
  VaultRepository(super.client);

  Future<List<PlatformCredential>> getCredentials(String userId) async {
    final response = await client
        .from('cipher_vault')
        .select()
        .eq('user_id', userId)
        .order('platform_name');
    return (response as List).map((json) => PlatformCredential.fromJson(json)).toList();
  }

  Future<void> saveCredential(PlatformCredential credential) async {
    await client.from('cipher_vault').upsert(credential.toJson());
  }

  Future<void> deleteCredential(String id) async {
    await client.from('cipher_vault').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 4. MemoryRepository & Media
// --------------------------------------------------------------------
class MemoryRepository extends BaseRepository {
  MemoryRepository(super.client);

  Future<List<Memory>> getMemories(String userId) async {
    final response = await client
        .from('memories')
        .select()
        .eq('user_id', userId)
        .order('memory_date', ascending: false);
    return (response as List).map((json) => Memory.fromJson(json)).toList();
  }

  Future<Memory> saveMemory(Memory memory) async {
    final response = await client.from('memories').upsert(memory.toJson()).select().single();
    return Memory.fromJson(response);
  }

  Future<void> deleteMemory(String id) async {
    await client.from('memories').delete().eq('id', id);
  }

  /// Supabase Storage Upload for Media assets
  Future<String> uploadMediaFile(String bucket, String path, List<int> bytes, String mimeType) async {
    await client.storage.from(bucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }
}

// --------------------------------------------------------------------
// 5. TimelineRepository
// --------------------------------------------------------------------
class TimelineRepository extends BaseRepository {
  TimelineRepository(super.client);

  Future<List<TimelineEvent>> getTimeline(String userId) async {
    final response = await client
        .from('timeline_events')
        .select()
        .eq('user_id', userId)
        .order('event_date', ascending: false);
    return (response as List).map((json) => TimelineEvent.fromJson(json)).toList();
  }
}

// --------------------------------------------------------------------
// 6. PeriodTrackerRepository
// --------------------------------------------------------------------
class PeriodTrackerRepository extends BaseRepository {
  PeriodTrackerRepository(super.client);

  Future<List<PeriodRecord>> getPeriods(String userId) async {
    final response = await client
        .from('period_records')
        .select()
        .eq('user_id', userId)
        .order('start_date', ascending: false);
    return (response as List).map((json) => PeriodRecord.fromJson(json)).toList();
  }

  Future<void> savePeriod(PeriodRecord record) async {
    await client.from('period_records').upsert(record.toJson());
  }

  Future<void> deletePeriod(String id) async {
    await client.from('period_records').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 7. QuoteRepository
// --------------------------------------------------------------------
class QuoteRepository extends BaseRepository {
  QuoteRepository(super.client);

  Future<List<Quote>> getQuotes(String userId) async {
    final response = await client
        .from('quote_vault')
        .select()
        .eq('user_id', userId)
        .order('quote_date', ascending: false);
    return (response as List).map((json) => Quote.fromJson(json)).toList();
  }

  Future<void> saveQuote(Quote quote) async {
    await client.from('quote_vault').upsert(quote.toJson());
  }
}

// --------------------------------------------------------------------
// 8. ConflictRepository
// --------------------------------------------------------------------
class ConflictRepository extends BaseRepository {
  ConflictRepository(super.client);

  Future<List<ConflictLog>> getConflicts(String userId) async {
    final response = await client
        .from('conflict_logs')
        .select()
        .eq('user_id', userId)
        .order('conflict_date', ascending: false);
    return (response as List).map((json) => ConflictLog.fromJson(json)).toList();
  }

  Future<void> saveConflict(ConflictLog log) async {
    await client.from('conflict_logs').upsert(log.toJson());
  }
}

// --------------------------------------------------------------------
// 9. GiftRepository
// --------------------------------------------------------------------
class GiftRepository extends BaseRepository {
  GiftRepository(super.client);

  Future<List<Gift>> getGifts(String userId) async {
    final response = await client
        .from('gifts_database')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Gift.fromJson(json)).toList();
  }

  Future<void> saveGift(Gift gift) async {
    await client.from('gifts_database').upsert(gift.toJson());
  }

  Future<void> deleteGift(String id) async {
    await client.from('gifts_database').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 10. PreferenceRepository
// --------------------------------------------------------------------
class PreferenceRepository extends BaseRepository {
  PreferenceRepository(super.client);

  Future<List<Preference>> getPreferences(String userId) async {
    final response = await client
        .from('preferences')
        .select()
        .eq('user_id', userId)
        .order('category');
    return (response as List).map((json) => Preference.fromJson(json)).toList();
  }

  Future<void> savePreference(Preference preference) async {
    await client.from('preferences').upsert(preference.toJson());
  }

  Future<void> deletePreference(String id) async {
    await client.from('preferences').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 11. HealthWellnessRepository
// --------------------------------------------------------------------
class HealthWellnessRepository extends BaseRepository {
  HealthWellnessRepository(super.client);

  Future<HealthWellness?> getHealthWellness(String userId) async {
    final response = await client
        .from('health_wellness')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return HealthWellness.fromJson(response);
  }

  Future<void> saveHealthWellness(HealthWellness wellness) async {
    await client.from('health_wellness').upsert(wellness.toJson());
  }
}

// --------------------------------------------------------------------
// 12. TimeBlockRepository
// --------------------------------------------------------------------
class TimeBlockRepository extends BaseRepository {
  TimeBlockRepository(super.client);

  Future<List<TimeBlock>> getTimeBlocks(String ownerId) async {
    final response = await client
        .from('time_blocks')
        .select()
        .eq('owner_id', ownerId)
        .order('start_time', ascending: true);
    return (response as List).map((json) => TimeBlock.fromJson(json)).toList();
  }

  Future<void> saveTimeBlock(TimeBlock block) async {
    await client.from('time_blocks').upsert(block.toJson());
  }

  Future<void> deleteTimeBlock(String id) async {
    await client.from('time_blocks').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 13. TaskRepository
// --------------------------------------------------------------------
class TaskRepository extends BaseRepository {
  TaskRepository(super.client);

  Future<List<Task>> getTasks(String ownerId) async {
    final response = await client
        .from('tasks')
        .select()
        .eq('owner_id', ownerId)
        .order('due_date', ascending: true);
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  Future<void> saveTask(Task task) async {
    await client.from('tasks').upsert(task.toJson());
  }

  Future<void> deleteTask(String id) async {
    await client.from('tasks').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 14. GoalRepository
// --------------------------------------------------------------------
class GoalRepository extends BaseRepository {
  GoalRepository(super.client);

  Future<List<GoalCategory>> getGoalCategories(String ownerId) async {
    final response = await client
        .from('goal_categories')
        .select()
        .eq('owner_id', ownerId);
    return (response as List).map((json) => GoalCategory.fromJson(json)).toList();
  }

  Future<void> saveGoalCategory(GoalCategory category) async {
    await client.from('goal_categories').upsert(category.toJson());
  }

  Future<List<Goal>> getGoals(String ownerId) async {
    final response = await client
        .from('goals')
        .select()
        .eq('owner_id', ownerId)
        .order('target_date', ascending: true);
    return (response as List).map((json) => Goal.fromJson(json)).toList();
  }

  Future<void> saveGoal(Goal goal) async {
    await client.from('goals').upsert(goal.toJson());
  }

  Future<void> deleteGoal(String id) async {
    await client.from('goals').delete().eq('id', id);
  }

  Future<List<GoalMilestone>> getMilestones(String goalId) async {
    final response = await client
        .from('goal_milestones')
        .select()
        .eq('goal_id', goalId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => GoalMilestone.fromJson(json)).toList();
  }

  Future<void> saveMilestone(GoalMilestone milestone) async {
    await client.from('goal_milestones').upsert(milestone.toJson());
  }

  Future<void> deleteMilestone(String id) async {
    await client.from('goal_milestones').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 15. HabitRepository
// --------------------------------------------------------------------
class HabitRepository extends BaseRepository {
  HabitRepository(super.client);

  Future<List<Habit>> getHabits(String ownerId) async {
    final response = await client
        .from('habits')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => Habit.fromJson(json)).toList();
  }

  Future<void> saveHabit(Habit habit) async {
    await client.from('habits').upsert(habit.toJson());
  }

  Future<void> deleteHabit(String id) async {
    await client.from('habits').delete().eq('id', id);
  }

  Future<List<HabitLog>> getHabitLogs(String habitId) async {
    final response = await client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .order('completed_date', ascending: false);
    return (response as List).map((json) => HabitLog.fromJson(json)).toList();
  }

  Future<void> logHabit(HabitLog log) async {
    await client.from('habit_logs').upsert(log.toJson());
  }

  Future<void> deleteHabitLog(String id) async {
    await client.from('habit_logs').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 16. RoutineRepository
// --------------------------------------------------------------------
class RoutineRepository extends BaseRepository {
  RoutineRepository(super.client);

  Future<List<Routine>> getRoutines(String ownerId) async {
    final response = await client
        .from('routines')
        .select()
        .eq('owner_id', ownerId);
    return (response as List).map((json) => Routine.fromJson(json)).toList();
  }

  Future<void> saveRoutine(Routine routine) async {
    await client.from('routines').upsert(routine.toJson());
  }

  Future<void> deleteRoutine(String id) async {
    await client.from('routines').delete().eq('id', id);
  }

  Future<List<RoutineStep>> getRoutineSteps(String routineId) async {
    final response = await client
        .from('routine_steps')
        .select()
        .eq('routine_id', routineId)
        .order('step_order', ascending: true);
    return (response as List).map((json) => RoutineStep.fromJson(json)).toList();
  }

  Future<void> saveRoutineStep(RoutineStep step) async {
    await client.from('routine_steps').upsert(step.toJson());
  }

  Future<void> deleteRoutineStep(String id) async {
    await client.from('routine_steps').delete().eq('id', id);
  }
}

// --------------------------------------------------------------------
// 17. FocusSessionRepository
// --------------------------------------------------------------------
class FocusSessionRepository extends BaseRepository {
  FocusSessionRepository(super.client);

  Future<List<FocusSession>> getFocusSessions(String ownerId) async {
    final response = await client
        .from('focus_sessions')
        .select()
        .eq('owner_id', ownerId)
        .order('start_time', ascending: false);
    return (response as List).map((json) => FocusSession.fromJson(json)).toList();
  }

  Future<void> saveFocusSession(FocusSession session) async {
    await client.from('focus_sessions').upsert(session.toJson());
  }
}

// --------------------------------------------------------------------
// 18. DailyReflectionRepository
// --------------------------------------------------------------------
class DailyReflectionRepository extends BaseRepository {
  DailyReflectionRepository(super.client);

  Future<List<DailyReflection>> getDailyReflections(String ownerId) async {
    final response = await client
        .from('daily_reflections')
        .select()
        .eq('owner_id', ownerId)
        .order('reflection_date', ascending: false);
    return (response as List).map((json) => DailyReflection.fromJson(json)).toList();
  }

  Future<void> saveDailyReflection(DailyReflection reflection) async {
    await client.from('daily_reflections').upsert(reflection.toJson());
  }
}

// --------------------------------------------------------------------
// 19. TimeLogRepository
// --------------------------------------------------------------------
class TimeLogRepository extends BaseRepository {
  TimeLogRepository(super.client);

  Future<List<TimeLog>> getTimeLogs(String ownerId) async {
    final response = await client
        .from('time_logs')
        .select()
        .eq('owner_id', ownerId)
        .order('started_at', ascending: false);
    return (response as List).map((json) => TimeLog.fromJson(json)).toList();
  }

  Future<void> saveTimeLog(TimeLog log) async {
    await client.from('time_logs').upsert(log.toJson());
  }
}


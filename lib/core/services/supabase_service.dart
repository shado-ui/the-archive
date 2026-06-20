import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Initialize the Supabase SDK. 
  /// Replace 'YOUR_SUPABASE_URL' and 'YOUR_SUPABASE_ANON_KEY' with actual credentials.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL', 
        defaultValue: 'https://your-supabase-url.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY', 
        defaultValue: 'your-anon-key-placeholder',
      ),
    );
  }

  /// Direct client instance
  SupabaseClient get client => Supabase.instance.client;
}

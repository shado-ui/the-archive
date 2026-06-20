import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Initialize the Supabase SDK. 
  /// Replace 'YOUR_SUPABASE_URL' and 'YOUR_SUPABASE_ANON_KEY' with actual credentials.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://ryefomdncqtnmiqzlknt.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_zpWsEz34jfAqQeRVGItTmA_blRZv2dM',
      ),
    );
  }

  /// Direct client instance
  SupabaseClient get client => Supabase.instance.client;
}

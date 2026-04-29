/// ─────────────────────────────────────────────────────────────────────────────
/// API Configuration
/// 
/// This app uses Supabase as the backend for cross-device sync.
/// 
/// SETUP STEPS (one-time, free):
/// 1. Go to https://supabase.com → Sign up (free, no credit card)
/// 2. Create a new project named "janki-agro-tourism"
/// 3. In the SQL Editor, run the SQL from setup_supabase.sql (in project root)
/// 4. Go to Project Settings → API
/// 5. Copy your "Project URL" and "anon public" key below
/// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  // ── Replace these with your Supabase credentials ─────────────────────────
  static const String supabaseUrl    = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
  // ─────────────────────────────────────────────────────────────────────────

  static const String orgId = 'janki_agro_tourism'; // shared org identifier

  // REST endpoints
  static String table(String name) => '$supabaseUrl/rest/v1/$name';

  static Map<String, String> get headers => {
    'apikey':        supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type':  'application/json',
    'Prefer':        'return=minimal',
  };

  static Map<String, String> get headersReturn => {
    'apikey':        supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type':  'application/json',
    'Prefer':        'return=representation',
  };

  static bool get isConfigured =>
      supabaseUrl != 'https://YOUR_PROJECT.supabase.co' &&
      supabaseAnonKey != 'YOUR_ANON_KEY_HERE';
}

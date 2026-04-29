import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// REST API wrapper for Supabase.
/// Each method upserts (insert or update) a single row identified by `id`.
/// All data is stored as JSONB in the `data` column.
class ApiService {
  static ApiService? _i;
  static ApiService get instance => _i ??= ApiService._();
  ApiService._();

  final _client = http.Client();

  // ── Generic CRUD ──────────────────────────────────────────────────────────

  /// Upsert a single record. id is the primary key.
  Future<bool> upsert(String table, String id, Map<String, dynamic> data) async {
    if (!ApiConfig.isConfigured) return false;
    try {
      final resp = await _client.post(
        Uri.parse('${ApiConfig.table(table)}?on_conflict=id'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'id': id,
          'org_id': ApiConfig.orgId,
          'data': data,
        }),
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) { return false; }
  }

  /// Fetch all rows for this org from a table.
  Future<List<Map<String, dynamic>>?> fetchAll(String table) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final resp = await _client.get(
        Uri.parse('${ApiConfig.table(table)}?org_id=eq.${ApiConfig.orgId}&select=id,data,updated_at'),
        headers: ApiConfig.headers,
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final list = jsonDecode(resp.body) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) { return null; }
  }

  /// Delete a single record by id.
  Future<bool> delete(String table, String id) async {
    if (!ApiConfig.isConfigured) return false;
    try {
      final resp = await _client.delete(
        Uri.parse('${ApiConfig.table(table)}?id=eq.$id'),
        headers: ApiConfig.headers,
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) { return false; }
  }

  /// Upsert a record with a custom key (not id-based, e.g. tax_settings).
  Future<bool> upsertKeyed(String table, String key, Map<String, dynamic> data) async {
    return upsert(table, key, data);
  }

  /// Fetch a single record by id.
  Future<Map<String, dynamic>?> fetchOne(String table, String id) async {
    if (!ApiConfig.isConfigured) return null;
    try {
      final resp = await _client.get(
        Uri.parse('${ApiConfig.table(table)}?id=eq.$id&select=data'),
        headers: ApiConfig.headers,
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final list = jsonDecode(resp.body) as List;
      if (list.isEmpty) return null;
      return (list.first as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  /// Check if API is reachable.
  Future<bool> ping() async {
    if (!ApiConfig.isConfigured) return false;
    try {
      final resp = await _client.get(
        Uri.parse('${ApiConfig.supabaseUrl}/rest/v1/'),
        headers: ApiConfig.headers,
      ).timeout(const Duration(seconds: 5));
      return resp.statusCode < 500;
    } catch (_) { return false; }
  }
}

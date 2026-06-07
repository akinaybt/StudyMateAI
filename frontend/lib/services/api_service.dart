import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

class ApiService {
  const ApiService();

  Future<String> _accessToken() async {
    final auth = Supabase.instance.client.auth;
    try {
      final refreshed = await auth.refreshSession();
      final token = refreshed.session?.accessToken;

      if (token != null && token.isNotEmpty) {
        return token;
      }
    } catch (_) {
      // If refresh fails, fall back to the current session below.
    }

    final currentSession = auth.currentSession;
    final token = currentSession?.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('User is not logged in. Missing access token.');
    }

    return token;
  }

  Future<Map<String, String>> _jsonHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _accessToken();
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeJsonResponse(
      http.Response response,
      String action,
      ) {
    final body = response.body.trim();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$action failed (${response.statusCode}): ${body.isEmpty ? 'Empty response body' : body}',
      );
    }

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('$action failed: unexpected response format');
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String storagePath,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final headers = await _jsonHeaders();

      final response = await http.post(
        Uri.parse(ApiConfig.uploadEndpoint),
        headers: headers,
        body: jsonEncode({
          'storage_path': storagePath,
          'filename': fileName,
          'content_type': contentType,
        }),
      );

      return _decodeJsonResponse(response, 'Upload');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  Future<Map<String, dynamic>> getSummary(String documentId) async {
    try {
      final headers = await _jsonHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.summaryEndpoint}/$documentId'),
        headers: headers,
      );

      return _decodeJsonResponse(response, 'Summary');
    } catch (e) {
      throw Exception('Summary error: $e');
    }
  }

  Future<Map<String, dynamic>> getFlashcards(String documentId) async {
    try {
      final headers = await _jsonHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.flashcardsEndpoint}/$documentId'),
        headers: headers,
      );

      return _decodeJsonResponse(response, 'Flashcards');
    } catch (e) {
      throw Exception('Flashcards error: $e');
    }
  }
}
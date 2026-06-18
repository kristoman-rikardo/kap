import 'package:dio/dio.dart';

/// Thin HTTP client for the KAP backend.
///
/// CP 0.4: just enough to prove the app reaches the API end-to-end. The full
/// client (Supabase JWT interceptor, typed errors, the `/v1/*` endpoints) is
/// built later per 05 §5.
class ApiClient {
  ApiClient({Dio? dio, String baseUrl = defaultBaseUrl})
    : _dio = (dio ?? Dio())..options.baseUrl = baseUrl;

  /// Dev default. The iOS simulator and the macOS desktop build both reach the
  /// host machine at `127.0.0.1`. An Android emulator would use `10.0.2.2`, and
  /// a physical device would need the Mac's LAN IP — handled when we get there.
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  final Dio _dio;

  /// Calls `GET /health` and returns the `status` field (e.g. "ok").
  Future<String> health() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return response.data?['status'] as String? ?? 'unknown';
  }
}

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_batch.dart';
import '../models/decision.dart';
import '../models/me_stats.dart';
import '../models/reveal.dart';

/// Thin HTTP client for the KAP backend.
///
/// CP 2.2: every request carries the Supabase JWT (05 §3); a 401 triggers one
/// silent re-auth + retry before surfacing the error. Typed errors and the
/// remaining `/v1/*` endpoints arrive with later checkpoints (05 §5).
class ApiClient {
  ApiClient({Dio? dio, String baseUrl = defaultBaseUrl, this.tokenProvider})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _token();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Utløpt/ugyldig sesjon: forny én gang og prøv kallet på nytt.
          if (error.response?.statusCode == 401 && tokenProvider == null) {
            try {
              await _reauthenticate();
              handler.resolve(await _dio.fetch(error.requestOptions));
              return;
            } catch (_) {/* fall gjennom til feilen */}
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Test seam: overrides the Supabase session lookup.
  final Future<String?> Function()? tokenProvider;

  Future<String?> _token() async {
    if (tokenProvider != null) return tokenProvider!();
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null; // Supabase ikke initialisert (tester) -> uautentisert
    }
  }

  Future<void> _reauthenticate() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) {
      await auth.refreshSession();
    } else {
      await auth.signInAnonymously();
    }
  }

  /// Dev default. The iOS simulator and the macOS desktop build both reach the
  /// host machine at `127.0.0.1`. An Android emulator would use `10.0.2.2`, and
  /// a physical device would need the Mac's LAN IP — handled when we get there.
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  final Dio _dio;

  /// The base URL all requests resolve against (exposed for sanity tests).
  String get baseUrl => _dio.options.baseUrl;

  /// Calls `GET /health` and returns the `status` field (e.g. "ok").
  Future<String> health() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return response.data?['status'] as String? ?? 'unknown';
  }

  /// Fetches today's anonymized daily round (05 §4.1).
  Future<DailyBatch> getDaily() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/daily');
    return DailyBatch.fromJson(response.data!);
  }

  /// Fetches streak, history and today's played-state (05 §4.5).
  Future<MeStats> getStats() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/me/stats');
    return MeStats.fromJson(response.data!);
  }

  /// Submits the round's choices and returns the reveal — the only way the
  /// client ever obtains names/tickers/alpha (05 §4.3, §5).
  Future<Reveal> submitBatch(int batchId, List<Decision> decisions) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/batches/$batchId/submit',
      data: {'choices': [for (final d in decisions) d.toJson()]},
    );
    return Reveal.fromJson(response.data!);
  }
}

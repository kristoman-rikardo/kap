import 'package:dio/dio.dart';

import '../models/daily_batch.dart';
import '../models/decision.dart';
import '../models/reveal.dart';

/// Thin HTTP client for the KAP backend.
///
/// CP 0.4: just enough to prove the app reaches the API end-to-end. The full
/// client (Supabase JWT interceptor, typed errors, the `/v1/*` endpoints) is
/// built later per 05 §5.
class ApiClient {
  ApiClient({Dio? dio, String baseUrl = defaultBaseUrl})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

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

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  static DateTime? _lastConnectivityCheck;
  static bool? _lastConnectivityResult;

  static Future<bool> hasInternetConnection({bool useCache = true}) async {
    // Cache connectivity check for 10 seconds to avoid repeated checks
    final now = DateTime.now();
    if (useCache) {
      if (_lastConnectivityCheck != null &&
          now.difference(_lastConnectivityCheck!).inSeconds < 10 &&
          _lastConnectivityResult != null) {
        return _lastConnectivityResult!;
      }
    }

    try {
      // Quick connectivity check using DNS resolution (faster than HTTP request)
      final result = await InternetAddress.lookup('google.com');
      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      _lastConnectivityCheck = now;
      _lastConnectivityResult = hasConnection;
      return hasConnection;
    } catch (e) {
      _lastConnectivityCheck = now;
      _lastConnectivityResult = false;
      return false;
    }
  }

  static Future<http.Response> makeRequest(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    int? maxRetries,
  }) async {
    final requestTimeout = timeout ?? _defaultTimeout;
    final retryCount = maxRetries ?? _maxRetries;

    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        late http.Response response;
        final uri = Uri.parse(url);

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(uri, headers: headers)
                .timeout(requestTimeout);
            break;
          case 'POST':
            response = await http
                .post(uri, headers: headers, body: body)
                .timeout(requestTimeout);
            break;
          case 'PUT':
            response = await http
                .put(uri, headers: headers, body: body)
                .timeout(requestTimeout);
            break;
          case 'DELETE':
            response = await http
                .delete(uri, headers: headers)
                .timeout(requestTimeout);
            break;
          default:
            throw UnsupportedError('HTTP method $method is not supported');
        }

        return response;
      } on SocketException catch (e) {
        if (attempt == retryCount) {
          // Only check connectivity on final failure to avoid overhead
          final hasConnection = await hasInternetConnection();
          if (!hasConnection) {
            throw SocketException('No internet connection: ${e.message}');
          }
          rethrow;
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 << attempt));
      } on TimeoutException {
        if (attempt == retryCount) {
          rethrow;
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 << attempt));
      } catch (e) {
        // For non-retryable errors, throw immediately
        rethrow;
      }
    }

    throw Exception('Request failed after $retryCount retries');
  }

  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    } else if (error is TimeoutException) {
      return 'Connection timed out. The server is taking too long to respond. Please try again.';
    } else if (error is HttpException) {
      return 'HTTP error occurred: ${error.message}';
    } else if (error is FormatException) {
      return 'Invalid response format from server.';
    } else {
      return 'Network error occurred: ${error.toString()}';
    }
  }
}

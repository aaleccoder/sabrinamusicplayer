import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MetadataService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.flutter_application_1/metadata',
  );

  // Cache for recently processed files to avoid re-extraction
  static final Map<String, Map<String, String?>> _cache = {};
  static const int _maxCacheSize = 100;

  Future<Map<String, String?>> getMetadata(String filePath) async {
    // Check cache first
    if (_cache.containsKey(filePath)) {
      return _cache[filePath]!;
    }

    try {
      final Map<dynamic, dynamic>? metadata = await _channel
          .invokeMethod('getMetadata', {'filePath': filePath})
          .timeout(
            const Duration(seconds: 10), // Add timeout to prevent hanging
            onTimeout: () {
              debugPrint('Metadata extraction timeout for: $filePath');
              return <String, dynamic>{};
            },
          );

      final result = metadata?.cast<String, String?>() ?? {};

      // Cache the result (with size limit)
      if (result.isNotEmpty) {
        _addToCache(filePath, result);
      }

      return result;
    } on PlatformException catch (e) {
      // Handle platform-side errors with more detailed logging
      debugPrint(
        "PlatformException getting metadata for $filePath: ${e.message} (${e.code})",
      );
      return {};
    } on TimeoutException catch (e) {
      debugPrint("Timeout getting metadata for $filePath: $e");
      return {};
    } catch (e) {
      debugPrint("Unexpected error getting metadata for $filePath: $e");
      return {};
    }
  }

  static void _addToCache(String filePath, Map<String, String?> metadata) {
    // Manage cache size to prevent memory issues
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entries (simple FIFO)
      final keysToRemove = _cache.keys.take(_maxCacheSize ~/ 2).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
    _cache[filePath] = metadata;
  }

  static void clearCache() {
    _cache.clear();
  }

  static int get cacheSize => _cache.length;
}

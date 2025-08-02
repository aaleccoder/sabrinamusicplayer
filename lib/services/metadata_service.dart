import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MetadataService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.flutter_application_1/metadata',
  );

  Future<List<Map<String, String?>>> getAllMusicFiles() async {
    try {
      final List<dynamic>? musicFiles = await _channel
          .invokeMethod('getAllMusicFiles')
          .timeout(const Duration(seconds: 60));

      if (musicFiles == null) {
        return [];
      }

      return musicFiles.map((dynamic file) {
        return (file as Map<dynamic, dynamic>).cast<String, String?>();
      }).toList();
    } on PlatformException catch (e) {
      // Provide more detailed error logging for platform-specific issues
      debugPrint(
        "PlatformException getting music files: ${e.message} (${e.code})",
      );
      return [];
    } on TimeoutException {
      // Handle timeouts gracefully
      debugPrint("Timeout getting music files from MediaStore.");
      return [];
    } catch (e) {
      // Catch any other unexpected errors
      debugPrint("Unexpected error getting music files: $e");
      return [];
    }
  }

  /// Gets full-size album art for a specific track
  /// Returns the URI to the cached full-size album art image
  Future<String?> getFullSizeAlbumArt(String trackId) async {
    try {
      final String? albumArtUri = await _channel
          .invokeMethod('extractFullSizeAlbumArt', {'trackId': trackId})
          .timeout(const Duration(seconds: 30));

      return albumArtUri;
    } on PlatformException catch (e) {
      debugPrint(
        "PlatformException getting full-size album art: ${e.message} (${e.code})",
      );
      return null;
    } on TimeoutException {
      debugPrint("Timeout getting full-size album art.");
      return null;
    } catch (e) {
      debugPrint("Unexpected error getting full-size album art: $e");
      return null;
    }
  }

  Future<String?> getPathFromUri(String uri) async {
    try {
      final String? path = await _channel.invokeMethod('getPathFromUri', {
        'uri': uri,
      });
      return path;
    } on PlatformException catch (e) {
      debugPrint("Failed to get path from URI: '${e.message}'.");
      return null;
    }
  }
}

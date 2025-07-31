import 'package:flutter/services.dart';

class MetadataService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.flutter_application_1/metadata',
  );

  Future<Map<String, String?>> getMetadata(String filePath) async {
    try {
      final Map<dynamic, dynamic>? metadata = await _channel.invokeMethod(
        'getMetadata',
        {'filePath': filePath},
      );
      return metadata?.cast<String, String?>() ?? {};
    } on PlatformException catch (e) {
      // Handle platform-side errors
      print("Error getting metadata: ${e.message}");
      return {};
    }
  }
}

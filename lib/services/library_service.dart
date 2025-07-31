import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/services/metadata_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryService {
  final audioExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'];
  void getFileUrl(ProviderContainer ref) async {
    final database = ref.read(appDatabaseProvider);

    final paths = await database.select(database.musicDirectories).get();
    final directory = Directory(paths[0].path);
    var files = <FileSystemEntity>[];
    if (await directory.exists()) {
      files = directory.listSync(recursive: true).whereType<File>().toList();
    }
    final audioFiles = files.where((file) {
      return audioExtensions.contains(file.path.split('.').last.toLowerCase());
    }).toList();

    for (var file in audioFiles) {
      final metadata = await MetadataService().getMetadata(file.path);
      Uint8List cover = Uint8List(0);

      if (metadata.containsKey("album_art")) {
        cover = await base64Decode(metadata['album_art']!);
      }

      ;
    }
  }
}

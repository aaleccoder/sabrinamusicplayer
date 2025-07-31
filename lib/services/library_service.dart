import 'dart:io';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryService {
  void getFileUrl(ProviderContainer ref) async {
    final database = ref.read(appDatabaseProvider);

    final paths = await database.select(database.musicDirectories).get();
    final directory = Directory(paths[0].path);
    if (await directory.exists()) {
      final files = directory.listSync(recursive: true);
      print(files);
    }
  }
}

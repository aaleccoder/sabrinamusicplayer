import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/services/metadata_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LibraryService {
  final Set<String> audioExtensions = {
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.m4a',
  };

  Future<void> scanIfChange(ProviderContainer ref) async {
    final prefs = await SharedPreferences.getInstance();
    final lastScanTimestamp = prefs.getInt('lastScanTimestamp') ?? 0;

    final database = ref.read(appDatabaseProvider);
    final paths = await database.select(database.musicDirectories).get();
    bool needsScan = false;

    if (paths.isEmpty) {
      debugPrint('No music directories found. Skipping scan.');
      return;
    }

    for (var directory in paths) {
      final dir = Directory(directory.path);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.millisecondsSinceEpoch > lastScanTimestamp) {
            needsScan = true;
            break;
          }
        }
      }
      if (needsScan) break;
    }
    if (needsScan) {
      debugPrint('Changes detected. Scanning library...');
      await scanLibrary(ref);
    } else {
      debugPrint('No changes detected. Skipping scan.');
    }
  }

  Future<void> scanLibrary(ProviderContainer ref) async {
    try {
      final database = ref.read(appDatabaseProvider);

      final paths = await database.select(database.musicDirectories).get();
      for (var directory in paths) {
        final dir = Directory(directory.path);
        var files = <FileSystemEntity>[];
        if (await dir.exists()) {
          files = await dir.list(recursive: true).toList();
        }
        final audioFiles = files.where((file) {
          return audioExtensions.contains(p.extension(file.path).toLowerCase());
        }).toList();

        for (var file in audioFiles) {
          try {
            final metadata = await MetadataService().getMetadata(file.path);
            int coverId = -1;

            if (metadata.containsKey("album_art")) {
              coverId = await createOrLinkToCover(
                database,
                base64Decode(metadata['album_art']!),
              );
            }
            final genreId = await createOrLinkToGenre(
              database,
              metadata['genre'] ?? 'Unknown',
            );
            final artistId = await createOrLinkToArtist(
              database,
              metadata['artist'] ?? 'Unknown',
            );
            final albumId = await createOrLinkAlbumId(
              database,
              artistId,
              metadata['album'] ?? 'Unknown',
              genreId,
              coverId: coverId != -1 ? coverId : null,
            );

            await database
                .into(database.tracks)
                .insert(
                  TracksCompanion.insert(
                    title: metadata['title'] ?? 'Unknown',
                    fileuri: file.path,
                    coverId: coverId != -1
                        ? Value(coverId)
                        : const Value.absent(),
                    trackNumber: Value(metadata['track_number'] as int?),
                    year: Value(metadata['year'] as int?),
                    albumId: Value(albumId),
                    artistId: Value(artistId),
                    genreId: Value(genreId),
                  ),
                );
          } catch (e, s) {
            debugPrint('Failed to process file: ${file.path}');
            debugPrint('Error: $e');
            debugPrint('Stack trace: $s');
          }
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'lastScanTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('Library scan completed successfully.');
    } catch (e, s) {
      debugPrint('A critical error occurred during library scan: $e');
      debugPrint('Stack trace: $s');
    }
  }

  String _generateBytesHash(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  Future<String> _creatCoverPath(Uint8List cover) async {
    final directory = await getApplicationDocumentsDirectory();

    final filePath = p.join(directory.path, '${Uuid().v4()}.jpg');
    final file = File(filePath);
    await file.writeAsBytes(cover);
    return filePath;
  }

  Future<int> createOrLinkToCover(AppDatabase database, Uint8List cover) async {
    final coverHash = await compute(_generateBytesHash, cover);
    final existingCover = await (database.select(
      database.cover,
    )..where((c) => c.hash.equals(coverHash))).get();
    if (existingCover.isNotEmpty) {
      return existingCover.first.id;
    } else {
      final coverPath = await _creatCoverPath(cover);
      return await database
          .into(database.cover)
          .insert(
            CoverCompanion.insert(cover: Value(coverPath), hash: coverHash),
          );
    }
  }

  Future<int> createOrLinkToGenre(
    AppDatabase database,
    String genreName,
  ) async {
    final existingGenre = await (database.select(
      database.genres,
    )..where((g) => g.name.equals(genreName))).get();
    if (existingGenre.isNotEmpty) {
      return existingGenre.first.id;
    } else {
      return await database
          .into(database.genres)
          .insert(GenresCompanion.insert(name: genreName));
    }
  }

  Future<int> createOrLinkToArtist(
    AppDatabase database,
    String artistName,
  ) async {
    final existingArtist = await (database.select(
      database.artists,
    )..where((a) => a.name.equals(artistName))).get();
    if (existingArtist.isNotEmpty) {
      return existingArtist.first.id;
    } else {
      return await database
          .into(database.artists)
          .insert(ArtistsCompanion.insert(name: artistName));
    }
  }

  Future<int> createOrLinkAlbumId(
    AppDatabase database,
    int artistId,
    String albumName,
    int genredId, {
    int? coverId,
  }) async {
    final existingAlbum = await (database.select(
      database.albums,
    )..where((a) => a.name.equals(albumName))).get();
    if (existingAlbum.isNotEmpty) {
      if (existingAlbum.first.coverId == null) {
        await (database.update(
          database.albums,
        )..where((a) => a.id.equals(existingAlbum.first.id))).write(
          AlbumsCompanion(
            coverId: coverId != null ? Value(coverId) : const Value.absent(),
          ),
        );
      }
      return existingAlbum.first.id;
    } else {
      return await database
          .into(database.albums)
          .insert(
            AlbumsCompanion.insert(
              name: albumName,
              artistId: Value(artistId),
              genreId: Value(genredId),
              coverId: coverId != null ? Value(coverId) : const Value(null),
            ),
          );
    }
  }
}

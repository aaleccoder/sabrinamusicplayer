import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/providers/library_scanning_provider.dart';
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
    final progressNotifier = ref.read(libraryScanningProvider.notifier);

    try {
      final database = ref.read(appDatabaseProvider);
      final musicDirs = await database.select(database.musicDirectories).get();

      if (musicDirs.isEmpty) {
        debugPrint('No music directories configured for scanning.');
        return;
      }

      // First pass: count all audio files
      final allAudioFiles = <File>[];
      for (var directory in musicDirs) {
        final dir = Directory(directory.path);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File &&
                audioExtensions.contains(
                  p.extension(entity.path).toLowerCase(),
                )) {
              allAudioFiles.add(entity);
            }
          }
        }
      }

      final existingTracks = await database.select(database.tracks).get();
      final existingFilePaths = existingTracks.map((t) => t.fileuri).toSet();
      final newAudioFiles = allAudioFiles
          .where((f) => !existingFilePaths.contains(f.path))
          .toList();

      // Start scanning progress
      progressNotifier.startScanning(totalFiles: newAudioFiles.length);
      debugPrint('Found ${newAudioFiles.length} new files to process.');

      if (newAudioFiles.isEmpty) {
        debugPrint('No new audio files to process.');
        // Show brief scanning message even when no new files
        progressNotifier.updateProgress(
          processedFiles: 0,
          currentFile: 'Library up to date',
        );
        await Future.delayed(
          const Duration(milliseconds: 1500),
        ); // Show for 1.5 seconds
        progressNotifier.finishScanning();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'lastScanTimestamp',
          DateTime.now().millisecondsSinceEpoch,
        );
        return;
      }

      // Process and add to database every 100 songs to avoid memory issues
      const batchSize =
          8; // Process 8 files simultaneously for optimal performance
      const dbCommitSize = 100; // Commit to database every 100 songs
      final metadataService = MetadataService();

      // Global maps to track all processed items across batches
      final globalArtistIdMap = <String, int>{};
      final globalGenreIdMap = <String, int>{};
      final globalCoverIdMap = <String, int>{};
      final globalAlbumIdMap = <String, int>{};

      for (int i = 0; i < newAudioFiles.length; i += dbCommitSize) {
        final dbBatchEnd = (i + dbCommitSize).clamp(0, newAudioFiles.length);
        final dbBatch = newAudioFiles.sublist(i, dbBatchEnd);

        debugPrint(
          'Processing database batch ${(i ~/ dbCommitSize) + 1}: ${dbBatch.length} files',
        );

        // Local collections for this database batch
        final metadataCache = <String, Map<String, dynamic>>{};
        final artistNames = <String>{};
        final genreNames = <String>{};
        final albumArtistMap = <String, String>{};
        final coverArtMap = <String, Uint8List>{};

        // Process metadata in smaller parallel batches within this database batch
        for (int j = 0; j < dbBatch.length; j += batchSize) {
          final batchEnd = (j + batchSize).clamp(0, dbBatch.length);
          final batch = dbBatch.sublist(j, batchEnd);
          final globalOffset = i + j;

          progressNotifier.updateProgress(
            processedFiles: globalOffset,
            currentFile:
                'Processing batch ${(globalOffset ~/ batchSize) + 1}...',
          );

          // Process batch in parallel
          final futures = batch.asMap().entries.map((entry) async {
            final index = entry.key;
            final file = entry.value;
            final globalIndex = globalOffset + index;

            try {
              final stopwatch = Stopwatch()..start();
              final metadata = await metadataService.getMetadata(file.path);
              final elapsed = stopwatch.elapsedMilliseconds;

              debugPrint(
                'Processed file ${globalIndex + 1}/${newAudioFiles.length}: ${p.basename(file.path)} (${elapsed}ms)',
              );

              return {'file': file, 'metadata': metadata, 'index': globalIndex};
            } catch (e, s) {
              debugPrint(
                'Failed to get metadata for file: ${file.path}, Error: $e',
              );
              return {
                'file': file,
                'metadata': <String, String?>{},
                'index': globalIndex,
              };
            }
          }).toList();

          // Wait for batch to complete
          final results = await Future.wait(futures, eagerError: false);

          // Process results
          for (final result in results) {
            final file = result['file'] as File;
            final metadata = result['metadata'] as Map<String, String?>;
            final index = result['index'] as int;

            if (metadata.isEmpty) continue;

            metadataCache[file.path] = metadata;

            final artist = metadata['artist'] ?? 'Unknown Artist';
            final album = metadata['album'] ?? 'Unknown Album';

            artistNames.add(artist);
            genreNames.add(metadata['genre'] ?? 'Unknown Genre');
            albumArtistMap.putIfAbsent(album, () => artist);

            // Process album art efficiently
            if (metadata.containsKey('album_art') &&
                metadata['album_art']!.isNotEmpty) {
              try {
                final imageBytes = base64Decode(metadata['album_art']!);
                if (imageBytes.isNotEmpty) {
                  final hash = await compute(_generateBytesHash, imageBytes);
                  coverArtMap.putIfAbsent(hash, () => imageBytes);
                }
              } catch (e) {
                debugPrint('Failed to process album art for ${file.path}: $e');
              }
            }

            // Update progress
            progressNotifier.updateProgress(
              processedFiles: index + 1,
              currentFile: p.basename(file.path),
            );
          }
        }

        // Process database operations for this batch
        progressNotifier.updateProgress(
          processedFiles: i + dbBatch.length,
          currentFile: 'Saving batch to database...',
        );

        // Process artists, genres, and covers for this batch
        final batchArtistIdMap = await _batchProcessArtists(
          database,
          artistNames,
        );
        final batchGenreIdMap = await _batchProcessGenres(database, genreNames);
        final batchCoverIdMap = await _batchProcessCovers(
          database,
          coverArtMap,
        );

        // Merge with global maps to avoid duplicates
        globalArtistIdMap.addAll(batchArtistIdMap);
        globalGenreIdMap.addAll(batchGenreIdMap);
        globalCoverIdMap.addAll(batchCoverIdMap);

        final batchAlbumIdMap = await _batchProcessAlbums(
          database,
          albumArtistMap,
          globalArtistIdMap,
          globalGenreIdMap,
          globalCoverIdMap,
          metadataCache,
        );

        // Merge album IDs
        globalAlbumIdMap.addAll(batchAlbumIdMap);

        // Create and insert tracks for this batch
        final trackCompanions = <TracksCompanion>[];
        for (final file in dbBatch) {
          final metadata = metadataCache[file.path];
          if (metadata == null) continue;

          final artistName = metadata['artist'] ?? 'Unknown Artist';
          final albumName = metadata['album'] ?? 'Unknown Album';
          final genreName = metadata['genre'] ?? 'Unknown Genre';
          final albumKey = '$albumName|${albumArtistMap[albumName]}';

          int? coverId;
          if (metadata.containsKey('album_art')) {
            final imageBytes = base64Decode(metadata['album_art']!);
            if (imageBytes.isNotEmpty) {
              final hash = await compute(_generateBytesHash, imageBytes);
              coverId = globalCoverIdMap[hash];
            }
          }

          trackCompanions.add(
            TracksCompanion.insert(
              title: metadata['title'] ?? p.basenameWithoutExtension(file.path),
              fileuri: file.path,
              coverId: coverId != null ? Value(coverId) : const Value.absent(),
              trackNumber: Value(metadata['track_number']),
              year: Value(metadata['year']),
              albumId: Value(globalAlbumIdMap[albumKey]),
              artistId: Value(globalArtistIdMap[artistName]),
              genreId: Value(globalGenreIdMap[genreName]),
            ),
          );
        }

        // Insert tracks for this batch
        if (trackCompanions.isNotEmpty) {
          await database.batch((batch) {
            batch.insertAll(database.tracks, trackCompanions);
          });
          debugPrint(
            'Added ${trackCompanions.length} tracks to database (batch ${(i ~/ dbCommitSize) + 1})',
          );
        }

        // Clear memory for this batch
        metadataCache.clear();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'lastScanTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint(
        'Library scan completed. Processed ${newAudioFiles.length} new files.',
      );

      // Finish scanning
      progressNotifier.finishScanning();
    } catch (e, s) {
      debugPrint('A critical error occurred during library scan: $e');
      debugPrint('Stack trace: $s');
      progressNotifier.setError('Scan failed: $e');
    }
  }

  String _generateBytesHash(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  Future<String> _createCoverPath(Uint8List cover) async {
    final directory = await getApplicationDocumentsDirectory();

    final filePath = p.join(directory.path, '${const Uuid().v4()}.jpg');
    final file = File(filePath);
    await file.writeAsBytes(cover);
    return filePath;
  }

  Future<Map<String, int>> _batchProcessCovers(
    AppDatabase database,
    Map<String, Uint8List> coverArtMap,
  ) async {
    if (coverArtMap.isEmpty) return {};

    final existing = await (database.select(
      database.cover,
    )..where((c) => c.hash.isIn(coverArtMap.keys))).get();

    final idMap = {for (var e in existing) e.hash: e.id};

    final newHashes = coverArtMap.keys.where(
      (hash) => !idMap.containsKey(hash),
    );

    if (newHashes.isNotEmpty) {
      final companions = <CoverCompanion>[];
      for (final hash in newHashes) {
        final path = await _createCoverPath(coverArtMap[hash]!);
        companions.add(CoverCompanion.insert(cover: Value(path), hash: hash));
      }

      await database.batch(
        (batch) => batch.insertAll(database.cover, companions),
      );

      final inserted = await (database.select(
        database.cover,
      )..where((c) => c.hash.isIn(newHashes))).get();

      for (var e in inserted) {
        idMap[e.hash] = e.id;
      }
    }

    return idMap;
  }

  Future<Map<String, int>> _batchProcessGenres(
    AppDatabase database,
    Set<String> genreNames,
  ) async {
    if (genreNames.isEmpty) return {};
    final existing = await (database.select(
      database.genres,
    )..where((g) => g.name.isIn(genreNames))).get();
    final idMap = {for (var e in existing) e.name: e.id};

    final newNames = genreNames
        .where((name) => !idMap.containsKey(name))
        .toList();
    if (newNames.isNotEmpty) {
      final companions = newNames
          .map((name) => GenresCompanion.insert(name: name))
          .toList();
      await database.batch(
        (batch) => batch.insertAll(database.genres, companions),
      );

      final inserted = await (database.select(
        database.genres,
      )..where((a) => a.name.isIn(newNames))).get();
      for (var e in inserted) {
        idMap[e.name] = e.id;
      }
    }
    return idMap;
  }

  Future<Map<String, int>> _batchProcessArtists(
    AppDatabase database,
    Set<String> artistNames,
  ) async {
    if (artistNames.isEmpty) return {};
    final existing = await (database.select(
      database.artists,
    )..where((a) => a.name.isIn(artistNames))).get();
    final idMap = {for (var e in existing) e.name: e.id};

    final newNames = artistNames
        .where((name) => !idMap.containsKey(name))
        .toList();
    if (newNames.isNotEmpty) {
      final companions = newNames
          .map((name) => ArtistsCompanion.insert(name: name))
          .toList();
      await database.batch(
        (batch) => batch.insertAll(database.artists, companions),
      );

      final inserted = await (database.select(
        database.artists,
      )..where((a) => a.name.isIn(newNames))).get();
      for (var e in inserted) {
        idMap[e.name] = e.id;
      }
    }
    return idMap;
  }

  Future<Map<String, int>> _batchProcessAlbums(
    AppDatabase db,
    Map<String, String> albumArtistMap,
    Map<String, int> artistIdMap,
    Map<String, int> genreIdMap,
    Map<String, int> coverIdMap,
    Map<String, Map<String, dynamic>> metadataCache,
  ) async {
    final existingAlbums = await db.select(db.albums).join([
      innerJoin(db.artists, db.artists.id.equalsExp(db.albums.artistId)),
    ]).get();

    final idMap = <String, int>{};
    for (final row in existingAlbums) {
      final album = row.readTable(db.albums);
      final artist = row.readTable(db.artists);
      idMap['${album.name}|${artist.name}'] = album.id;
    }

    final newAlbumCompanions = <AlbumsCompanion>[];
    final newAlbumKeys = <String>{};

    for (final entry in albumArtistMap.entries) {
      final albumName = entry.key;
      final artistName = entry.value;
      final uniqueKey = '$albumName|$artistName';

      if (!idMap.containsKey(uniqueKey)) {
        final metadata = metadataCache.values.firstWhere(
          (m) =>
              (m['album'] ?? 'Unknown Album') == albumName &&
              (m['artist'] ?? 'Unknown Artist') == artistName,
          orElse: () => {},
        );
        if (metadata.isEmpty) continue;

        final genreName = metadata['genre'] ?? 'Unknown Genre';
        int? coverId;
        if (metadata.containsKey('album_art')) {
          final imageBytes = base64Decode(metadata['album_art']!);
          if (imageBytes.isNotEmpty) {
            final hash = await compute(_generateBytesHash, imageBytes);
            coverId = coverIdMap[hash];
          }
        }

        newAlbumCompanions.add(
          AlbumsCompanion.insert(
            name: albumName,
            artistId: Value(artistIdMap[artistName]),
            genreId: Value(genreIdMap[genreName]),
            coverId: coverId != null ? Value(coverId) : const Value.absent(),
          ),
        );
        newAlbumKeys.add(uniqueKey);
      }
    }

    if (newAlbumCompanions.isNotEmpty) {
      await db.batch((batch) => batch.insertAll(db.albums, newAlbumCompanions));

      final inserted = await db.select(db.albums).join([
        innerJoin(db.artists, db.artists.id.equalsExp(db.albums.artistId)),
      ]).get();

      for (final row in inserted) {
        final album = row.readTable(db.albums);
        final artist = row.readTable(db.artists);
        final key = '${album.name}|${artist.name}';
        if (newAlbumKeys.contains(key)) {
          idMap[key] = album.id;
        }
      }
    }
    return idMap;
  }
}

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  Future<void> scanLibrary(WidgetRef ref) async {
    final progressNotifier = ref.read(libraryScanningProvider.notifier);
    final database = ref.read(appDatabaseProvider);
    final metadataService = MetadataService();

    try {
      progressNotifier.startScanning(totalFiles: 0);
      progressNotifier.updateProgress(
        processedFiles: 0,
        currentFile: 'Fetching music from your device...',
      );

      // Fetch all music files from the MediaStore
      final allMusicFiles = await metadataService.getAllMusicFiles();
      final allDeviceFilePaths = allMusicFiles
          .map((f) => f['path'] as String)
          .toSet();

      // Get excluded directories
      final excludedDirs = await database
          .select(database.excludedDirectories)
          .get();
      final excludedPaths = excludedDirs.map((d) => d.path).toSet();

      // Get existing tracks from the database
      final existingTracks = await database.select(database.tracks).get();
      final tracksToDelete = <int>{};

      // Find tracks to delete (orphaned or in excluded folders)
      for (final track in existingTracks) {
        final trackPath = await metadataService.getPathFromUri(track.fileuri);
        bool isInExcluded =
            trackPath != null &&
            excludedPaths.any((p) => trackPath.startsWith(p));
        if (isInExcluded || !allDeviceFilePaths.contains(track.fileuri)) {
          tracksToDelete.add(track.id);
        }
      }

      // Perform deletion if needed
      if (tracksToDelete.isNotEmpty) {
        await (database.delete(
          database.tracks,
        )..where((t) => t.id.isIn(tracksToDelete))).go();
        debugPrint(
          'Deleted ${tracksToDelete.length} orphaned or excluded tracks.',
        );
        await database.cleanupOrphanedMetadata();
        // Invalidate providers to reflect deletions immediately
        ref.invalidate(tracksProvider);
        ref.invalidate(albumsProvider);
        ref.invalidate(artistsProvider);
        ref.invalidate(genresProvider);
      }

      if (allMusicFiles.isEmpty) {
        debugPrint('No music files found on the device.');
        progressNotifier.finishScanning();
        return;
      }

      progressNotifier.startScanning(totalFiles: allMusicFiles.length);
      debugPrint('Found ${allMusicFiles.length} music files.');

      // Re-fetch existing tracks to get a clean state for processing new files
      final currentTracks = await database.select(database.tracks).get();
      final currentFilePaths = currentTracks.map((t) => t.fileuri).toSet();

      // Filter out already existing files and files in excluded directories
      final newFilesToProcess = allMusicFiles.where((f) {
        final path = f['path'] as String;
        if (currentFilePaths.contains(path)) {
          return false;
        }
        if (excludedPaths.any((p) => path.startsWith(p))) {
          return false;
        }
        return true;
      }).toList();

      if (newFilesToProcess.isEmpty) {
        debugPrint('No new music files to process.');
        progressNotifier.finishScanning();
        return;
      }

      debugPrint('Processing ${newFilesToProcess.length} new music files.');

      // Process files in batches to avoid overwhelming the database
      const dbCommitSize = 100;
      for (int i = 0; i < newFilesToProcess.length; i += dbCommitSize) {
        final batchEnd = (i + dbCommitSize).clamp(0, newFilesToProcess.length);
        final batch = newFilesToProcess.sublist(i, batchEnd);

        progressNotifier.updateProgress(
          processedFiles: i,
          currentFile: 'Processing batch ${i ~/ dbCommitSize + 1}...',
        );

        // Prepare data for batch insertion
        final artistNames = <String>{};
        final genreNames = <String>{};
        final albumArtistMap = <String, String>{};
        final albumArtUriMap = <String, String>{};

        for (final metadata in batch) {
          final artist = metadata['artist'] ?? 'Unknown Artist';
          final album = metadata['album'] ?? 'Unknown Album';
          final genre = metadata['genre'] ?? 'Unknown Genre';

          artistNames.add(artist);
          genreNames.add(genre);
          albumArtistMap.putIfAbsent(album, () => artist);

          // Store album art URI for later use
          if (metadata.containsKey('album_art_uri') &&
              metadata['album_art_uri'] != null) {
            final albumKey = '$album|$artist';
            albumArtUriMap.putIfAbsent(
              albumKey,
              () => metadata['album_art_uri']!,
            );
          }
        }

        // Batch process artists and genres
        final artistIdMap = await _batchProcessArtists(database, artistNames);
        final genreIdMap = await _batchProcessGenres(database, genreNames);

        // Batch process albums with URI-based cover handling
        final albumIdMap = await _batchProcessAlbums(
          database,
          albumArtistMap,
          artistIdMap,
          genreIdMap,
          albumArtUriMap,
          {for (var m in batch) m['path']!: m},
        );

        // Prepare tracks for insertion
        final trackCompanions = <TracksCompanion>[];
        for (int j = 0; j < batch.length; j++) {
          final metadata = batch[j];
          final filePath = metadata['path'];
          if (filePath == null) continue;

          final artistName = metadata['artist'] ?? 'Unknown Artist';
          final albumName = metadata['album'] ?? 'Unknown Album';
          final genreName = metadata['genre'] ?? 'Unknown Genre';
          final albumKey = '$albumName|$artistName';

          // Store the album art URI directly in the cover path
          final albumArtUri = metadata['album_art_uri'];

          trackCompanions.add(
            TracksCompanion.insert(
              title: metadata['title'] ?? p.basenameWithoutExtension(filePath),
              fileuri: filePath,
              trackNumber: Value(metadata['track_number']),
              year: Value(metadata['year']),
              albumId: Value(albumIdMap[albumKey]),
              artistId: Value(artistIdMap[artistName]),
              genreId: Value(genreIdMap[genreName]),
              coverImage: albumArtUri != null
                  ? Value(albumArtUri)
                  : const Value.absent(),
            ),
          );
          progressNotifier.updateProgress(
            processedFiles: i + j + 1,
            currentFile: p.basename(filePath),
          );
        }
        // Insert tracks in a batch
        if (trackCompanions.isNotEmpty) {
          await database.batch((batch) {
            batch.insertAll(database.tracks, trackCompanions);
          });
        }
      }

      debugPrint('Library scan completed successfully.');
      progressNotifier.finishScanning();
      ref.invalidate(tracksProvider);
      ref.invalidate(albumsProvider);
      ref.invalidate(artistsProvider);
      ref.invalidate(genresProvider);
    } catch (e, s) {
      debugPrint('A critical error occurred during library scan: $e');
      debugPrint('Stack trace: $s');
      progressNotifier.setError('Scan failed: $e');
    }
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
    Map<String, String> albumArtUriMap,
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

        final coverArtUri = albumArtUriMap[uniqueKey];

        newAlbumCompanions.add(
          AlbumsCompanion.insert(
            name: albumName,
            artistId: Value(artistIdMap[artistName]),
            genreId: Value(genreIdMap[genreName]),
            coverImage: coverArtUri != null
                ? Value(coverArtUri)
                : const Value.absent(),
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

  Future<void> addExcludedDirectoryAndRemoveTracks(
    WidgetRef ref,
    String path,
  ) async {
    final database = ref.read(appDatabaseProvider);
    final metadataService = MetadataService();

    // Add to excluded directories table
    await database
        .into(database.excludedDirectories)
        .insert(ExcludedDirectoriesCompanion.insert(path: path));

    // Get all tracks to find which ones to delete
    final allTracks = await database.select(database.tracks).get();
    final tracksToDelete = <int>[];

    for (final track in allTracks) {
      // We need to resolve the file path from the URI to compare with the excluded path
      final trackPath = await metadataService.getPathFromUri(track.fileuri);
      if (trackPath != null && trackPath.startsWith(path)) {
        tracksToDelete.add(track.id);
      }
    }

    if (tracksToDelete.isNotEmpty) {
      // Delete tracks from that directory
      await (database.delete(
        database.tracks,
      )..where((t) => t.id.isIn(tracksToDelete))).go();

      // Clean up orphaned metadata
      await database.cleanupOrphanedMetadata();

      // Invalidate providers to refresh UI
      ref.invalidate(tracksProvider);
      ref.invalidate(albumsProvider);
      ref.invalidate(artistsProvider);
      ref.invalidate(genresProvider);
    }
  }
}

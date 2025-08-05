import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/providers/library_scanning_provider.dart';
import 'package:flutter_application_1/services/metadata_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

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

      final allMusicFiles = await metadataService.getAllMusicFiles();
      final allDeviceFilePaths = allMusicFiles
          .map((f) => f['path'] as String)
          .toSet();

      final excludedDirs = await database
          .select(database.excludedDirectories)
          .get();
      final excludedPaths = excludedDirs.map((d) => d.path).toSet();

      final allDbTracks = await database.select(database.tracks).get();
      final tracksToUnlink = <int>{};

      for (final track in allDbTracks) {
        final trackPath = track.fileuri != null
            ? await metadataService.getPathFromUri(track.fileuri!)
            : null;
        final isExcluded =
            trackPath != null &&
            excludedPaths.any((p) => trackPath.startsWith(p));
        final isOrphaned = !allDeviceFilePaths.contains(track.fileuri);

        if (isExcluded || isOrphaned) {
          tracksToUnlink.add(track.id);
        }
      }

      if (tracksToUnlink.isNotEmpty) {
        await (database.update(database.tracks)
              ..where((t) => t.id.isIn(tracksToUnlink)))
            .write(const TracksCompanion(fileuri: Value.absent()));
        debugPrint('Unlinked ${tracksToUnlink.length} tracks.');
        ref.invalidate(tracksProvider);
      }

      if (allMusicFiles.isEmpty) {
        debugPrint('No music files found on the device.');
        progressNotifier.finishScanning();
        return;
      }

      progressNotifier.startScanning(totalFiles: allMusicFiles.length);
      debugPrint('Found ${allMusicFiles.length} music files.');

      // Filter out excluded files first
      final filesToProcess = allMusicFiles
          .where((f) => !excludedPaths.any((p) => f['path']!.startsWith(p)))
          .toList();

      if (filesToProcess.isEmpty) {
        debugPrint('No new or linkable music files to process.');
        progressNotifier.finishScanning();
        return;
      }

      debugPrint('Processing ${filesToProcess.length} music files.');

      // Fetch all existing track and artist data for efficient lookup
      final allArtists = await database.select(database.artists).get();
      final artistIdToName = {for (var a in allArtists) a.id: a.name};

      final allTracks = await database.select(database.tracks).get();
      final trackLookup = {
        for (var t in allTracks)
          '${t.title.toLowerCase()}|${artistIdToName[t.artistId]?.toLowerCase()}':
              t,
      };

      const dbCommitSize = 100;
      for (int i = 0; i < filesToProcess.length; i += dbCommitSize) {
        final batchEnd = (i + dbCommitSize).clamp(0, filesToProcess.length);
        final batch = filesToProcess.sublist(i, batchEnd);

        progressNotifier.updateProgress(
          processedFiles: i,
          currentFile: 'Processing batch ${i ~/ dbCommitSize + 1}...',
        );

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

          if (metadata['album_art_uri'] != null) {
            final albumKey = '$album|$artist';
            albumArtUriMap.putIfAbsent(
              albumKey,
              () => metadata['album_art_uri']!,
            );
          }
        }

        final artistIdMap = await _batchProcessArtists(database, artistNames);
        final genreIdMap = await _batchProcessGenres(database, genreNames);
        final albumIdMap = await _batchProcessAlbums(
          database,
          albumArtistMap,
          artistIdMap,
          genreIdMap,
          albumArtUriMap,
          {},
          {},
          {for (var m in batch) m['path']!: m},
        );

        final tracksToInsert = <TracksCompanion>[];
        final tracksToUpdate = <TracksCompanion>[];

        for (int j = 0; j < batch.length; j++) {
          final metadata = batch[j];
          final filePath = metadata['path'] as String;
          final title =
              metadata['title'] ?? p.basenameWithoutExtension(filePath);
          final artistName = metadata['artist'] ?? 'Unknown Artist';
          final albumName = metadata['album'] ?? 'Unknown Album';
          final genreName = metadata['genre'] ?? 'Unknown Genre';
          final albumKey = '$albumName|$artistName';

          final lookupKey =
              '${title.toLowerCase()}|${artistName.toLowerCase()}';
          final existingTrack = trackLookup[lookupKey];

          if (existingTrack != null) {
            // If fileUri is not null, we don't touch it.
          } else {
            // It's a new track.
            tracksToInsert.add(
              TracksCompanion.insert(
                title: title,
                fileuri: Value(filePath),
                artistId: Value(artistIdMap[artistName]),
                albumId: Value(albumIdMap[albumKey]),
                genreId: Value(genreIdMap[genreName]),
                year: Value(metadata['year']),
                trackNumber: Value(metadata['track_number']),
                createdAt: Value(DateTime.now()),
              ),
            );
          }
          progressNotifier.updateProgress(
            processedFiles: i + j + 1,
            currentFile: p.basename(filePath),
          );
        }

        if (tracksToInsert.isNotEmpty) {
          await database.batch(
            (b) => b.insertAll(database.tracks, tracksToInsert),
          );
        }
        if (tracksToUpdate.isNotEmpty) {
          await database.batch((b) {
            for (final companion in tracksToUpdate) {
              b.update(database.tracks, companion);
            }
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
    Map<String, String> albumArtUri128Map,
    Map<String, String> albumArtUri32Map,
    Map<String, Map<String, dynamic>> metadataCache,
  ) async {
    final existingAlbumsResult = await db.select(db.albums).join([
      innerJoin(db.artists, db.artists.id.equalsExp(db.albums.artistId)),
    ]).get();

    final idMap = <String, int>{};
    final existingAlbumMap = <String, Album>{};
    for (final row in existingAlbumsResult) {
      final album = row.readTable(db.albums);
      final artist = row.readTable(db.artists);
      final key = '${album.name}|${artist.name}';
      idMap[key] = album.id;
      existingAlbumMap[key] = album;
    }

    final albumsToInsert = <AlbumsCompanion>[];
    final albumsToUpdate = <AlbumsCompanion>[];
    final newAlbumKeys = <String>{};

    for (final entry in albumArtistMap.entries) {
      final albumName = entry.key;
      final artistName = entry.value;
      final uniqueKey = '$albumName|$artistName';
      final coverArtUri = albumArtUriMap[uniqueKey];

      if (idMap.containsKey(uniqueKey)) {
        // Album exists, check if we should update the cover.
        final existingAlbum = existingAlbumMap[uniqueKey]!;
        if (coverArtUri != null && existingAlbum.coverImage != coverArtUri) {
          albumsToUpdate.add(
            AlbumsCompanion(
              id: Value(existingAlbum.id),
              coverImage: Value(coverArtUri),
            ),
          );
        }
      } else {
        // New album, create it.
        final metadata = metadataCache.values.firstWhere(
          (m) =>
              (m['album'] ?? 'Unknown Album') == albumName &&
              (m['artist'] ?? 'Unknown Artist') == artistName,
          orElse: () => {},
        );
        if (metadata.isEmpty) continue;

        final genreName = metadata['genre'] ?? 'Unknown Genre';

        albumsToInsert.add(
          AlbumsCompanion.insert(
            name: albumName,
            artistId: Value(artistIdMap[artistName]),
            genreId: Value(genreIdMap[genreName]),
            coverImage: Value(coverArtUri),
          ),
        );
        newAlbumKeys.add(uniqueKey);
      }
    }

    if (albumsToInsert.isNotEmpty) {
      await db.batch((batch) => batch.insertAll(db.albums, albumsToInsert));
      // Re-fetch to get IDs for the new albums
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

    if (albumsToUpdate.isNotEmpty) {
      await db.batch((batch) {
        for (final companion in albumsToUpdate) {
          batch.update(db.albums, companion);
        }
      });
    }

    return idMap;
  }

  Future<void> addExcludedDirectoryAndRemoveTracks(
    WidgetRef ref,
    String path,
  ) async {
    final database = ref.read(appDatabaseProvider);
    final metadataService = MetadataService();
    developer.log('Excluding directory and removing tracks: $path');

    await database
        .into(database.excludedDirectories)
        .insert(ExcludedDirectoriesCompanion.insert(path: path));

    final allTracks = await database.select(database.tracks).get();
    final tracksToDelete = <int>[];

    for (final track in allTracks) {
      final trackPath = track.fileuri != null
          ? await metadataService.getPathFromUri(track.fileuri!)
          : null;
      if (trackPath != null && trackPath.startsWith(path)) {
        tracksToDelete.add(track.id);
      }
    }

    if (tracksToDelete.isNotEmpty) {
      developer.log('Deleting ${tracksToDelete.length} tracks from $path');
      await (database.delete(
        database.tracks,
      )..where((t) => t.id.isIn(tracksToDelete))).go();

      await database.cleanupOrphanedMetadata();

      ref.invalidate(tracksProvider);
      ref.invalidate(albumsProvider);
      ref.invalidate(artistsProvider);
      ref.invalidate(genresProvider);
    }
  }
}

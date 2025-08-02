import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/artists.dart';
import 'package:flutter_application_1/widgets/genres.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:path_provider/path_provider.dart';

part 'schema.g.dart';

class MusicDirectories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().withLength(max: 255)();
  BoolColumn get is_enabled => boolean().withDefault(const Constant(true))();
  IntColumn get last_scanned => integer().nullable()();
  BoolColumn get scan_subdirectories =>
      boolean().withDefault(const Constant(true))();
  IntColumn get total_size => integer().withDefault(const Constant(0))();
  IntColumn get file_count => integer().withDefault(const Constant(0))();
  DateTimeColumn get date_added => dateTime()();
  TextColumn get excluded_subdirectories => text().nullable()();
}

// table for genres
class Genres extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Playlist extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

// Junction table for playlist-track many-to-many relationship
class PlaylistTracks extends Table {
  IntColumn get playlistId => integer().references(Playlist, #id)();
  IntColumn get trackId => integer().references(Tracks, #id)();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

class Cover extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cover => text().nullable()();
  TextColumn get hash => text().unique()();
}

// table for artists
class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get coverId => integer().nullable().references(Cover, #id)();
}

// table for albums
class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get coverId => integer().nullable().references(Cover, #id)();
  IntColumn get artistId => integer().nullable().references(Artists, #id)();
  IntColumn get genreId => integer().nullable().references(Genres, #id)();
}

// table for tracks
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get fileuri => text()(); // As requested
  IntColumn get coverId => integer().nullable().references(Cover, #id)();
  TextColumn get lyrics => text().nullable()();
  IntColumn get duration => integer().nullable()();
  TextColumn get trackNumber => text().nullable()();
  TextColumn get year => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  IntColumn get albumId => integer().nullable().references(Albums, #id)();
  IntColumn get artistId => integer().nullable().references(Artists, #id)();
  IntColumn get genreId => integer().nullable().references(Genres, #id)();
}

@DriftDatabase(
  tables: [
    MusicDirectories,
    Genres,
    Artists,
    Albums,
    Tracks,
    Cover,
    Playlist,
    PlaylistTracks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // Create indexes for better query performance
      await _createIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // Create indexes for better performance
        await _createIndexes();
      }
    },
  );

  Future<void> _createIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_tracks_artist_id ON tracks(artist_id);
      CREATE INDEX IF NOT EXISTS idx_tracks_album_id ON tracks(album_id);
      CREATE INDEX IF NOT EXISTS idx_albums_artist_id ON albums(artist_id);
      CREATE INDEX IF NOT EXISTS idx_tracks_title ON tracks(title);
      CREATE INDEX IF NOT EXISTS idx_artists_name ON artists(name);
      CREATE INDEX IF NOT EXISTS idx_albums_name ON albums(name);
    ''');
  }

  Future<List<TrackItem>> getAllTracks() async {
    final query = select(tracks).join([
      leftOuterJoin(artists, artists.id.equalsExp(tracks.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(tracks.coverId)),
    ]);

    final rows = await query.get();

    return rows.map((row) {
      final track = row.readTable(tracks);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return TrackItem(
        id: track.id,
        title: track.title,
        artist: artist?.name ?? '',
        cover: coverItem?.cover ?? '',
        fileuri: track.fileuri,
      );
    }).toList();
  }

  // Lightweight methods that only fetch basic info
  Future<List<ArtistItem>> getAllArtists() async {
    final query = select(
      artists,
    ).join([leftOuterJoin(cover, cover.id.equalsExp(artists.coverId))]);
    final rows = await query.get();

    return rows.map((row) {
      final artist = row.readTable(artists);
      final coverItem = row.readTableOrNull(cover);

      return ArtistItem(
        id: artist.id,
        name: artist.name,
        cover: coverItem?.cover ?? '',
        albums: null, // Will be loaded lazily
        tracks: null, // Will be loaded lazily
      );
    }).toList();
  }

  Future<List<AlbumItem>> getAllAlbums() async {
    final query = select(albums).join([
      leftOuterJoin(artists, artists.id.equalsExp(albums.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(albums.coverId)),
    ]);

    final rows = await query.get();

    return rows.map((row) {
      final album = row.readTable(albums);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return AlbumItem(
        id: album.id,
        name: album.name,
        cover: coverItem?.cover,
        artistName: artist?.name,
        artistId: artist?.id,
        tracks: null, // Will be loaded lazily
      );
    }).toList();
  }

  // New methods for lazy loading
  Future<List<AlbumItem>> getAlbumsByArtist(int artistId) async {
    final query = select(albums).join([
      leftOuterJoin(cover, cover.id.equalsExp(albums.coverId)),
    ])..where(albums.artistId.equals(artistId));

    final rows = await query.get();

    return rows.map((row) {
      final album = row.readTable(albums);
      final coverItem = row.readTableOrNull(cover);

      return AlbumItem(
        id: album.id,
        name: album.name,
        cover: coverItem?.cover,
        artistName: null, // Not needed when fetching by artist
        artistId: artistId,
        tracks: null, // Will be loaded lazily
      );
    }).toList();
  }

  Future<List<TrackItem>> getTracksByAlbum(int albumId) async {
    final query = select(tracks).join([
      leftOuterJoin(artists, artists.id.equalsExp(tracks.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(tracks.coverId)),
    ])..where(tracks.albumId.equals(albumId));

    final rows = await query.get();

    return rows.map((row) {
      final track = row.readTable(tracks);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return TrackItem(
        id: track.id,
        title: track.title,
        artist: artist?.name ?? '',
        cover: coverItem?.cover ?? '',
        fileuri: track.fileuri,
      );
    }).toList();
  }

  Future<List<TrackItem>> getTracksByArtist(int artistId) async {
    final query = select(tracks).join([
      leftOuterJoin(cover, cover.id.equalsExp(tracks.coverId)),
    ])..where(tracks.artistId.equals(artistId));

    final rows = await query.get();

    return rows.map((row) {
      final track = row.readTable(tracks);
      final coverItem = row.readTableOrNull(cover);

      return TrackItem(
        id: track.id,
        title: track.title,
        artist: '', // Artist name not needed when fetching by artist
        cover: coverItem?.cover ?? '',
        fileuri: track.fileuri,
      );
    }).toList();
  }

  // Optimized count methods using indexes
  Future<int> getAlbumCountByArtist(int artistId) async {
    final query = selectOnly(albums)
      ..addColumns([albums.id.count()])
      ..where(albums.artistId.equals(artistId));

    final result = await query.getSingle();
    return result.read(albums.id.count()) ?? 0;
  }

  Future<int> getTrackCountByArtist(int artistId) async {
    final query = selectOnly(tracks)
      ..addColumns([tracks.id.count()])
      ..where(tracks.artistId.equals(artistId));

    final result = await query.getSingle();
    return result.read(tracks.id.count()) ?? 0;
  }

  Future<int> getTrackCountByAlbum(int albumId) async {
    final query = selectOnly(tracks)
      ..addColumns([tracks.id.count()])
      ..where(tracks.albumId.equals(albumId));

    final result = await query.getSingle();
    return result.read(tracks.id.count()) ?? 0;
  }

  // Batch operations for better performance
  Future<void> insertTracksBatch(List<TracksCompanion> trackList) async {
    await batch((batch) {
      batch.insertAll(tracks, trackList);
    });
  }

  Future<void> insertAlbumsBatch(List<AlbumsCompanion> albumList) async {
    await batch((batch) {
      batch.insertAll(albums, albumList);
    });
  }

  Future<void> insertArtistsBatch(List<ArtistsCompanion> artistList) async {
    await batch((batch) {
      batch.insertAll(artists, artistList);
    });
  }

  // Optimized search methods with indexes
  Future<List<TrackItem>> searchTracks(String query) async {
    final searchQuery = select(tracks).join([
      leftOuterJoin(artists, artists.id.equalsExp(tracks.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(tracks.coverId)),
    ])..where(tracks.title.like('%$query%') | artists.name.like('%$query%'));

    final rows = await searchQuery.get();
    return rows.map((row) {
      final track = row.readTable(tracks);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return TrackItem(
        id: track.id,
        title: track.title,
        artist: artist?.name ?? '',
        cover: coverItem?.cover ?? '',
        fileuri: track.fileuri,
      );
    }).toList();
  }

  Future<List<ArtistItem>> searchArtists(String query) async {
    final searchQuery = select(artists).join([
      leftOuterJoin(cover, cover.id.equalsExp(artists.coverId)),
    ])..where(artists.name.like('%$query%'));

    final rows = await searchQuery.get();
    return rows.map((row) {
      final artist = row.readTable(artists);
      final coverItem = row.readTableOrNull(cover);

      return ArtistItem(
        id: artist.id,
        name: artist.name,
        cover: coverItem?.cover ?? '',
        albums: null,
        tracks: null,
      );
    }).toList();
  }

  Future<List<AlbumItem>> searchAlbumsByName(String query) async {
    final searchQuery = select(albums).join([
      leftOuterJoin(artists, artists.id.equalsExp(albums.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(albums.coverId)),
    ])..where(albums.name.like('%$query%') | artists.name.like('%$query%'));

    final rows = await searchQuery.get();
    return rows.map((row) {
      final album = row.readTable(albums);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return AlbumItem(
        id: album.id,
        name: album.name,
        cover: coverItem?.cover,
        artistName: artist?.name,
        artistId: artist?.id,
        tracks: null,
      );
    }).toList();
  }

  // Genre methods
  Future<List<GenreItem>> getAllGenres() async {
    final query = select(genres);
    final rows = await query.get();

    return rows.map((genre) {
      return GenreItem(id: genre.id, name: genre.name);
    }).toList();
  }

  Future<List<TrackItem>> getTracksByGenre(int genreId) async {
    final query = select(tracks).join([
      leftOuterJoin(artists, artists.id.equalsExp(tracks.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(tracks.coverId)),
    ])..where(tracks.genreId.equals(genreId));

    final rows = await query.get();

    return rows.map((row) {
      final track = row.readTable(tracks);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return TrackItem(
        id: track.id,
        title: track.title,
        artist: artist?.name ?? '',
        cover: coverItem?.cover ?? '',
        fileuri: track.fileuri,
      );
    }).toList();
  }

  Future<int> getTrackCountByGenre(int genreId) async {
    final query = selectOnly(tracks)
      ..addColumns([tracks.id.count()])
      ..where(tracks.genreId.equals(genreId));

    final result = await query.getSingle();
    return result.read(tracks.id.count()) ?? 0;
  }

  // Playlist methods
  Future<List<PlaylistItem>> getAllPlaylists() async {
    final query = select(playlist);
    final rows = await query.get();

    return rows.map((playlistRow) {
      return PlaylistItem(
        id: playlistRow.id,
        name: playlistRow.name,
        description: playlistRow.description,
        coverImage: playlistRow.coverImage,
        createdAt: playlistRow.createdAt,
        updatedAt: playlistRow.updatedAt,
      );
    }).toList();
  }

  Future<List<TrackItem>> getPlaylistTracks(int playlistId) async {
    final query =
        select(tracks).join([
            innerJoin(
              playlistTracks,
              playlistTracks.trackId.equalsExp(tracks.id),
            ),
            leftOuterJoin(artists, artists.id.equalsExp(tracks.artistId)),
            leftOuterJoin(cover, cover.id.equalsExp(tracks.coverId)),
          ])
          ..where(playlistTracks.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistTracks.addedAt)]);

    final rows = await query.get();

    return rows.map((row) {
      final track = row.readTable(tracks);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return TrackItem(
        id: track.id,
        title: track.title,
        artist: artist?.name ?? '',
        cover: coverItem?.cover ?? '',
        fileuri: track.fileuri,
      );
    }).toList();
  }

  Future<int> getPlaylistTrackCount(int playlistId) async {
    final query = selectOnly(playlistTracks)
      ..addColumns([playlistTracks.trackId.count()])
      ..where(playlistTracks.playlistId.equals(playlistId));

    final result = await query.getSingle();
    return result.read(playlistTracks.trackId.count()) ?? 0;
  }

  Future<int> createPlaylist(
    String name, {
    String? description,
    String? coverImage,
  }) async {
    final playlist = PlaylistCompanion.insert(
      name: name,
      description: Value(description),
      coverImage: Value(coverImage),
    );

    return await into(this.playlist).insert(playlist);
  }

  Future<void> updatePlaylist(
    int playlistId, {
    String? name,
    String? description,
    String? coverImage,
  }) async {
    final updateData = PlaylistCompanion(
      id: Value(playlistId),
      name: name != null ? Value(name) : const Value.absent(),
      description: Value(description),
      coverImage: Value(coverImage),
      updatedAt: Value(DateTime.now()),
    );

    await (update(
      playlist,
    )..where((p) => p.id.equals(playlistId))).write(updateData);
  }

  Future<void> deletePlaylist(int playlistId) async {
    await transaction(() async {
      // First remove all tracks from the playlist
      await (delete(
        playlistTracks,
      )..where((pt) => pt.playlistId.equals(playlistId))).go();

      // Then delete the playlist itself
      await (delete(playlist)..where((p) => p.id.equals(playlistId))).go();
    });
  }

  Future<void> addTrackToPlaylist(int playlistId, int trackId) async {
    final playlistTrack = PlaylistTracksCompanion.insert(
      playlistId: playlistId,
      trackId: trackId,
      position: 0,
    );

    await into(playlistTracks).insert(
      playlistTrack,
      mode: InsertMode.insertOrIgnore, // Prevent duplicates
    );
  }

  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds) async {
    await batch((batch) {
      for (final trackId in trackIds) {
        batch.insert(
          playlistTracks,
          PlaylistTracksCompanion.insert(
            playlistId: playlistId,
            trackId: trackId,
            position: 0,
          ),
          mode: InsertMode.insertOrIgnore, // Prevent duplicates
        );
      }
    });
  }

  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async {
    await (delete(playlistTracks)..where(
          (pt) => pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId),
        ))
        .go();
  }

  // Pagination support for large datasets (incorrect implementation, renamed to avoid conflict)
  Future<List<ArtistItem>> getArtistsByNamePaginated({
    required String query,
    int limit = 50,
    int offset = 0,
  }) async {
    final searchQuery =
        select(
            artists,
          ).join([leftOuterJoin(cover, cover.id.equalsExp(artists.coverId))])
          ..where(artists.name.like('%$query%'))
          ..limit(limit, offset: offset);

    final rows = await searchQuery.get();
    return rows.map((row) {
      final artist = row.readTable(artists);
      final coverItem = row.readTableOrNull(cover);

      return ArtistItem(
        id: artist.id,
        name: artist.name,
        cover: coverItem?.cover ?? '',
        albums: null,
        tracks: null,
      );
    }).toList();
  }

  Future<List<AlbumItem>> searchAlbums(String query) async {
    final searchQuery = select(albums).join([
      leftOuterJoin(artists, artists.id.equalsExp(albums.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(albums.coverId)),
    ])..where(albums.name.like('%$query%') | artists.name.like('%$query%'));

    final rows = await searchQuery.get();
    return rows.map((row) {
      final album = row.readTable(albums);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return AlbumItem(
        id: album.id,
        name: album.name,
        cover: coverItem?.cover,
        artistName: artist?.name,
        artistId: artist?.id,
        tracks: null,
      );
    }).toList();
  }

  // Pagination support for large datasets
  Future<List<TrackItem>> getTracksPaginated({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(tracks).join([
      leftOuterJoin(artists, artists.id.equalsExp(tracks.artistId)),
      leftOuterJoin(cover, cover.id.equalsExp(tracks.coverId)),
    ])..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) {
      final track = row.readTable(tracks);
      final artist = row.readTableOrNull(artists);
      final coverItem = row.readTableOrNull(cover);

      return TrackItem(
        id: track.id,
        title: track.title,
        artist: artist?.name ?? '',
        cover: coverItem?.cover ?? '',
        fileuri: track.fileuri,
      );
    }).toList();
  }

  Future<List<ArtistItem>> getArtistsPaginated({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(artists).join([
      leftOuterJoin(cover, cover.id.equalsExp(artists.coverId)),
    ])..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) {
      final artist = row.readTable(artists);
      final coverItem = row.readTableOrNull(cover);

      return ArtistItem(
        id: artist.id,
        name: artist.name,
        cover: coverItem?.cover ?? '',
        albums: null,
        tracks: null,
      );
    }).toList();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

/*
CREATE TABLE music_directories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  -- 📁 Full path to the root directory (e.g., /storage/emulated/0/Music)
  path TEXT NOT NULL UNIQUE,
  
  -- ✅ Whether this directory is enabled for scanning
  is_enabled INTEGER NOT NULL DEFAULT 1,
  
  -- 🕒 Last scanned timestamp (ms since epoch), NULL if never scanned
  last_scanned INTEGER,
  
  -- 🔍 Whether to scan subdirectories recursively (default: true)
  scan_subdirectories INTEGER NOT NULL DEFAULT 1,
  
  -- 📦 Cached total size of audio files (bytes)
  total_size INTEGER NOT NULL DEFAULT 0,
  
  -- 🎵 Number of audio files found
  file_count INTEGER NOT NULL DEFAULT 0,
  
  -- 📅 When the directory was added (ms since epoch)
  date_added INTEGER NOT NULL,
  
  -- 🚫 List of subdirectories to exclude (stored as JSON array of paths)
  excluded_subdirectories TEXT -- e.g., ["/Music/Podcasts", "/Music/Ads"]
);
*/

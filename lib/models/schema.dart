import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  IntColumn get albumId => integer().nullable().references(Albums, #id)();
  IntColumn get artistId => integer().nullable().references(Artists, #id)();
  IntColumn get genreId => integer().nullable().references(Genres, #id)();
}

@DriftDatabase(
  tables: [MusicDirectories, Genres, Artists, Albums, Tracks, Cover],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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

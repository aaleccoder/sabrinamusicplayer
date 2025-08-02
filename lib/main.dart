import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/routes.dart';
import 'package:flutter_application_1/screens/settings.dart';
import 'package:flutter_application_1/services/audio_service.dart';
import 'package:flutter_application_1/services/library_service.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/artists.dart';
import 'package:flutter_application_1/widgets/genres.dart';
import 'package:flutter_application_1/widgets/library.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final audioPlayerNotifierProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      return AudioPlayerNotifier();
    });

final tracksProvider = FutureProvider<List<TrackItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllTracks();
});

final albumsProvider = FutureProvider<List<AlbumItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllAlbums();
});

final artistsProvider = FutureProvider<List<ArtistItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllArtists();
});

// Providers for lazy loading counts
final artistAlbumCountProvider = FutureProvider.family<int, int>((
  ref,
  artistId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAlbumCountByArtist(artistId);
});

final artistTrackCountProvider = FutureProvider.family<int, int>((
  ref,
  artistId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTrackCountByArtist(artistId);
});

final albumsByArtistProvider = FutureProvider.family<List<AlbumItem>, int>((
  ref,
  artistId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAlbumsByArtist(artistId);
});

final tracksByArtistProvider = FutureProvider.family<List<TrackItem>, int>((
  ref,
  artistId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTracksByArtist(artistId);
});

final tracksByAlbumProvider = FutureProvider.family<List<TrackItem>, int>((
  ref,
  albumId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTracksByAlbum(albumId);
});

final albumTrackCountProvider = FutureProvider.family<int, int>((ref, albumId) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTrackCountByAlbum(albumId);
});

// Genre providers
final genresProvider = FutureProvider<List<GenreItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllGenres();
});

final tracksByGenreProvider = FutureProvider.family<List<TrackItem>, int>((
  ref,
  genreId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTracksByGenre(genreId);
});

final genreTrackCountProvider = FutureProvider.family<int, int>((ref, genreId) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTrackCountByGenre(genreId);
});

// Playlist providers
final playlistsProvider = FutureProvider<List<PlaylistItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllPlaylists();
});

final playlistTracksProvider = FutureProvider.family<List<TrackItem>, int>((
  ref,
  playlistId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getPlaylistTracks(playlistId);
});

final playlistTrackCountProvider = FutureProvider.family<int, int>((
  ref,
  playlistId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.getPlaylistTrackCount(playlistId);
});

// Search provider
final searchTracksProvider = FutureProvider.family<List<TrackItem>, String>((
  ref,
  query,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.searchTracks(query);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.audio.request();
  await Permission.storage.request();

  final container = ProviderContainer();
  LibraryService().scanIfChange(container);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: AppTheme.primary,
          onPrimary: AppTheme.onPrimary,
          secondary: AppTheme.secondary,
          onSecondary: AppTheme.onSecondary,
          surface: AppTheme.surface,
          onSurface: AppTheme.onSurface,
          error: AppTheme.error,
          onError: AppTheme.onError,
        ),
        textTheme: AppTheme.textTheme,
        scaffoldBackgroundColor: AppTheme.background,
      ),
      home: Home(),
    );
  }
}

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [SongListView(), Library(), SettingsPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]),
          MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          // NavigationDestination(
          //   icon: Icon(Icons.thermostat_auto),
          //   label: 'Test',
          // ),
        ],
      ),
    );
  }
}

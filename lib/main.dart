import 'package:flutter/foundation.dart';
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
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_application_1/widgets/library.dart';
import 'package:flutter_application_1/widgets/library_scanning_overlay.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final audioPlayerNotifierProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      return AudioPlayerNotifier(ref);
    });

final tracksProvider = StreamProvider.family<List<TrackItem>, SortOption>((
  ref,
  sortOption,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTracks(
    isUnliked: false,
    sortOption: sortOption,
    coverSize: CoverSize.s128,
  );
});

final likedTracksProvider = StreamProvider<List<TrackItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTracks(isFavorite: true, coverSize: CoverSize.s32);
});

final unlikedTracksProvider = StreamProvider<List<TrackItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTracks(isUnliked: true, coverSize: CoverSize.s32);
});

final albumsProvider = FutureProvider<List<AlbumItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllAlbums(coverSize: CoverSize.s128);
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

final tracksByArtistProvider = StreamProvider.family<List<TrackItem>, int>((
  ref,
  artistId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTracksByArtist(artistId);
});

final tracksByAlbumProvider = StreamProvider.family<List<TrackItem>, int>((
  ref,
  albumId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTracksByAlbum(albumId);
});

final albumTrackCountProvider = FutureProvider.family<int, int>((ref, albumId) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTrackCountByAlbum(albumId);
});

// Genre providers
final genresProvider = FutureProvider.autoDispose<List<GenreItem>>((ref) {
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

final genreTrackCountProvider = FutureProvider.autoDispose.family<int, int>((
  ref,
  genreId,
) {
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

// Search providers
final searchTracksProvider = StreamProvider.family<List<TrackItem>, String>((
  ref,
  query,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSearchTracks(query);
});

final searchAlbumsProvider = FutureProvider.family<List<AlbumItem>, String>((
  ref,
  query,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.searchAlbums(query);
});

final searchArtistsProvider = FutureProvider.family<List<ArtistItem>, String>((
  ref,
  query,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.searchArtists(query);
});

final searchPlaylistsProvider =
    FutureProvider.family<List<PlaylistItem>, String>((ref, query) {
      final db = ref.watch(appDatabaseProvider);
      return db.getAllPlaylists().then(
        (playlists) => playlists
            .where(
              (playlist) =>
                  playlist.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    });

final updateTrackProvider = FutureProvider.family<void, TrackItem>((
  ref,
  track,
) async {
  final db = ref.watch(appDatabaseProvider);
  await db.updateTrack(track);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugProfileBuildsEnabled = true;
  }

  await Permission.audio.request();
  await Permission.storage.request();
  await Permission.notification.request();
  await Permission.mediaLibrary.request();
  await Permission.photos.request();
  await Permission.accessNotificationPolicy.request();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,

      theme: ThemeData(
        fontFamily: "Sora",
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: AppTheme.surface,
          error: AppTheme.error,
          onPrimary: AppTheme.onPrimary,
          onSecondary: AppTheme.onSecondary,
          onSurface: AppTheme.onSurface,
          onError: AppTheme.onError,
        ),
        textTheme: AppTheme.textTheme,
        scaffoldBackgroundColor: AppTheme.background,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
          color: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
            padding: AppTheme.paddingMd,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primary.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.onSurface.withOpacity(0.6),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: AppTheme.primary, size: 24);
            }
            return IconThemeData(
              color: AppTheme.onSurface.withOpacity(0.6),
              size: 24,
            );
          }),
        ),
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

class _HomeState extends ConsumerState<Home> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  final List<Widget> _pages = [
    SongListView(),
    const AlbumsPage(),
    const ArtistsPage(),
    const GenresPage(),
    const Library(),
    const SettingsPage(),
  ];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppTheme.curveDefault,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: AppTheme.curveDefault,
          ),
        );

    _animationController.forward();
    // Defer heavy scan to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScan();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndScan() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('initial_scan_done') ?? false) return;

    await LibraryService().scanLibrary(ref);

    await prefs.setBool('initial_scan_done', true);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // Reverse animation before switching pages
    _animationController.reverse().then((_) {
      setState(() => _selectedIndex = index);
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(color: AppTheme.background),
        child: Stack(
          children: [
            // Use PageStorage to preserve tab state
            PageStorage(
              bucket: _pageStorageBucket,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _pages[_selectedIndex],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 90, // Navigation bar height (60) + margin (16)
              child: MiniPlayer(),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 4,
              child: _buildModernNavigationBar(),
            ),
            LibraryScanningOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNavigationBar() {
    return ClipRRect(
      borderRadius: AppTheme.radiusXl,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusXl,
          color: Colors.black.withOpacity(
            0.90,
          ), // Dark frosted glass, 90% opacity

          border: Border.all(color: Colors.white.withOpacity(0.13), width: 1.5),
          // No boxShadow
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavDestination(Icons.music_note, 'Songs', 0),
            _buildNavDestination(Icons.album, 'Albums', 1),
            _buildNavDestination(Icons.person, 'Artists', 2),
            _buildNavDestination(Icons.category, 'Genres', 3),
            _buildNavDestination(Icons.library_music, 'Library', 4),
            _buildNavDestination(Icons.settings, 'Settings', 5),
          ],
        ),
      ),
    );
  }

  Widget _buildNavDestination(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppTheme.animationFast,
                curve: AppTheme.curveDefault,
                padding: EdgeInsets.all(isSelected ? 6 : 4),
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.3),
                        borderRadius: AppTheme.radiusSm,
                      )
                    : null,
                child: Icon(
                  icon,
                  size: isSelected ? 28 : 24,
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: AppTheme.animationFast,
                style:
                    AppTheme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurface.withOpacity(0.7),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ) ??
                    const TextStyle(),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

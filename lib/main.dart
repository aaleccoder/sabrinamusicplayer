import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/providers/library_scanning_provider.dart';
import 'package:flutter_application_1/routes.dart';
import 'package:flutter_application_1/screens/settings.dart';
import 'package:flutter_application_1/services/audio_service.dart';
import 'package:flutter_application_1/services/library_service.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/artists.dart';
import 'package:flutter_application_1/widgets/genres.dart';
import 'package:flutter_application_1/widgets/library.dart';
import 'package:flutter_application_1/widgets/library_scanning_overlay.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Search providers
final searchTracksProvider = FutureProvider.family<List<TrackItem>, String>((
  ref,
  query,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.searchTracks(query);
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.audio.request();
  await Permission.storage.request();

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
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primary,
          secondary: AppTheme.secondary,
          surface: AppTheme.surface,
          background: AppTheme.background,
          error: AppTheme.error,
          onPrimary: AppTheme.onPrimary,
          onSecondary: AppTheme.onSecondary,
          onSurface: AppTheme.onSurface,
          onBackground: AppTheme.onBackground,
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
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.onSurface.withOpacity(0.6),
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
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
  final List<Widget> _pages = [SongListView(), Library(), SettingsPage()];
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
    _checkAndScan();
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

    setState(() {
      _selectedIndex = index;
    });

    // Restart animation for page transition
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.0,
            colors: [
              AppTheme.primary.withOpacity(0.05),
              AppTheme.background,
              AppTheme.background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
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
            Positioned(
              left: 0,
              right: 0,
              bottom:
                  102, // Navigation bar height (70) + margins (16*2) + small gap
              child: MiniPlayer(),
            ),
            LibraryScanningOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: _buildModernNavigationBar(),
    );
  }

  Widget _buildModernNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.shadowLg,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.radiusXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppTheme.radiusXl,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: NavigationBar(
              height: 70,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              indicatorColor: Colors.transparent,
              destinations: [
                _buildNavDestination(Icons.home_rounded, 'Home', 0),
                _buildNavDestination(Icons.library_music_rounded, 'Library', 1),
                _buildNavDestination(Icons.settings_rounded, 'Settings', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;

    return NavigationDestination(
      icon: AnimatedContainer(
        duration: AppTheme.animationFast,
        curve: AppTheme.curveDefault,
        padding: EdgeInsets.all(isSelected ? 8 : 4),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: AppTheme.radiusMd,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          size: isSelected ? 26 : 24,
          color: isSelected
              ? AppTheme.primary
              : AppTheme.onSurface.withOpacity(0.6),
        ),
      ),
      label: label,
    );
  }
}

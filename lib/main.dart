import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/routes.dart';
import 'package:flutter_application_1/screens/metadata_screen.dart';
import 'package:flutter_application_1/screens/player_screen.dart';
import 'package:flutter_application_1/screens/settings.dart';
import 'package:flutter_application_1/services/audio_service.dart';
import 'package:flutter_application_1/services/library_service.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
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
  final List<Widget> _pages = [
    SongListView(),
    SettingsPage(),
    MetadataScreen(),
  ];

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
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          NavigationDestination(
            icon: Icon(Icons.thermostat_auto),
            label: 'Test',
          ),
        ],
      ),
    );
  }
}

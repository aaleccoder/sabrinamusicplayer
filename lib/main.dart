import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/routes.dart';
import 'package:flutter_application_1/services/library_service.dart';
import 'package:flutter_application_1/widgets/navbar.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
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
      home: NavbarScaffold(),
    );
  }
}

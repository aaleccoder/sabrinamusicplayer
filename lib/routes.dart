// routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/metadata_screen.dart';
import 'package:flutter_application_1/screens/settings.dart';
import 'package:flutter_application_1/unknown_page.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings_page = '/settings_page';
  static const String profile = '/profile';
  static const String metadataTestScreeen = "/metadata";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case metadataTestScreeen:
        return MaterialPageRoute(builder: (_) => MetadataScreen());
      case home:
        return MaterialPageRoute(builder: (_) => SongListView());
      case settings_page:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => UnknownPage());
    }
  }
}

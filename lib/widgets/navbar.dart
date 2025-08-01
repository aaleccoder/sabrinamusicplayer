import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';

class NavbarScaffold extends StatefulWidget {
  const NavbarScaffold({super.key});

  @override
  State<NavbarScaffold> createState() => _NavbarScaffoldState();
}

class _NavbarScaffoldState extends State<NavbarScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.settings_page);
        setState(() {
          _selectedIndex = 0;
        });
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.metadataTestScreeen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SongListView(),
    );
  }
}

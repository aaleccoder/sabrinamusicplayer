import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'albums.dart';
import 'artists.dart';
import 'genres.dart';
import 'playlists.dart';
import 'mini_player.dart';

class Library extends ConsumerStatefulWidget {
  const Library({super.key});

  @override
  ConsumerState<Library> createState() => _LibraryState();
}

class _LibraryState extends ConsumerState<Library> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: ListView(
          children: [
            _LibraryItem(
              icon: Icons.disc_full,
              label: "Album",
              color: Colors.deepPurple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlbumsPageWrapper(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _LibraryItem(
              icon: Icons.person,
              label: "Artists",
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArtistsPageWrapper(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _LibraryItem(
              icon: Icons.category,
              label: "Genres",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GenresPageWrapper(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _LibraryItem(
              icon: Icons.queue_music,
              label: "Playlists",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaylistsPageWrapper(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _LibraryItem(
              icon: Icons.favorite,
              label: "Liked Songs",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilteredSongsPageWrapper(
                      title: 'Liked Songs',
                      provider: likedTracksProvider,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _LibraryItem(
              icon: Icons.thumb_down,
              label: "Unliked Songs",
              color: Colors.grey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilteredSongsPageWrapper(
                      title: 'Unliked Songs',
                      provider: unlikedTracksProvider,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LibraryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(width: 24),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlbumsPageWrapper extends StatelessWidget {
  const AlbumsPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Albums'), centerTitle: true),
      body: Column(
        children: [
          Expanded(child: AlbumsPage()),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class ArtistsPageWrapper extends StatelessWidget {
  const ArtistsPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artists'), centerTitle: true),
      body: Column(
        children: [
          Expanded(child: ArtistsPage()),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class FilteredSongsPageWrapper extends StatelessWidget {
  final String title;
  final StreamProvider<List<TrackItem>> provider;

  const FilteredSongsPageWrapper({
    super.key,
    required this.title,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Column(
        children: [
          Expanded(child: FilteredSongsPage(provider: provider)),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class FilteredSongsPage extends ConsumerWidget {
  final StreamProvider<List<TrackItem>> provider;

  const FilteredSongsPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(provider);
    return tracksAsync.when(
      data: (tracks) => tracks.isEmpty
          ? const Center(child: Text('No songs found.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              itemCount: tracks.length,
              itemBuilder: (context, index) => SongListViewItem(
                track: tracks[index],
                tracks: tracks,
                index: index,
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class PlaylistsPageWrapper extends StatelessWidget {
  const PlaylistsPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists'), centerTitle: true),
      body: Column(
        children: [
          Expanded(child: PlaylistsPage()),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class GenresPageWrapper extends StatelessWidget {
  const GenresPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genres'), centerTitle: true),
      body: Column(
        children: [
          Expanded(child: GenresPage()),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'playlists.dart';

class Library extends ConsumerStatefulWidget {
  const Library({super.key});

  @override
  ConsumerState<Library> createState() => _LibraryState();
}

class _LibraryState extends ConsumerState<Library>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Liked'),
            Tab(text: 'Unliked'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const PlaylistsPage(),
          FilteredSongsPage(provider: likedTracksProvider),
          FilteredSongsPage(provider: unlikedTracksProvider),
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

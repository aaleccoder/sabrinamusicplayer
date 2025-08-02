import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/album_detail_page.dart';
import 'package:flutter_application_1/widgets/artist_detail_page.dart';
import 'package:flutter_application_1/widgets/playlist_detail_page.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/artists.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class GlobalSearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;

  const GlobalSearchPage({super.key, this.initialQuery});

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  late TextEditingController _searchController;
  String _currentQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _currentQuery = widget.initialQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _currentQuery = query.trim();
      _isSearching = _currentQuery.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search songs, albums, artists...',
            hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurface.withOpacity(0.6),
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
          onSubmitted: _performSearch,
        ),
        centerTitle: false,
      ),
      body: _isSearching && _currentQuery.isNotEmpty
          ? _buildSearchResults()
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppTheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search your music library',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find songs, albums, artists, and playlists',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onBackground.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        color: AppTheme.surface,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.radiusXl,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.radiusXl,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.02),
                Colors.white.withOpacity(0.01),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
          ),
          child: SingleChildScrollView(
            padding: AppTheme.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTracksSection(),
                const SizedBox(height: 24),
                _buildAlbumsSection(),
                const SizedBox(height: 24),
                _buildArtistsSection(),
                const SizedBox(height: 24),
                _buildPlaylistsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTracksSection() {
    final tracksAsync = ref.watch(searchTracksProvider(_currentQuery));

    return tracksAsync.when(
      data: (tracks) => _buildSection(
        'Songs',
        tracks.length,
        tracks.isEmpty
            ? const Text('No songs found')
            : Column(
                children: tracks
                    .take(5)
                    .map((track) => _buildTrackItem(track, tracks))
                    .toList(),
              ),
        onViewAll: tracks.length > 5
            ? () => _showAllResults('Songs', tracks)
            : null,
      ),
      loading: () =>
          _buildSection('Songs', 0, const CircularProgressIndicator()),
      error: (error, _) => _buildSection('Songs', 0, Text('Error: $error')),
    );
  }

  Widget _buildAlbumsSection() {
    final albumsAsync = ref.watch(searchAlbumsProvider(_currentQuery));

    return albumsAsync.when(
      data: (albums) => _buildSection(
        'Albums',
        albums.length,
        albums.isEmpty
            ? const Text('No albums found')
            : SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: albums.take(10).length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _buildAlbumCard(albums[index]),
                ),
              ),
        onViewAll: albums.length > 10
            ? () => _showAllResults('Albums', albums)
            : null,
      ),
      loading: () =>
          _buildSection('Albums', 0, const CircularProgressIndicator()),
      error: (error, _) => _buildSection('Albums', 0, Text('Error: $error')),
    );
  }

  Widget _buildArtistsSection() {
    final artistsAsync = ref.watch(searchArtistsProvider(_currentQuery));

    return artistsAsync.when(
      data: (artists) => _buildSection(
        'Artists',
        artists.length,
        artists.isEmpty
            ? const Text('No artists found')
            : Column(
                children: artists
                    .take(5)
                    .map((artist) => _buildArtistItem(artist))
                    .toList(),
              ),
        onViewAll: artists.length > 5
            ? () => _showAllResults('Artists', artists)
            : null,
      ),
      loading: () =>
          _buildSection('Artists', 0, const CircularProgressIndicator()),
      error: (error, _) => _buildSection('Artists', 0, Text('Error: $error')),
    );
  }

  Widget _buildPlaylistsSection() {
    final playlistsAsync = ref.watch(searchPlaylistsProvider(_currentQuery));

    return playlistsAsync.when(
      data: (playlists) => _buildSection(
        'Playlists',
        playlists.length,
        playlists.isEmpty
            ? const Text('No playlists found')
            : Column(
                children: playlists
                    .take(5)
                    .map((playlist) => _buildPlaylistItem(playlist))
                    .toList(),
              ),
        onViewAll: playlists.length > 5
            ? () => _showAllResults('Playlists', playlists)
            : null,
      ),
      loading: () =>
          _buildSection('Playlists', 0, const CircularProgressIndicator()),
      error: (error, _) => _buildSection('Playlists', 0, Text('Error: $error')),
    );
  }

  Widget _buildSection(
    String title,
    int count,
    Widget content, {
    VoidCallback? onViewAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title${count > 0 ? ' ($count)' : ''}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onViewAll != null)
              TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildTrackItem(TrackItem track, List<TrackItem> allTracks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        color: AppTheme.surface,
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildTrackCover(track),
        ),
        title: Text(
          track.title,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.onSurface.withOpacity(0.7),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () async {
          final musicPlayer = ref.watch(audioPlayerNotifierProvider.notifier);
          await musicPlayer.createQueue([track]);
          musicPlayer.play(track);
        },
      ),
    );
  }

  Widget _buildTrackCover(TrackItem track) {
    try {
      if (track.cover.isNotEmpty) {
        final coverUri = Uri.parse(track.cover);
        if (coverUri.isScheme('file')) {
          final file = File.fromUri(coverUri);
          if (file.existsSync()) {
            return Image.file(file, width: 50, height: 50, fit: BoxFit.cover);
          }
        }
      }
    } catch (e) {
      // Fall back to placeholder
    }

    return Container(
      width: 50,
      height: 50,
      color: AppTheme.primary.withOpacity(0.1),
      child: Icon(Icons.music_note, color: AppTheme.primary),
    );
  }

  Widget _buildAlbumCard(AlbumItem album) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailPage(album: album),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusXl,
          color: AppTheme.surface,
        ),
        padding: AppTheme.paddingSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppTheme.radiusSm,
              child: _buildAlbumCover(album),
            ),
            const SizedBox(height: 8),
            Text(
              album.name ?? 'Unknown Album',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppTheme.textTheme.bodyMedium?.fontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            if (album.artistName != null) ...[
              const SizedBox(height: 4),
              Text(
                album.artistName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                  color: AppTheme.onSurface.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCover(AlbumItem album) {
    try {
      if (album.cover != null && album.cover!.isNotEmpty) {
        final coverUri = Uri.parse(album.cover!);
        if (coverUri.isScheme('file')) {
          final file = File.fromUri(coverUri);
          if (file.existsSync()) {
            return Image.file(file, width: 124, height: 100, fit: BoxFit.cover);
          }
        }
      }
    } catch (e) {
      // Fall back to placeholder
    }

    return Container(
      width: 124,
      height: 120,
      color: AppTheme.primary.withOpacity(0.1),
      child: Icon(Icons.album, color: AppTheme.primary, size: 40),
    );
  }

  Widget _buildArtistItem(ArtistItem artist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        color: AppTheme.surface,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: AppTheme.primary),
        ),
        title: Text(
          artist.name,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text('Artist'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailPage(artist: artist),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistItem(PlaylistItem playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        color: AppTheme.surface,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary.withOpacity(0.1),
          child: Icon(Icons.queue_music, color: AppTheme.secondary),
        ),
        title: Text(
          playlist.name,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(playlist.description ?? 'Playlist'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailPage(playlist: playlist),
            ),
          );
        },
      ),
    );
  }

  void _showAllResults(String category, List<dynamic> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AllResultsPage(
          category: category,
          query: _currentQuery,
          items: items,
        ),
      ),
    );
  }
}

class _AllResultsPage extends ConsumerWidget {
  final String category;
  final String query;
  final List<dynamic> items;

  const _AllResultsPage({
    required this.category,
    required this.query,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('$category - "$query"'), centerTitle: true),
      body: Padding(
        padding: AppTheme.paddingMd,
        child: items.isEmpty
            ? Center(
                child: Text(
                  'No $category found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onBackground.withOpacity(0.6),
                  ),
                ),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is TrackItem) {
                    return _buildTrackItem(context, ref, item);
                  } else if (item is AlbumItem) {
                    return _buildAlbumItem(context, item);
                  } else if (item is ArtistItem) {
                    return _buildArtistItem(context, item);
                  } else if (item is PlaylistItem) {
                    return _buildPlaylistItem(context, item);
                  }
                  return const SizedBox.shrink();
                },
              ),
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, WidgetRef ref, TrackItem track) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusMd,
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildTrackCover(track),
        ),
        title: Text(
          track.title,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.onSurface.withOpacity(0.7),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () async {
          final musicPlayer = ref.watch(audioPlayerNotifierProvider.notifier);
          await musicPlayer.createQueue([track]);
          musicPlayer.play(track);
        },
      ),
    );
  }

  Widget _buildTrackCover(TrackItem track) {
    try {
      if (track.cover.isNotEmpty) {
        final coverUri = Uri.parse(track.cover);
        if (coverUri.isScheme('file')) {
          final file = File.fromUri(coverUri);
          if (file.existsSync()) {
            return Image.file(file, width: 50, height: 50, fit: BoxFit.cover);
          }
        }
      }
    } catch (e) {
      // Fall back to placeholder
    }

    return Container(
      width: 50,
      height: 50,
      color: AppTheme.primary.withOpacity(0.1),
      child: Icon(Icons.music_note, color: AppTheme.primary),
    );
  }

  Widget _buildAlbumItem(BuildContext context, AlbumItem album) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusMd,
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildAlbumCover(album),
        ),
        title: Text(
          album.name ?? 'Unknown Album',
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          album.artistName ?? 'Unknown Artist',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.onSurface.withOpacity(0.7),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumDetailPage(album: album),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumCover(AlbumItem album) {
    try {
      if (album.cover != null && album.cover!.isNotEmpty) {
        final coverUri = Uri.parse(album.cover!);
        if (coverUri.isScheme('file')) {
          final file = File.fromUri(coverUri);
          if (file.existsSync()) {
            return Image.file(file, width: 50, height: 50, fit: BoxFit.cover);
          }
        }
      }
    } catch (e) {
      // Fall back to placeholder
    }

    return Container(
      width: 50,
      height: 50,
      color: AppTheme.primary.withOpacity(0.1),
      child: Icon(Icons.album, color: AppTheme.primary, size: 24),
    );
  }

  Widget _buildArtistItem(BuildContext context, ArtistItem artist) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusMd,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: AppTheme.primary),
        ),
        title: Text(
          artist.name,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text('Artist'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailPage(artist: artist),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistItem(BuildContext context, PlaylistItem playlist) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusMd,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary.withOpacity(0.1),
          child: Icon(Icons.queue_music, color: AppTheme.secondary),
        ),
        title: Text(
          playlist.name,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(playlist.description ?? 'Playlist'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailPage(playlist: playlist),
            ),
          );
        },
      ),
    );
  }
}

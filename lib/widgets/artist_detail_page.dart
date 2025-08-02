import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/artists.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
import 'package:flutter_application_1/widgets/artist_all_tracks_page.dart';
import 'package:flutter_application_1/widgets/album_detail_page.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';

class ArtistDetailPage extends ConsumerStatefulWidget {
  final ArtistItem artist;

  const ArtistDetailPage({super.key, required this.artist});

  @override
  ConsumerState<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends ConsumerState<ArtistDetailPage> {
  void _playTrack(TrackItem track, List<TrackItem> tracks, int index) async {
    final musicPlayer = ref.watch(audioPlayerNotifierProvider.notifier);
    final queue = tracks.sublist(index);
    await musicPlayer.createQueue(queue);
    musicPlayer.play(track);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(
      builder: (context, ref, _) {
        final tracksAsync = ref.watch(tracksByArtistProvider(widget.artist.id));
        final albumsAsync = ref.watch(albumsByArtistProvider(widget.artist.id));

        return tracksAsync.when(
          data: (tracks) {
            return albumsAsync.when(
              data: (albums) {
                final displayedTracks = tracks.take(10).toList();
                final hasMoreTracks = tracks.length > 10;

                return _buildContent(
                  context,
                  colorScheme,
                  tracks,
                  albums,
                  displayedTracks,
                  hasMoreTracks,
                );
              },
              loading: () => _buildLoadingState(colorScheme),
              error: (err, stack) =>
                  _buildErrorState(colorScheme, 'Error loading albums: $err'),
            );
          },
          loading: () => _buildLoadingState(colorScheme),
          error: (err, stack) =>
              _buildErrorState(colorScheme, 'Error loading tracks: $err'),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    List<TrackItem> tracks,
    List<AlbumItem> albums,
    List<TrackItem> displayedTracks,
    bool hasMoreTracks,
  ) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: const EdgeInsets.only(
                        top: 80,
                        left: 20,
                        right: 20,
                      ),
                      child: Column(
                        children: [
                          // Artist Cover
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: widget.artist.cover.isNotEmpty
                                  ? Image.file(
                                      File(widget.artist.cover),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[800],
                                                child: Icon(
                                                  Icons.person,
                                                  size: 80,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.person,
                                        size: 80,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Artist Name
                        Text(
                          widget.artist.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Track and Album count
                        Text(
                          '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'} • ${albums.length} ${albums.length == 1 ? 'album' : 'albums'}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Popular Tracks Section
                if (displayedTracks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          if (hasMoreTracks)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArtistAllTracksPage(
                                      artist: widget.artist,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Show all',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (displayedTracks.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final track = displayedTracks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: ArtistTrackListItem(
                          track: track,
                          tracks: tracks,
                          index: index,
                          onTap: () => _playTrack(track, tracks, index),
                        ),
                      );
                    }, childCount: displayedTracks.length),
                  ),
                // Albums Section
                if (albums.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 32,
                        bottom: 16,
                      ),
                      child: Text(
                        'Albums',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                if (albums.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 160,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AlbumDetailPage(album: album),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child:
                                            album.cover != null &&
                                                album.cover!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(12),
                                                    ),
                                                child: Image.file(
                                                  File(album.cover!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 48,
                                                        ),
                                                      ),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          12,
                                                        ),
                                                      ),
                                                ),
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 48,
                                                ),
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              album.name ?? 'Unknown Album',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Consumer(
                                              builder: (context, ref, _) {
                                                final trackCountAsync = ref
                                                    .watch(
                                                      albumTrackCountProvider(
                                                        album.id!,
                                                      ),
                                                    );
                                                return trackCountAsync.when(
                                                  data: (trackCount) => Text(
                                                    '$trackCount songs',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  loading: () => const Text(
                                                    'Loading...',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  error: (err, stack) =>
                                                      const Text(
                                                        '0 songs',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                // Empty state
                if (displayedTracks.isEmpty && albums.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No content found for this artist',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, String errorMessage) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class ArtistTrackListItem extends StatefulWidget {
  final TrackItem track;
  final List<TrackItem> tracks;
  final int index;
  final VoidCallback onTap;

  const ArtistTrackListItem({
    super.key,
    required this.track,
    required this.tracks,
    required this.index,
    required this.onTap,
  });

  @override
  State<ArtistTrackListItem> createState() => _ArtistTrackListItemState();
}

class _ArtistTrackListItemState extends State<ArtistTrackListItem> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.97;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          widget.onTap();
          await Future.delayed(const Duration(milliseconds: 100));
          setState(() {
            _scale = 1.0;
          });
        },
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppTheme.radiusMd,
            ),
            child: Row(
              children: [
                // Track number
                SizedBox(
                  width: 30,
                  child: Text(
                    '${widget.index + 1}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 16),
                // Track cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.track.cover.isNotEmpty
                      ? Image.file(
                          File(widget.track.cover),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 50,
                                height: 50,
                                color: colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.music_note,
                                  color: colorScheme.primary,
                                ),
                              ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.music_note,
                            color: colorScheme.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Track info
                Expanded(
                  child: Text(
                    widget.track.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // Play icon
                Icon(
                  Icons.play_arrow,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

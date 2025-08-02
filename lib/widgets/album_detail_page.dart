import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';

class AlbumDetailPage extends ConsumerStatefulWidget {
  final AlbumItem album;

  const AlbumDetailPage({Key? key, required this.album}) : super(key: key);

  @override
  ConsumerState<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends ConsumerState<AlbumDetailPage> {
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
        final tracksAsync = ref.watch(tracksByAlbumProvider(widget.album.id!));

        return tracksAsync.when(
          data: (tracks) => _buildContent(context, colorScheme, tracks),
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
                          // Album Cover
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  widget.album.cover != null &&
                                      widget.album.cover!.isNotEmpty
                                  ? Image.file(
                                      File(widget.album.cover!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[800],
                                                child: Icon(
                                                  Icons.album,
                                                  size: 80,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.album,
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
                        // Album Name
                        Text(
                          widget.album.name ?? 'Unknown Album',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Artist Name
                        Text(
                          widget.album.artistName ?? 'Unknown Artist',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Track count
                        Text(
                          '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
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
                // Songs List
                if (tracks.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final track = tracks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: AlbumTrackListItem(
                          track: track,
                          tracks: tracks,
                          index: index,
                          onTap: () => _playTrack(track, tracks, index),
                        ),
                      );
                    }, childCount: tracks.length),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No songs found in this album',
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

class AlbumTrackListItem extends StatefulWidget {
  final TrackItem track;
  final List<TrackItem> tracks;
  final int index;
  final VoidCallback onTap;

  const AlbumTrackListItem({
    Key? key,
    required this.track,
    required this.tracks,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AlbumTrackListItem> createState() => _AlbumTrackListItemState();
}

class _AlbumTrackListItemState extends State<AlbumTrackListItem> {
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
                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.track.artist,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                // Play icon (optional)
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

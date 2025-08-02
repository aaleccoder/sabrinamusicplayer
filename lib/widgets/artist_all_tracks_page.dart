import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/artists.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';

class ArtistAllTracksPage extends ConsumerStatefulWidget {
  final ArtistItem artist;

  const ArtistAllTracksPage({Key? key, required this.artist}) : super(key: key);

  @override
  ConsumerState<ArtistAllTracksPage> createState() =>
      _ArtistAllTracksPageState();
}

class _ArtistAllTracksPageState extends ConsumerState<ArtistAllTracksPage> {
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
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artist.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tracks.length} songs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Artist cover (smaller version)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: widget.artist.cover.isNotEmpty
                              ? Image.file(
                                  File(widget.artist.cover),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[800],
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: colorScheme.primary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Songs by',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                    ),
                              ),
                              Text(
                                widget.artist.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // All Tracks List
                if (tracks.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final track = tracks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: AllTracksListItem(
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
                          'No songs found for this artist',
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
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    widget.artist.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
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
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    widget.artist.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
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

class AllTracksListItem extends StatefulWidget {
  final TrackItem track;
  final List<TrackItem> tracks;
  final int index;
  final VoidCallback onTap;

  const AllTracksListItem({
    Key? key,
    required this.track,
    required this.tracks,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AllTracksListItem> createState() => _AllTracksListItemState();
}

class _AllTracksListItemState extends State<AllTracksListItem> {
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

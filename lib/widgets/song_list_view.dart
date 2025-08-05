import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/home_scan_banner.dart';
import 'package:flutter_application_1/widgets/search_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SortOption {
  alphabeticalAZ,
  alphabeticalZA,
  album,
  artist,
  year,
  dateAdded,
}

final sortOptionProvider = StateProvider<SortOption>(
  (ref) => SortOption.alphabeticalAZ,
);

class TrackItem {
  int id;
  String title;
  String artist;
  int? artistID;
  String? album;
  int? albumID;
  String cover;
  String fullCover;
  String fileuri;
  String? genre;
  String? lyrics;
  int? genreID;
  bool liked;
  bool unliked;
  String? year;
  DateTime createdAt;

  TrackItem({
    this.genreID,
    this.genre,
    this.albumID,
    this.artistID,
    required this.fullCover,
    required this.unliked,
    required this.liked,
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.cover,
    required this.fileuri,
    this.year,
    required this.createdAt,
  });
}

class SongListView extends ConsumerWidget {
  const SongListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOption = ref.watch(sortOptionProvider);
    final tracksAsync = ref.watch(tracksProvider(sortOption));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section with scan banner and search
            HomeScanBanner(),

            // Search bar with proper padding
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: const SearchBarWidget(),
            ),

            // Songs list
            Expanded(child: _buildSongsList(context, ref, tracksAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithOptions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TrackItem>> tracksAsync,
  ) {
    final sortOption = ref.watch(sortOptionProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          tracksAsync.when(
            data: (tracks) {
              if (tracks.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () {
                  ref
                      .read(audioPlayerNotifierProvider.notifier)
                      .playAllShuffled(tracks);
                },
                icon: Icon(Icons.shuffle, color: AppTheme.primary, size: 16),
                label: Text(
                  'Shuffle Play',
                  style: TextStyle(color: AppTheme.primary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
          DropdownButton<SortOption>(
            value: sortOption,
            onChanged: (SortOption? newValue) {
              if (newValue != null) {
                ref.read(sortOptionProvider.notifier).state = newValue;
              }
            },
            items: SortOption.values.map((SortOption option) {
              return DropdownMenuItem<SortOption>(
                value: option,
                child: Text(
                  _getSortOptionName(option),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSortOptionName(SortOption option) {
    switch (option) {
      case SortOption.alphabeticalAZ:
        return 'Alphabetical (A-Z)';
      case SortOption.alphabeticalZA:
        return 'Alphabetical (Z-A)';
      case SortOption.album:
        return 'Album';
      case SortOption.artist:
        return 'Artist';
      case SortOption.year:
        return 'Year';
      case SortOption.dateAdded:
        return 'Date Added';
    }
  }

  Widget _buildSongCountHeader(
    BuildContext context,
    AsyncValue<List<TrackItem>> tracksAsync,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 1),
      ),
      child: tracksAsync.when(
        data: (tracks) => Text(
          '${tracks.length} song${tracks.length != 1 ? 's' : ''} available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: AppTheme.textTheme.bodySmall?.fontSize,
            color: AppTheme.onSurface.withOpacity(0.7),
          ),
        ),
        loading: () => Text(
          'Loading your music...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: AppTheme.textTheme.bodySmall?.fontSize,
            color: AppTheme.onSurface.withOpacity(0.7),
          ),
        ),
        error: (e, _) => Text(
          'Error loading music',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: AppTheme.textTheme.bodySmall?.fontSize,
            color: AppTheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildSongsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TrackItem>> tracksAsync,
  ) {
    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return _buildEmptyState(context);
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeaderWithOptions(context, ref, tracksAsync),
            ),
            SliverToBoxAdapter(
              child: _buildSongCountHeader(context, tracksAsync),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final itemIndex = index ~/ 2;
                  if (index.isEven) {
                    return SongListViewItem(
                      track: tracks[itemIndex],
                      tracks: tracks,
                      index: itemIndex,
                    );
                  }
                  return const SizedBox(height: 8);
                }, childCount: math.max(0, tracks.length * 2 - 1)),
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading your music...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) *
                    0.6,
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading music',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) *
                    0.6,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) *
                    0.6,
                color: AppTheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.library_music_outlined,
                size: 38,
                color: AppTheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No songs found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.headlineSmall?.fontSize ??
                        24) *
                    0.6,
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add music folders in Settings to get started with your music library',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) *
                    0.6,
                color: AppTheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to settings
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SongListViewItem extends ConsumerStatefulWidget {
  final TrackItem track;
  final List<TrackItem> tracks;
  final int index;

  const SongListViewItem({
    super.key,
    required this.track,
    required this.tracks,
    required this.index,
  });

  @override
  _SongListViewItemState createState() => _SongListViewItemState();
}

class _SongListViewItemState extends ConsumerState<SongListViewItem> {
  double _scale = 1.0;

  void playerStatus(WidgetRef ref, TrackItem track) async {
    setState(() {
      _scale = 0.98;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _scale = 1.0;
    });
    final musicPlayer = ref.read(audioPlayerNotifierProvider.notifier);
    final queue = widget.tracks.sublist(widget.index);
    await musicPlayer.createQueue(queue);
    await musicPlayer.play(track);
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
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          playerStatus(ref, widget.track);
        },
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.radiusMd,
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _buildAlbumArt(),
                ),
                const SizedBox(width: 10),

                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: AppTheme.textTheme.bodyMedium?.fontSize,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.track.artist,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                          color: AppTheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),

                // Menu button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton(
                    icon: Icon(
                      CupertinoIcons.ellipsis,
                      color: AppTheme.primary,
                      size: 12,
                    ),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'like',
                            child: Row(
                              children: [
                                Icon(
                                  widget.track.liked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                SizedBox(width: 8),
                                Text(widget.track.liked ? 'Unlike' : 'Like'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'unlike',
                            child: Row(
                              children: [
                                Icon(
                                  widget.track.unliked
                                      ? Icons.thumb_down
                                      : Icons.thumb_down_alt_outlined,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  widget.track.unliked
                                      ? 'Remove Unlike'
                                      : 'Unlike',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'add_to_playlist',
                            child: Row(
                              children: [
                                Icon(Icons.playlist_add),
                                SizedBox(width: 8),
                                Text('Add to Playlist'),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) async {
                      final db = ref.read(appDatabaseProvider);
                      switch (value) {
                        case 'like':
                          await db.updateTrack(
                            widget.track..liked = !widget.track.liked,
                          );
                          break;
                        case 'unlike':
                          await db.updateTrack(
                            widget.track..unliked = !widget.track.unliked,
                          );
                          break;
                        case 'add_to_playlist':
                          _showAddToPlaylistDialog(context, widget.track);
                          break;
                      }
                      final currentSortOption = ref.read(sortOptionProvider);
                      ref.refresh(tracksProvider(currentSortOption));
                      ref.refresh(likedTracksProvider);
                      ref.refresh(unlikedTracksProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    if (widget.track.cover.isNotEmpty) {
      final coverUri = Uri.tryParse(widget.track.cover);
      if (coverUri != null && coverUri.isScheme('file')) {
        return Image.file(
          File.fromUri(coverUri),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderAlbumArt();
          },
        );
      }
    }
    return _buildPlaceholderAlbumArt();
  }

  Widget _buildPlaceholderAlbumArt() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note, color: AppTheme.primary, size: 24),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, TrackItem track) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final playlistsAsync = ref.watch(playlistsProvider);
          return playlistsAsync.when(
            data: (playlists) => AlertDialog(
              title: const Text('Add to Playlist'),
              content: playlists.isEmpty
                  ? const Text(
                      'No playlists available. Create a playlist first.',
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return ListTile(
                            leading: const Icon(Icons.queue_music, size: 14),
                            title: Text(
                              playlist.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize:
                                        (Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.fontSize ??
                                            14) *
                                        0.6,
                                  ),
                            ),
                            subtitle: playlist.description != null
                                ? Text(
                                    playlist.description!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.fontSize ??
                                                  12) *
                                              0.6,
                                        ),
                                  )
                                : null,
                            onTap: () async {
                              try {
                                await ref
                                    .read(appDatabaseProvider)
                                    .addTrackToPlaylist(playlist.id, track.id);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added "${track.title}" to "${playlist.name}"',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize:
                                                (Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.fontSize ??
                                                    14) *
                                                0.6,
                                          ),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error: ${e.toString()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize:
                                                (Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.fontSize ??
                                                    14) *
                                                0.6,
                                          ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            loading: () => const AlertDialog(
              title: Text('Add to Playlist'),
              content: CircularProgressIndicator(),
            ),
            error: (err, stack) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load playlists: $err'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

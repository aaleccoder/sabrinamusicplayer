import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/home_scan_banner.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_application_1/widgets/search_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackItem {
  final int id;
  final String title;
  final String artist;
  final String cover;
  final String fileuri;

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
    required this.fileuri,
  });
}

class SongListView extends ConsumerWidget {
  const SongListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);

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

            // Song count header
            _buildSongCountHeader(context, tracksAsync),

            // Songs list
            Expanded(child: _buildSongsList(context, tracksAsync)),
          ],
        ),
      ),
    );
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
        data: (tracks) => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.library_music,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Music Library',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tracks.length} song${tracks.length != 1 ? 's' : ''} available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading your music...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        error: (e, _) => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.error_outline, size: 16, color: AppTheme.error),
            ),
            const SizedBox(width: 12),
            Text(
              'Error loading music',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList(
    BuildContext context,
    AsyncValue<List<TrackItem>> tracksAsync,
  ) {
    return tracksAsync.when(
      data: (tracks) =>
          tracks.isEmpty ? _buildEmptyState(context) : _buildTracksList(tracks),
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your music...'),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                size: 64,
                color: AppTheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No songs found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add music folders in Settings to get started with your music library',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildTracksList(List<TrackItem> tracks) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: tracks.length,
      itemBuilder: (context, index) =>
          SongListViewItem(track: tracks[index], tracks: tracks, index: index),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
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
    final musicPlayer = ref.watch(audioPlayerNotifierProvider.notifier);
    final queue = widget.tracks.sublist(widget.index);
    await musicPlayer.createQueue(queue);
    musicPlayer.play(track);
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.radiusMd,
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildAlbumArt(),
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
                            ?.copyWith(
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
                      size: 20,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
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
                    onSelected: (value) {
                      if (value == 'add_to_playlist') {
                        _showAddToPlaylistDialog(context, widget.track);
                      }
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
    try {
      if (widget.track.cover.isNotEmpty) {
        final coverUri = Uri.parse(widget.track.cover);
        if (coverUri.isScheme('file')) {
          final file = File.fromUri(coverUri);
          if (file.existsSync()) {
            return Image.file(file, width: 56, height: 56, fit: BoxFit.cover);
          }
        }
      }
    } catch (e) {
      // Fall back to placeholder
    }

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
                            leading: const Icon(Icons.queue_music),
                            title: Text(playlist.name),
                            subtitle: playlist.description != null
                                ? Text(playlist.description!)
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
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
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

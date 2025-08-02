import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
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

    return Padding(
      padding: AppTheme.paddingSm,
      child: tracksAsync.when(
        data: (tracks) => ListView.separated(
          itemCount: tracks.length,
          itemBuilder: (context, index) => SongListViewItem(
            track: tracks[index],
            tracks: tracks,
            index: index,
          ),
          separatorBuilder: (context, index) =>
              const Divider(height: 10, color: Colors.transparent),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
      _scale = 0.97; // Scale down on tap
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _scale = 1.0; // Reset scale after tap
    });
    final musicPlayer = ref.watch(audioPlayerNotifierProvider.notifier);
    final queue = widget.tracks.sublist(widget.index);
    await musicPlayer.createQueue(queue);
    musicPlayer.play(track);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0; // Scale back to normal on tap up
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0; // Reset scale if tap is canceled
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppTheme.radiusMd,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: File(widget.track.cover).existsSync()
                      ? Image.file(
                          File(widget.track.cover),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.track.title,
                        style: Theme.of(context).textTheme.titleMedium,
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
                PopupMenuButton(
                  icon: Icon(
                    CupertinoIcons.ellipsis,
                    color: colorScheme.onSurface,
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
              ],
            ),
          ),
        ),
      ),
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

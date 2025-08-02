import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/track_search_page.dart';
import 'package:flutter_application_1/widgets/mini_player.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';
import 'package:image_picker/image_picker.dart';

class PlaylistDetailPage extends ConsumerStatefulWidget {
  final PlaylistItem playlist;

  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
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
        final tracksAsync = ref.watch(
          playlistTracksProvider(widget.playlist.id),
        );

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
                  actions: [
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit Playlist'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'add_tracks',
                          child: Row(
                            children: [
                              Icon(Icons.library_add),
                              SizedBox(width: 8),
                              Text('Add Tracks'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'change_cover',
                          child: Row(
                            children: [
                              Icon(Icons.image),
                              SizedBox(width: 8),
                              Text('Change Cover'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditPlaylistDialog(context);
                        } else if (value == 'add_tracks') {
                          _navigateToAddTracks();
                        } else if (value == 'change_cover') {
                          _showCoverImagePicker();
                        }
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: const EdgeInsets.only(
                        top: 80,
                        left: 20,
                        right: 20,
                      ),
                      child: Column(
                        children: [
                          // Playlist Cover
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  widget.playlist.coverImage != null &&
                                      widget.playlist.coverImage!.isNotEmpty
                                  ? Image.file(
                                      File(widget.playlist.coverImage!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildDefaultCover(colorScheme),
                                    )
                                  : _buildDefaultCover(colorScheme),
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
                        // Playlist Name
                        Text(
                          widget.playlist.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Description
                        if (widget.playlist.description != null)
                          Text(
                            widget.playlist.description!,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        const SizedBox(height: 8),
                        // Track count and controls
                        Row(
                          children: [
                            Text(
                              '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _navigateToAddTracks,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Songs'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Tracks List
                if (tracks.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final track = tracks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: PlaylistTrackListItem(
                          track: track,
                          tracks: tracks,
                          index: index,
                          playlist: widget.playlist,
                          onTap: () => _playTrack(track, tracks, index),
                          onRemove: () => _removeTrackFromPlaylist(track),
                        ),
                      );
                    }, childCount: tracks.length),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.queue_music,
                            size: 64,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No songs in this playlist',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some tracks to get started',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _navigateToAddTracks,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Songs'),
                          ),
                        ],
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

  Widget _buildDefaultCover(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary.withOpacity(0.8), colorScheme.primary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.queue_music, size: 80, color: Colors.white),
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

  void _navigateToAddTracks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackSearchPage(playlist: widget.playlist),
      ),
    ).then((_) {
      // Refresh the playlist tracks when returning
      ref.invalidate(playlistTracksProvider(widget.playlist.id));
    });
  }

  void _removeTrackFromPlaylist(TrackItem track) async {
    try {
      await ref
          .read(appDatabaseProvider)
          .removeTrackFromPlaylist(widget.playlist.id, track.id);
      ref.invalidate(playlistTracksProvider(widget.playlist.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "${track.title}" from playlist')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditPlaylistDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.playlist.name);
    final descriptionController = TextEditingController(
      text: widget.playlist.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'Enter playlist name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await ref
                    .read(appDatabaseProvider)
                    .updatePlaylist(
                      widget.playlist.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                ref.invalidate(playlistsProvider);
                Navigator.of(context).pop();
                // Update the current playlist data
                setState(() {
                  widget.playlist.name = nameController.text.trim();
                  widget.playlist.description =
                      descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim();
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCoverImagePicker() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  _updatePlaylistCover(image.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  _updatePlaylistCover(image.path);
                }
              },
            ),
            if (widget.playlist.coverImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Cover',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updatePlaylistCover(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _updatePlaylistCover(String? imagePath) async {
    try {
      await ref
          .read(appDatabaseProvider)
          .updatePlaylist(widget.playlist.id, coverImage: imagePath);
      ref.invalidate(playlistsProvider);
      setState(() {
        widget.playlist.coverImage = imagePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(imagePath != null ? 'Cover updated' : 'Cover removed'),
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
  }
}

class PlaylistTrackListItem extends StatefulWidget {
  final TrackItem track;
  final List<TrackItem> tracks;
  final int index;
  final PlaylistItem playlist;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const PlaylistTrackListItem({
    super.key,
    required this.track,
    required this.tracks,
    required this.index,
    required this.playlist,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<PlaylistTrackListItem> createState() => _PlaylistTrackListItemState();
}

class _PlaylistTrackListItemState extends State<PlaylistTrackListItem> {
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
                // Remove button
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Remove from Playlist',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'remove') {
                      widget.onRemove();
                    }
                  },
                  child: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/playlists.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackSearchPage extends ConsumerStatefulWidget {
  final PlaylistItem? playlist;

  const TrackSearchPage({super.key, this.playlist});

  @override
  ConsumerState<TrackSearchPage> createState() => _TrackSearchPageState();
}

class _TrackSearchPageState extends ConsumerState<TrackSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedTrackIds = <int>{};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playlist != null
              ? 'Add to ${widget.playlist!.name}'
              : 'Select Tracks',
        ),
        centerTitle: true,
        actions: [
          if (_selectedTrackIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: () => _showPlaylistSelectionDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tracks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Selection Summary
          if (_selectedTrackIds.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedTrackIds.length} track(s) selected',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedTrackIds.clear();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: widget.playlist != null
                            ? _addSelectedTracksToPlaylist
                            : _showPlaylistSelectionDialog,
                        child: Text(
                          widget.playlist != null ? 'Add' : 'Add to Playlist',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Track List
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                late AsyncValue<List<TrackItem>> tracksAsync;

                if (_searchQuery.isNotEmpty) {
                  tracksAsync = ref.watch(searchTracksProvider(_searchQuery));
                } else {
                  tracksAsync = ref.watch(
                    tracksProvider(SortOption.alphabeticalAZ),
                  );
                }

                return tracksAsync.when(
                  data: (tracks) {
                    if (tracks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No tracks found for "$_searchQuery"'
                                  : 'No tracks available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isSelected = _selectedTrackIds.contains(track.id);

                        return Card(
                          elevation: isSelected ? 4 : 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedTrackIds.add(track.id);
                                      } else {
                                        _selectedTrackIds.remove(track.id);
                                      }
                                    });
                                  },
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: track.cover.isNotEmpty
                                      ? Image.file(
                                          File(track.cover),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withOpacity(0.1),
                                                    child: Icon(
                                                      Icons.music_note,
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                    ),
                                                  ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
                                          child: Icon(
                                            Icons.music_note,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            title: Text(
                              track.title,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(track.artist),
                            onTap: () {
                              setState(() {
                                if (_selectedTrackIds.contains(track.id)) {
                                  _selectedTrackIds.remove(track.id);
                                } else {
                                  _selectedTrackIds.add(track.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addSelectedTracksToPlaylist() async {
    if (widget.playlist == null || _selectedTrackIds.isEmpty) return;

    try {
      await ref
          .read(appDatabaseProvider)
          .addTracksToPlaylist(widget.playlist!.id, _selectedTrackIds.toList());

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${_selectedTrackIds.length} track(s) to "${widget.playlist!.name}"',
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
  }

  void _showPlaylistSelectionDialog() {
    if (_selectedTrackIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final playlistsAsync = ref.watch(playlistsProvider);
          return playlistsAsync.when(
            data: (playlists) => AlertDialog(
              title: const Text('Select Playlist'),
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
                                    .addTracksToPlaylist(
                                      playlist.id,
                                      _selectedTrackIds.toList(),
                                    );
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added ${_selectedTrackIds.length} track(s) to "${playlist.name}"',
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
              title: Text('Select Playlist'),
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

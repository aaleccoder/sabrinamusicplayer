import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/playlist_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaylistItem {
  int id;
  String name;
  String? description;
  String? coverImage;
  DateTime createdAt;
  DateTime? updatedAt;

  PlaylistItem({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    required this.createdAt,
    this.updatedAt,
  });
}

class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsState();
}

class _PlaylistsState extends ConsumerState<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final playlistsAsync = ref.watch(playlistsProvider);
          return playlistsAsync.when(
            data: (playlists) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'My Playlists',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreatePlaylistDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: playlists.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.queue_music,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No playlists yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create your first playlist to get started',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              return PlaylistListItem(
                                playlist: playlist,
                                onEdit: () =>
                                    _showEditPlaylistDialog(context, playlist),
                                onDelete: () => _showDeletePlaylistDialog(
                                  context,
                                  playlist,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
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
                    .createPlaylist(
                      nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                ref.invalidate(playlistsProvider);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditPlaylistDialog(BuildContext context, PlaylistItem playlist) {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController = TextEditingController(
      text: playlist.description ?? '',
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
                      playlist.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                ref.invalidate(playlistsProvider);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(BuildContext context, PlaylistItem playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(appDatabaseProvider).deletePlaylist(playlist.id);
              ref.invalidate(playlistsProvider);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class PlaylistListItem extends ConsumerWidget {
  final PlaylistItem playlist;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlaylistListItem({
    super.key,
    required this.playlist,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackCountAsync = ref.watch(playlistTrackCountProvider(playlist.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.shadowLg,
        color: AppTheme.surface,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: AppTheme.radiusMd,
          ),
          child: Icon(Icons.queue_music, color: AppTheme.primary),
        ),
        title: Text(
          playlist.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: AppTheme.textTheme.bodyMedium?.fontSize,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        subtitle: playlist.description != null
            ? Text(
                playlist.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                  color: AppTheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : trackCountAsync.when(
                data: (count) => Text(
                  '$count songs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                    color: AppTheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                    color: AppTheme.onSurface.withOpacity(0.7),
                  ),
                ),
                error: (err, stack) => Text(
                  '0 songs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                    color: AppTheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
        ),
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

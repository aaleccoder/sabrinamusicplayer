import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/album_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlbumItem {
  int? id;
  String? name;
  String? cover;
  String? artistName;
  int? artistId;
  List<TrackItem>? tracks;
  int? playCount;

  AlbumItem({
    this.playCount,
    required this.id,
    required this.name,
    required this.cover,
    required this.artistName,
    this.artistId,
    required this.tracks,
  });
}

class AlbumsPage extends ConsumerStatefulWidget {
  const AlbumsPage({super.key});

  @override
  ConsumerState<AlbumsPage> createState() => _AlbumsState();
}

class _AlbumsState extends ConsumerState<AlbumsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final albumsAsync = ref.watch(
            albumsProvider(PaginationState(page: 0)),
          );
          return albumsAsync.when(
            data: (albums) {
              if (albums.isEmpty) {
                return const Center(child: Text('No albums found'));
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return AlbumGridItem(album: album);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
      ),
    );
  }
}

class AlbumGridItem extends StatelessWidget {
  final AlbumItem album;
  final int? count;

  const AlbumGridItem({super.key, required this.album, this.count});

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusXl,
          // boxShadow: AppTheme.shadowLg, // Removed for performance
          color: AppTheme.surface,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildAlbumArt()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name ?? 'Unknown Album',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTheme.textTheme.bodyMedium?.fontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.artistName ?? 'Unknown Artist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                      color: AppTheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    if (album.cover != null && album.cover!.isNotEmpty) {
      final coverUri = Uri.tryParse(album.cover!);
      if (coverUri != null && coverUri.isScheme('file')) {
        return Image.file(
          File.fromUri(coverUri),
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
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Icon(Icons.image, size: 48, color: AppTheme.primary),
    );
  }
}

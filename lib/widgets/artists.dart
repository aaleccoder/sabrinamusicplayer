import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/artist_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtistItem {
  int id;
  String name;
  String cover;
  List<TrackItem>? tracks;
  List<AlbumItem>? albums;
  int playCount;

  ArtistItem({
    required this.id,
    required this.name,
    required this.cover,
    required this.tracks,
    required this.albums,
    this.playCount = 0,
  });
}

class ArtistsPage extends ConsumerStatefulWidget {
  const ArtistsPage({super.key});

  @override
  ConsumerState<ArtistsPage> createState() => _ArtistsState();
}

class _ArtistsState extends ConsumerState<ArtistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final artistsAsync = ref.watch(
            artistsProvider(PaginationState(page: 0)),
          );
          return artistsAsync.when(
            data: (artists) {
              if (artists.isEmpty) {
                return const Center(child: Text('No artists found'));
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
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return ArtistGridItem(artist: artist);
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

class ArtistGridItem extends ConsumerWidget {
  final ArtistItem artist;

  const ArtistGridItem({super.key, required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailPage(artist: artist),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusXl,
          color: AppTheme.surface,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: _buildArtistImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTheme.textTheme.bodyMedium?.fontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildArtistStats(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistImage() {
    if (artist.cover.isNotEmpty) {
      final coverUri = Uri.tryParse(artist.cover);
      if (coverUri != null && coverUri.isScheme('file')) {
        return Image.file(
          File.fromUri(coverUri),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1)),
      child: Icon(Icons.person, size: 48, color: AppTheme.primary),
    );
  }

  Widget _buildArtistStats(BuildContext context, WidgetRef ref) {
    final trackCountAsync = ref.watch(artistTrackCountProvider(artist.id));
    final albumCountAsync = ref.watch(artistAlbumCountProvider(artist.id));

    return trackCountAsync.when(
      data: (trackCount) {
        return albumCountAsync.when(
          data: (albumCount) {
            return Text(
              '$trackCount songs • $albumCount albums',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: AppTheme.textTheme.bodySmall?.fontSize,
                color: AppTheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          loading: () => Text(
            'Loading...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: AppTheme.textTheme.bodySmall?.fontSize,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
          error: (err, stack) => Text(
            '0 albums',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: AppTheme.textTheme.bodySmall?.fontSize,
              color: AppTheme.onSurface.withOpacity(0.7),
            ),
          ),
        );
      },
      loading: () => Text(
        'Loading...',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: AppTheme.textTheme.bodySmall?.fontSize,
          color: AppTheme.onSurface.withOpacity(0.7),
        ),
      ),
      error: (err, stack) => Text(
        '0 songs • 0 albums',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: AppTheme.textTheme.bodySmall?.fontSize,
          color: AppTheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

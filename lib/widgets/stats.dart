import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/album_detail_page.dart';
import 'package:flutter_application_1/widgets/albums.dart';
import 'package:flutter_application_1/widgets/artist_detail_page.dart';
import 'package:flutter_application_1/widgets/artists.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Stats extends ConsumerStatefulWidget {
  const Stats({super.key});

  @override
  ConsumerState<Stats> createState() => _StatsState();
}

class _StatsState extends ConsumerState<Stats> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 180.0),
        children: const [
          QuickTrackSection(),
          SizedBox(height: 16),
          TopAlbumsSection(),
          SizedBox(height: 16),
          TopArtistsSection(),
          SizedBox(height: 16),
          TopGenresSection(),
        ],
      ),
    );
  }
}

class QuickTrackSection extends ConsumerWidget {
  const QuickTrackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackPlaysAsync = ref.watch(trackPlaysProvider);
    return trackPlaysAsync.when(
      data: (trackPlays) {
        if (trackPlays.isEmpty) {
          return const Center(child: Text('No track plays found'));
        }
        final tracks = trackPlays;
        return CustomCard(
          title: 'Top Played Tracks',
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tracks.length.clamp(0, 5),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return SongListViewItem(
                track: tracks[index],
                tracks: tracks,
                index: index,
                count: tracks[index].playCount,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading track plays: $error')),
    );
  }
}

class TopAlbumsSection extends ConsumerWidget {
  const TopAlbumsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsPlaysAsync = ref.watch(albumsPlaysProvider);
    return albumsPlaysAsync.when(
      data: (albumPlays) {
        if (albumPlays.isEmpty) {
          return const Center(child: Text('No album plays found'));
        }
        final albums = albumPlays;
        return CustomCard(
          title: 'Top Played Albums',
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: albums.length.clamp(0, 5),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return AlbumStatItem(
                album: albums[index],
                count: albums[index].playCount,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading album plays: $error')),
    );
  }
}

class TopArtistsSection extends ConsumerWidget {
  const TopArtistsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsPlaysAsync = ref.watch(artistsPlaysProvider);
    return artistsPlaysAsync.when(
      data: (artistPlays) {
        if (artistPlays.isEmpty) {
          return const Center(child: Text('No artist plays found'));
        }
        final artists = artistPlays;
        return CustomCard(
          title: 'Top Played Artists',
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: artists.length.clamp(0, 5),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return ArtistStatItem(
                artist: artists[index],
                count: artists[index].playCount,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading artist plays: $error')),
    );
  }
}

class TopGenresSection extends ConsumerWidget {
  const TopGenresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresPlaysAsync = ref.watch(genrePlaysProvider);
    return genresPlaysAsync.when(
      data: (genrePlays) {
        final validGenres = genrePlays
            .where((genre) => genre.playCount > 0)
            .toList();
        if (validGenres.isEmpty) {
          return const Center(child: Text('No genre plays found'));
        }
        final genres = validGenres.take(5).toList();
        return CustomCard(
          title: 'Top Played Genres',
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List.generate(genres.length, (index) {
                  final genre = genres[index];
                  final isTouched =
                      index == -1; // Placeholder for touch interaction
                  final fontSize = isTouched ? 16.0 : 14.0;
                  final radius = isTouched ? 60.0 : 50.0;
                  return PieChartSectionData(
                    color: Colors.primaries[index % Colors.primaries.length],
                    value: genre.playCount.toDouble(),
                    title: '${genre.name}\n(${genre.playCount})',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffffffff),
                    ),
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading genre plays: $error')),
    );
  }
}

class AlbumStatItem extends StatelessWidget {
  final AlbumItem album;
  final int? count;

  const AlbumStatItem({super.key, required this.album, this.count});

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
      child: Row(
        children: [
          SizedBox(width: 60, height: 60, child: _buildAlbumArt()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.name ?? 'Unknown Album',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  album.artistName ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (count != null)
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    if (album.cover != null && album.cover!.isNotEmpty) {
      final coverUri = Uri.tryParse(album.cover!);
      if (coverUri != null && coverUri.isScheme('file')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.file(
            File.fromUri(coverUri),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderAlbumArt();
            },
          ),
        );
      }
    }
    return _buildPlaceholderAlbumArt();
  }

  Widget _buildPlaceholderAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Icon(Icons.music_note, size: 32, color: AppTheme.primary),
    );
  }
}

class ArtistStatItem extends StatelessWidget {
  final ArtistItem artist;
  final int? count;

  const ArtistStatItem({super.key, required this.artist, this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailPage(artist: artist),
          ),
        );
      },
      child: Row(
        children: [
          SizedBox(width: 60, height: 60, child: _buildArtistImage()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (count != null)
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      ),
    );
  }

  Widget _buildArtistImage() {
    if (artist.cover.isNotEmpty) {
      final coverUri = Uri.tryParse(artist.cover);
      if (coverUri != null && coverUri.isScheme('file')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: Image.file(
            File.fromUri(coverUri),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: const Icon(Icons.person, size: 32, color: AppTheme.primary),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;

  const CustomCard({
    super.key,
    required this.title,
    required this.child,
    this.padding,
    this.color,
    this.elevation,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: shape,
      color: color,
      elevation: elevation ?? 2.0,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

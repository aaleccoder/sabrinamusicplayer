import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/genre_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenreItem {
  int id;
  String name;

  GenreItem({required this.id, required this.name});
}

class GenresPage extends ConsumerStatefulWidget {
  const GenresPage({super.key});

  @override
  ConsumerState<GenresPage> createState() => _GenresState();
}

class _GenresState extends ConsumerState<GenresPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final genresAsync = ref.watch(genresProvider);
          return genresAsync.when(
            data: (genres) {
              if (genres.isEmpty) {
                return const Center(child: Text('No genres found'));
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
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return GenreGridItem(genre: genre);
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

class GenreGridItem extends ConsumerWidget {
  final GenreItem genre;

  const GenreGridItem({super.key, required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenreDetailPage(genre: genre),
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
              child: Container(
                decoration: BoxDecoration(
                  color: _getGenreColor(genre.name).withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 32,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    genre.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTheme.textTheme.bodyMedium?.fontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildGenreStats(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreStats(BuildContext context, WidgetRef ref) {
    debugPrint('Building genre stats for genre: ${genre.name}');
    final trackCountAsync = ref.watch(genreTrackCountProvider(genre.id));
    return trackCountAsync.when(
      data: (trackCount) => Text(
        '$trackCount songs',
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
    );
  }

  Color _getGenreColor(String genreName) {
    // Generate a color based on genre name
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
    ];

    final hash = genreName.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

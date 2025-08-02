import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_application_1/widgets/genre_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenreItem {
  int id;
  String name;

  GenreItem({required this.id, required this.name});
}

class GenresPage extends ConsumerStatefulWidget {
  const GenresPage({Key? key}) : super(key: key);

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
                padding: const EdgeInsets.all(0.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenreDetailPage(genre: genre),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _getGenreColor(
                                        genre.name,
                                      ).withOpacity(0.8),
                                      _getGenreColor(genre.name),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    genre.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final trackCountAsync = ref.watch(
                                        genreTrackCountProvider(genre.id),
                                      );

                                      return trackCountAsync.when(
                                        data: (trackCount) {
                                          return Text(
                                            '$trackCount songs',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                        loading: () => const Text(
                                          'Loading...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        error: (err, stack) => const Text(
                                          '0 songs',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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

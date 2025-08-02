import 'dart:io';

import 'package:flutter/material.dart';
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

  ArtistItem({
    required this.id,
    required this.name,
    required this.cover,
    required this.tracks,
    required this.albums,
  });
}

class ArtistsPage extends ConsumerStatefulWidget {
  const ArtistsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ArtistsPage> createState() => _ArtistsState();
}

class _ArtistsState extends ConsumerState<ArtistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final artistsAsync = ref.watch(artistsProvider);
          return artistsAsync.when(
            data: (artists) {
              if (artists.isEmpty) {
                return const Center(child: Text('No artists found'));
              }
              return Padding(
                padding: const EdgeInsets.all(0.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ArtistDetailPage(artist: artist),
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
                              child: artist.cover.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.file(
                                        File(artist.cover),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 48,
                                                  ),
                                                ),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                      ),
                                      child: const Icon(Icons.person, size: 48),
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
                                    artist.name,
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
                                        artistTrackCountProvider(artist.id),
                                      );
                                      final albumCountAsync = ref.watch(
                                        artistAlbumCountProvider(artist.id),
                                      );

                                      return trackCountAsync.when(
                                        data: (trackCount) {
                                          return albumCountAsync.when(
                                            data: (albumCount) {
                                              return Text(
                                                '$trackCount songs • $albumCount albums',
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
                                              '0 albums',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
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
                                          '0 songs • 0 albums',
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
}

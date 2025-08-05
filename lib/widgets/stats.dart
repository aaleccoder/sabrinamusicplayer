import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackStat {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String coverImage;
  final String fileuri;
  final DateTime playedAt;

  TrackStat({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverImage,
    required this.fileuri,
    required this.playedAt,
  });
}

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
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add some logging to see when this builds
            Builder(
              builder: (context) {
                print("Stats widget building");
                return const SizedBox.shrink();
              },
            ),
            const Expanded(child: QuickTrackSection()),
          ],
        ),
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
      data: (trackPlays) => _buildQuickTrackSection(trackPlays, context),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading track plays: $error')),
    );
  }
}

Widget _buildQuickTrackSection(
  List<TrackStat> trackPlays,
  BuildContext context,
) {
 // Add some logging to see when this builds
 print("Building quick track section with ${trackPlays.length} tracks");
 if (trackPlays.isEmpty) {
   return const Center(child: Text("No recent tracks"));
 }
 return ListView.builder(
   itemCount: trackPlays.length > 5 ? 5 : trackPlays.length,
   itemBuilder: (context, index) {
     final track = trackPlays[index];
     return ListTile(
       leading: Image.network(track.coverImage),
       title: Text(track.title),
       subtitle: Text('${track.artist} - ${track.album}'),
       trailing: Text(track.playedAt.toString()),
     );
   },
 );
}

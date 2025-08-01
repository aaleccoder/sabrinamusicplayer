import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerNotifierProvider.notifier);
    final audioState = ref.watch(audioPlayerNotifierProvider);
    final currentTrack = audioState.currentTrack;

    return Scaffold(
      appBar: AppBar(title: Text(currentTrack?.title ?? 'Now Playing')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (currentTrack != null) ...[
              Text('Artist: ${currentTrack.artist}'),
              Text('Title: ${currentTrack.title}'),
            ] else
              Text('No track is currently playing.'),
            ElevatedButton(
              onPressed: () => audioService.play(currentTrack!),
              child: const Text('Play'),
            ),
            ElevatedButton(
              onPressed: () => audioService.pause(),
              child: const Text('Pause'),
            ),
            ElevatedButton(
              onPressed: () => audioService.stop(),
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}

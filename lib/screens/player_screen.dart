import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerNotifierProvider.notifier);
    final audioState = ref.watch(audioPlayerNotifierProvider);
    final currentTrack = audioState.currentTrack;

    return GestureDetector(
      onVerticalDragUpdate: (_) {
        Navigator.pop(context);
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentTrack != null) ...[
                Hero(
                  tag: 'player-artwork',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: File(currentTrack.cover).existsSync()
                        ? Image.file(
                            File(currentTrack.cover),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.music_note,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
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
      ),
    );
  }
}

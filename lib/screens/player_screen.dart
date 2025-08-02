import 'dart:io';

import 'package:flutter/cupertino.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: currentTrack != null
                    ? Column(
                        key: ValueKey(currentTrack.id),
                        children: [
                          Hero(
                            tag: 'player-artwork',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: File(currentTrack.cover).existsSync()
                                  ? Image.file(
                                      File(currentTrack.cover),
                                      width: 400,
                                      height: 400,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 400,
                                      height: 400,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      child: Icon(
                                        Icons.music_note,
                                        size: 64,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 350,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentTrack.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displayLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentTrack.artist,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Text('No track is currently playing.'),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: audioService.previous,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      fixedSize: Size(80, 80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Icon(CupertinoIcons.backward_fill),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1500),
                    child: audioState.isPlaying
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              iconColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              fixedSize: Size(150, 100),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: audioService.pause,
                            child: Icon(Icons.pause),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              iconColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              fixedSize: Size(100, 100),
                            ),
                            onPressed: audioService.unpause,
                            child: Icon(CupertinoIcons.play_arrow),
                          ),
                  ),
                  ElevatedButton(
                    onPressed: audioService.next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      fixedSize: Size(80, 80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Icon(CupertinoIcons.forward_fill),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

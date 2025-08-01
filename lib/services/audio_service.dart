import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioPlayerState {
  final TrackItem? currentTrack;
  final bool isPlaying;
  final List<TrackItem>? queue;
  final int currentIndex;

  AudioPlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.queue,
    this.currentIndex = 0,
  });

  AudioPlayerState copyWith({
    TrackItem? currentTrack,
    bool? isPlaying,
    List<TrackItem>? queue,
    int? currentIndex,
  }) {
    return AudioPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayerNotifier() : super(AudioPlayerState()) {
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        if (state.queue != null && state.queue!.isNotEmpty) {
          final nextIndex = (state.currentIndex + 1) % state.queue!.length;
          final nextTrack = state.queue![nextIndex];
          _audioPlayer.setFilePath(nextTrack.fileuri);
          _audioPlayer.play();
          state = state.copyWith(
            currentTrack: nextTrack,
            currentIndex: nextIndex,
            isPlaying: true,
          );
        }
      } else {
        state = state.copyWith(isPlaying: _audioPlayer.playing);
      }
    });
  }

  Future<void> createQueue(List<TrackItem> tracks) async {
    if (tracks.isNotEmpty) {
      await _audioPlayer.setFilePath(tracks[0].fileuri);
      state = state.copyWith(
        queue: tracks,
        currentTrack: tracks[0],
        currentIndex: 0,
      );
    }
  }

  Future<void> play(TrackItem track) async {
    if (state.currentTrack?.fileuri == track.fileuri) {
      await _audioPlayer.play();
    } else {
      await _audioPlayer.setFilePath(track.fileuri);
      await _audioPlayer.play();
    }
    state = state.copyWith(currentTrack: track, isPlaying: true);
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = state.copyWith(isPlaying: false, queue: [], currentTrack: null);
  }
}

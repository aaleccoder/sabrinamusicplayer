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
          _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(nextTrack.fileuri)));
          _audioPlayer.play();
          state = state.copyWith(
            currentTrack: nextTrack,
            currentIndex: nextIndex,
          );
        }
      }
    });

    _audioPlayer.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
  }

  Future<void> createQueue(List<TrackItem> tracks) async {
    if (tracks.isNotEmpty) {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(tracks[0].fileuri)));
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
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(track.fileuri)));
      await _audioPlayer.play();
    }
    state = state.copyWith(currentTrack: track);
  }

  Future<void> next() async {
    if (state.queue != null && state.queue!.isNotEmpty) {
      final nextIndex = (state.currentIndex + 1) % state.queue!.length;
      final nextTrack = state.queue![nextIndex];
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(nextTrack.fileuri)));
      await _audioPlayer.play();
      state = state.copyWith(currentTrack: nextTrack, currentIndex: nextIndex);
    }
  }

  Future<void> previous() async {
    if (state.queue != null && state.queue!.isNotEmpty) {
      final previousIndex =
          (state.currentIndex - 1 + state.queue!.length) % state.queue!.length;
      final previousTrack = state.queue![previousIndex];
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(previousTrack.fileuri)));
      await _audioPlayer.play();
      state = state.copyWith(
        currentTrack: previousTrack,
        currentIndex: previousIndex,
      );
    }
  }

  Future<void> unpause() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = state.copyWith(queue: [], currentTrack: null);
  }
}

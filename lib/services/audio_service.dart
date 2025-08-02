import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioPlayerState {
  final TrackItem? currentTrack;
  final bool isPlaying;
  final List<TrackItem>? queue;
  final int currentIndex;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;

  AudioPlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.queue,
    this.currentIndex = 0,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration,
  });

  AudioPlayerState copyWith({
    Object? currentTrack = const Object(),
    bool? isPlaying,
    Object? queue = const Object(),
    int? currentIndex,
    Duration? position,
    Duration? bufferedPosition,
    Object? duration = const Object(),
  }) {
    return AudioPlayerState(
      currentTrack: identical(currentTrack, const Object())
          ? this.currentTrack
          : currentTrack as TrackItem?,
      isPlaying: isPlaying ?? this.isPlaying,
      queue: identical(queue, const Object())
          ? this.queue
          : queue as List<TrackItem>?,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: identical(duration, const Object())
          ? this.duration
          : duration as Duration?,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<TrackItem> _originalQueue = [];

  AudioPlayerNotifier() : super(AudioPlayerState()) {
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        next();
      }
    });

    _audioPlayer.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      state = state.copyWith(bufferedPosition: bufferedPosition);
    });

    _audioPlayer.durationStream.listen((duration) {
      state = state.copyWith(duration: duration);
    });
  }

  Future<void> createQueue(List<TrackItem> tracks) async {
    if (tracks.isNotEmpty) {
      _originalQueue = List.from(tracks);
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(tracks[0].fileuri)),
      );
      state = state.copyWith(
        queue: tracks,
        currentTrack: tracks[0],
        currentIndex: 0,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
      );
    }
  }

  Future<void> play(TrackItem track) async {
    if (state.currentTrack?.fileuri != track.fileuri) {
      state = state.copyWith(currentTrack: track);
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(track.fileuri)),
      );
    }
    await _audioPlayer.play();
  }

  Future<void> next() async {
    if (state.queue != null && state.queue!.isNotEmpty) {
      final nextIndex = (state.currentIndex + 1) % state.queue!.length;
      final nextTrack = state.queue![nextIndex];
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(nextTrack.fileuri)),
      );
      await _audioPlayer.play();
      state = state.copyWith(
        currentTrack: nextTrack,
        currentIndex: nextIndex,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
      );
    }
  }

  Future<void> previous() async {
    if (state.queue != null && state.queue!.isNotEmpty) {
      final previousIndex =
          (state.currentIndex - 1 + state.queue!.length) % state.queue!.length;
      final previousTrack = state.queue![previousIndex];
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(previousTrack.fileuri)),
      );
      await _audioPlayer.play();
      state = state.copyWith(
        currentTrack: previousTrack,
        currentIndex: previousIndex,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
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
    state = state.copyWith(
      position: Duration.zero,
      bufferedPosition: Duration.zero,
    );
  }

  Future<void> clearQueue() async {
    await stop();
    state = state.copyWith(
      queue: [],
      currentTrack: null,
      currentIndex: 0,
      duration: null,
    );
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> playAllShuffled(List<TrackItem> tracks) async {
    if (tracks.isNotEmpty) {
      final shuffledQueue = List<TrackItem>.from(tracks)..shuffle();
      await createQueue(shuffledQueue);
      await play(shuffledQueue[0]);
    }
  }
}

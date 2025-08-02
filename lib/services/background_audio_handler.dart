import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';

/// Custom AudioHandler for background audio playback
class BackgroundAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<MediaItem> _queue = [];
  int _currentIndex = 0;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

  BackgroundAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Configure audio session for music playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to audio player events and update media controls
    _audioPlayer.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _audioPlayer.positionStream.listen((pos) {
      print('[BackgroundAudioHandler] position update: $pos');
    });

    // Handle audio player completion
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });

    // Update queue when it changes
    queue.add(_queue);
  }

  /// Transform AudioPlayer events to AudioService playback state
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_audioPlayer.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        const MediaControl(
          androidIcon: 'drawable/ic_shuffle',
          label: 'Shuffle',
          action: MediaAction.custom,
          customAction: CustomMediaAction(name: 'shuffle'),
        ),
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
      },
      androidCompactActionIndices: const [
        0,
        1,
        2,
      ], // Previous, Play/Pause, Next
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_audioPlayer.processingState]!,
      playing: _audioPlayer.playing,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
      queueIndex: _currentIndex,
      shuffleMode: _shuffleMode,
      repeatMode: _repeatMode,
    );
  }

  /// Convert TrackItem to MediaItem for audio_service
  static MediaItem trackToMediaItem(TrackItem track) {
    return MediaItem(
      id: track.fileuri,
      album: '', // You might want to add album info to TrackItem
      title: track.title,
      artist: track.artist,
      duration: null, // Will be set when audio loads
      artUri: track.cover.isNotEmpty ? Uri.parse(track.cover) : null,
      extras: {'trackId': track.id},
    );
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    _queue.clear();
    _queue.addAll(mediaItems);
    queue.add(_queue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    _queue.clear();
    _queue.addAll(queue);
    this.queue.add(_queue);
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    final index = _queue.indexWhere((item) => item.id == mediaItem.id);
    if (index != -1) {
      _queue[index] = mediaItem;
      queue.add(_queue);
    }
  }

  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    playbackState.add(
      PlaybackState(
        controls: [],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    if (_repeatMode == AudioServiceRepeatMode.one) {
      // Replay current track
      await _loadAndPlayCurrent();
      return;
    }

    _currentIndex = (_currentIndex + 1) % _queue.length;

    if (_currentIndex == 0 && _repeatMode == AudioServiceRepeatMode.none) {
      await pause();
      return;
    }

    await _loadAndPlayCurrent();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;

    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await _loadAndPlayCurrent();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;
    playbackState.add(_transformEvent(PlaybackEvent()));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode;
    if (shuffleMode == AudioServiceShuffleMode.all) {
      await shuffleQueue();
    }
    playbackState.add(_transformEvent(PlaybackEvent()));
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _currentIndex = index;
    await _loadAndPlayCurrent();
  }

  /// Load and play the current track
  Future<void> _loadAndPlayCurrent() async {
    if (_queue.isEmpty || _currentIndex >= _queue.length) return;

    final mediaItem = _queue[_currentIndex];

    // Update the current media item
    this.mediaItem.add(mediaItem);

    try {
      // Load the audio source
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(mediaItem.id)),
      );

      // Update media item with duration once loaded
      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          final updatedItem = mediaItem.copyWith(duration: duration);
          this.mediaItem.add(updatedItem);

          // Update in queue as well
          _queue[_currentIndex] = updatedItem;
          queue.add(_queue);
        }
      });

      await _audioPlayer.play();
    } catch (e) {
      print('Error loading audio: $e');
      // Skip to next track if current one fails
      if (_currentIndex < _queue.length - 1) {
        await skipToNext();
      }
    }
  }

  /// Play a specific track and create queue from track list
  Future<void> playTrack(TrackItem track, List<TrackItem> trackList) async {
    final mediaItems = trackList.map(trackToMediaItem).toList();
    await addQueueItems(mediaItems);

    final trackIndex = trackList.indexWhere((t) => t.id == track.id);
    _currentIndex = trackIndex >= 0 ? trackIndex : 0;

    await _loadAndPlayCurrent();
  }

  /// Shuffle the current queue
  Future<void> shuffleQueue() async {
    if (_queue.length <= 1) return;

    final currentItem = _queue[_currentIndex];
    _queue.shuffle();

    // Move current item to front
    _queue.remove(currentItem);
    _queue.insert(0, currentItem);
    _currentIndex = 0;

    queue.add(_queue);
  }

  @override
  Future<void> onTaskRemoved() async {
    // Stop playback when the app is removed from recent apps
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Stop playback when notification is dismissed
    await stop();
  }

  /// Get the currently playing track
  TrackItem? getCurrentTrack() {
    if (_queue.isEmpty || _currentIndex >= _queue.length) return null;

    final mediaItem = _queue[_currentIndex];
    return TrackItem(
      id: mediaItem.extras?['trackId'] ?? 0,
      title: mediaItem.title,
      artist: mediaItem.artist ?? '',
      cover: mediaItem.artUri?.toString() ?? '',
      fileuri: mediaItem.id,
    );
  }

  List<TrackItem> getCurrentQueue() {
    return _queue
        .map(
          (mediaItem) => TrackItem(
            id: mediaItem.extras?['trackId'] ?? 0,
            title: mediaItem.title,
            artist: mediaItem.artist ?? '',
            cover: mediaItem.artUri?.toString() ?? '',
            fileuri: mediaItem.id,
          ),
        )
        .toList();
  }

  Duration get position => _audioPlayer.position;

  Duration? get duration => _audioPlayer.duration;

  bool get isPlaying => _audioPlayer.playing;

  int get currentIndex => _currentIndex;

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'shuffle':
        await setShuffleMode(
          _shuffleMode == AudioServiceShuffleMode.none
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
        );
        break;
      default:
        super.customAction(name, extras);
    }
  }

  AudioServiceRepeatMode get repeatMode => _repeatMode;

  AudioServiceShuffleMode get shuffleMode => _shuffleMode;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
}

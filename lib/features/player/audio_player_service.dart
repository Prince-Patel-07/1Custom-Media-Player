// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:custom_media_player/core/database/app_database.dart';
import 'package:custom_media_player/core/models/media_track.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';

final audioPlayerServiceProvider = ChangeNotifierProvider<AudioPlayerService>((
  ref,
) {
  return AudioPlayerService(ref.watch(appDatabaseProvider));
});

class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService(this._database) {
    _subscriptions = [
      _player.playerStateStream.listen((_) => notifyListeners()),
      _player.positionStream.listen(_onPositionChanged),
      _player.durationStream.listen((_) => notifyListeners()),
      _player.loopModeStream.listen((_) => notifyListeners()),
      _player.shuffleModeEnabledStream.listen((_) => notifyListeners()),
      _player.currentIndexStream.listen(_onCurrentIndexChanged),
    ];
  }

  final AppDatabase _database;
  final AudioPlayer _player = AudioPlayer();
  late final List<StreamSubscription<dynamic>> _subscriptions;

  List<MediaTrack> _queue = const [];
  MediaTrack? _currentTrack;
  String? _errorMessage;
  Duration _lastSavedResumePosition = Duration.zero;
  String? _lastSavedTrackSource;

  List<MediaTrack> get queue => _queue;
  MediaTrack? get currentTrack => _currentTrack;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _player.playing;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  Future<void> playTracks(
    List<MediaTrack> tracks, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    if (tracks.isEmpty) {
      return;
    }

    final selectedTrack = tracks[initialIndex];

    if (_isSameSelection(tracks, selectedTrack)) {
      _errorMessage = null;
      notifyListeners();
      await _player.play();
      return;
    }

    _errorMessage = null;
    _queue = List<MediaTrack>.unmodifiable(tracks);
    _currentTrack = selectedTrack;
    notifyListeners();

    try {
      final audioSources = tracks.map(_mapTrackToSource).toList();
      await _player.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
        initialPosition: _initialPositionForTrack(selectedTrack),
      );
      if (shuffle) {
        await _player.shuffle();
        await _player.setShuffleModeEnabled(true);
      }
      await _player.play();
    } catch (error) {
      _errorMessage = 'Playback failed: $error';
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
      await _persistCurrentTrackPosition(force: true);
      return;
    }

    await _player.play();
  }

  Future<void> playNext() async {
    if (_player.hasNext) {
      await _persistCurrentTrackPosition(force: true);
      await _player.seekToNext();
    }
  }

  Future<void> playPrevious() async {
    if (_player.hasPrevious) {
      await _persistCurrentTrackPosition(force: true);
      await _player.seekToPrevious();
      return;
    }

    await _player.seek(Duration.zero);
  }

  Future<void> seek(Duration nextPosition) async {
    await _player.seek(nextPosition);
    await _persistCurrentTrackPosition(
      force: true,
      overridePosition: nextPosition,
    );
  }

  Future<void> toggleShuffle() async {
    if (_player.shuffleModeEnabled) {
      await _player.setShuffleModeEnabled(false);
      return;
    }

    await _player.shuffle();
    await _player.setShuffleModeEnabled(true);
  }

  Future<void> cycleLoopMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        return;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        return;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        return;
    }
  }

  String formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString();
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onCurrentIndexChanged(int? index) {
    if (index == null || index < 0 || index >= _queue.length) {
      return;
    }

    _synchronizeTrack(_queue[index]);
    notifyListeners();
  }

  AudioSource _mapTrackToSource(MediaTrack track) {
    if (track.isRemote) {
      return AudioSource.uri(Uri.parse(track.source), tag: track);
    }

    if (track.storesEmbeddedAudio) {
      return _MemoryAudioSource(track);
    }

    return AudioSource.file(track.source, tag: track);
  }

  Duration _initialPositionForTrack(MediaTrack track) {
    if (track.isRemote || !track.hasResumePoint) {
      return Duration.zero;
    }
    return track.resumePosition;
  }

  bool _isSameSelection(List<MediaTrack> tracks, MediaTrack selectedTrack) {
    if (_currentTrack?.source != selectedTrack.source ||
        _queue.length != tracks.length) {
      return false;
    }

    for (var index = 0; index < tracks.length; index++) {
      if (_queue[index].source != tracks[index].source) {
        return false;
      }
    }

    return _player.audioSource != null;
  }

  void _onPositionChanged(Duration position) {
    unawaited(_persistCurrentTrackPosition());
    notifyListeners();
  }

  Future<void> _persistCurrentTrackPosition({
    bool force = false,
    Duration? overridePosition,
  }) async {
    final track = _currentTrack;
    if (track == null || track.isRemote) {
      return;
    }

    final effectivePosition = _normalizedResumePosition(
      overridePosition ?? _player.position,
      _player.duration ?? Duration.zero,
    );

    if (!force) {
      if (effectivePosition == Duration.zero) {
        return;
      }
      if (_lastSavedTrackSource == track.source &&
          (effectivePosition - _lastSavedResumePosition).inSeconds.abs() < 5) {
        return;
      }
    }

    _synchronizeTrack(track.copyWith(resumePosition: effectivePosition));
    _lastSavedTrackSource = track.source;
    _lastSavedResumePosition = effectivePosition;
    await _database.updateResumePosition(track.source, effectivePosition);
  }

  Duration _normalizedResumePosition(Duration position, Duration duration) {
    if (position <= const Duration(seconds: 3)) {
      return Duration.zero;
    }

    if (duration > Duration.zero &&
        position >= duration - const Duration(seconds: 3)) {
      return Duration.zero;
    }

    return position;
  }

  void _synchronizeTrack(MediaTrack updatedTrack) {
    _currentTrack = updatedTrack;
    _queue = List<MediaTrack>.unmodifiable(
      _queue.map((track) {
        if (track.source == updatedTrack.source) {
          return updatedTrack;
        }
        return track;
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_persistCurrentTrackPosition(force: true));
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    unawaited(_player.dispose());
    super.dispose();
  }
}

class _MemoryAudioSource extends StreamAudioSource {
  _MemoryAudioSource(this.track) : super(tag: track);

  final MediaTrack track;

  Uint8List get _bytes => track.fileBytes!;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final bytes = _bytes;
    final effectiveStart = start == null || start < 0 ? 0 : start;
    final effectiveEnd = end == null || end > bytes.length ? bytes.length : end;
    final segment = bytes.sublist(effectiveStart, effectiveEnd);

    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: segment.length,
      offset: effectiveStart,
      stream: Stream.value(segment),
      contentType: _contentTypeForTrack(track),
    );
  }

  String _contentTypeForTrack(MediaTrack track) {
    final normalizedName = (track.fileName ?? track.source).toLowerCase();

    if (normalizedName.endsWith('.m4a')) {
      return 'audio/mp4';
    }
    if (normalizedName.endsWith('.aac')) {
      return 'audio/aac';
    }
    if (normalizedName.endsWith('.flac')) {
      return 'audio/flac';
    }
    if (normalizedName.endsWith('.ogg')) {
      return 'audio/ogg';
    }
    if (normalizedName.endsWith('.wav')) {
      return 'audio/wav';
    }

    return 'audio/mpeg';
  }
}

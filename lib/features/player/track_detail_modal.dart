import 'dart:typed_data';

import 'package:custom_media_player/core/models/media_track.dart';
import 'package:custom_media_player/features/player/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class TrackDetailModal extends ConsumerStatefulWidget {
  const TrackDetailModal({
    required this.track,
    super.key,
  });

  final MediaTrack track;

  @override
  ConsumerState<TrackDetailModal> createState() => _TrackDetailModalState();
}

class _TrackDetailModalState extends ConsumerState<TrackDetailModal> {
  late bool _isFavorite;
  double? _pendingSeekMilliseconds;
  bool _isScrubbing = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = false;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF202736),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_rounded),
              title: const Text('Track Info'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Remove from queue',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(audioPlayerServiceProvider);
    final track = widget.track;

    final duration = player.duration;
    final livePosition = player.position > duration ? duration : player.position;
    final maxMilliseconds = duration.inMilliseconds == 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final displayMilliseconds = _isScrubbing
        ? (_pendingSeekMilliseconds ?? livePosition.inMilliseconds.toDouble())
        : livePosition.inMilliseconds.toDouble();
    final clampedPosition = displayMilliseconds.clamp(0, maxMilliseconds).toDouble();

    final gradientColor = track.dominantColor ?? const Color(0xFFBF6A02);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColor.withValues(alpha: 0.3),
            gradientColor.withValues(alpha: 0.1),
            const Color(0xFF0E1117),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  iconSize: 28,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: _showMoreOptions,
                  iconSize: 24,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _AlbumArtSection(track: track),
                  const SizedBox(height: 36),
                  _TrackInfoSection(track: track),
                  const SizedBox(height: 32),
                  _PlaybackPositionSection(
                    player: player,
                    clampedPosition: clampedPosition,
                    maxMilliseconds: maxMilliseconds,
                    isScrubbing: _isScrubbing,
                    onSeekStart: () {
                      setState(() {
                        _isScrubbing = true;
                        _pendingSeekMilliseconds = clampedPosition;
                      });
                    },
                    onSeekChanged: (value) {
                      setState(() {
                        _isScrubbing = true;
                        _pendingSeekMilliseconds = value;
                      });
                    },
                    onSeekEnd: (value) async {
                      await player.seek(Duration(milliseconds: value.round()));
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _isScrubbing = false;
                        _pendingSeekMilliseconds = null;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  _ControlButtonsSection(
                    player: player,
                    isFavorite: _isFavorite,
                    onFavoritePressed: _toggleFavorite,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumArtSection extends StatelessWidget {
  const _AlbumArtSection({required this.track});

  final MediaTrack track;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: _buildAlbumArt(track),
      ),
    );
  }

  Widget _buildAlbumArt(MediaTrack track) {
    if (track.albumArtBytes != null && track.albumArtBytes!.isNotEmpty) {
      return Image.memory(
        track.albumArtBytes!,
        fit: BoxFit.cover,
      );
    }

    if (track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty) {
      return Image.network(
        track.albumArtUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderAlbumArt(),
      );
    }

    return _placeholderAlbumArt();
  }

  Widget _placeholderAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF57C7B6).withValues(alpha: 0.2),
            const Color(0xFFF29F05).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 120,
          color: Colors.white24,
        ),
      ),
    );
  }
}

class _TrackInfoSection extends StatelessWidget {
  const _TrackInfoSection({required this.track});

  final MediaTrack track;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          track.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          track.artist,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (track.album != null && track.album!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            track.album!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlaybackPositionSection extends StatelessWidget {
  const _PlaybackPositionSection({
    required this.player,
    required this.clampedPosition,
    required this.maxMilliseconds,
    required this.isScrubbing,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
  });

  final AudioPlayerService player;
  final double clampedPosition;
  final double maxMilliseconds;
  final bool isScrubbing;
  final VoidCallback onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            overlayColor: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.16),
            thumbColor: Colors.white,
            trackHeight: 6,
          ),
          child: Slider(
            value: clampedPosition,
            min: 0,
            max: maxMilliseconds,
            onChangeStart: (_) => onSeekStart(),
            onChanged: onSeekChanged,
            onChangeEnd: onSeekEnd,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              player.formatDuration(
                Duration(milliseconds: clampedPosition.round()),
              ),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              player.formatDuration(player.duration),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlButtonsSection extends StatelessWidget {
  const _ControlButtonsSection({
    required this.player,
    required this.isFavorite,
    required this.onFavoritePressed,
  });

  final AudioPlayerService player;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.red : Colors.white70,
              ),
              iconSize: 28,
              onPressed: onFavoritePressed,
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: player.hasPrevious ? player.playPrevious : null,
              iconSize: 28,
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: player.togglePlayPause,
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: player.hasNext ? player.playNext : null,
              iconSize: 28,
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded),
              color: Colors.white70,
              iconSize: 28,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

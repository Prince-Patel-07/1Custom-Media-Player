import 'package:custom_media_player/features/player/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class PlayerPanel extends ConsumerStatefulWidget {
  const PlayerPanel({super.key});

  @override
  ConsumerState<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends ConsumerState<PlayerPanel> {
  double? _pendingSeekMilliseconds;
  bool _isScrubbing = false;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(audioPlayerServiceProvider);
    final currentTrack = player.currentTrack;

    if (currentTrack == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          children: [
            Icon(Icons.music_note_rounded),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Import your own songs or try the online samples to wake the player up.',
              ),
            ),
          ],
        ),
      );
    }

    final duration = player.duration;
    final livePosition = player.position > duration
        ? duration
        : player.position;
    final maxMilliseconds = duration.inMilliseconds == 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final displayMilliseconds = _isScrubbing
        ? (_pendingSeekMilliseconds ?? livePosition.inMilliseconds.toDouble())
        : livePosition.inMilliseconds.toDouble();
    final clampedPosition = displayMilliseconds
        .clamp(0, maxMilliseconds)
        .toDouble();
    final queueIndex = player.queue.indexWhere(
      (track) => track.source == currentTrack.source,
    );
    final queueLabel = queueIndex < 0
        ? 'Queue ready'
        : 'Track ${queueIndex + 1} of ${player.queue.length}';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B3242), Color(0xFF1A1F2B), Color(0xFF141B24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: currentTrack.isRemote
                        ? const [Color(0xFFF29F05), Color(0xFFD96D1A)]
                        : const [Color(0xFF57C7B6), Color(0xFF2E90A5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  currentTrack.isRemote
                      ? Icons.cloud_queue_rounded
                      : Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: player.isPlaying ? 34 : 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTrack.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentTrack.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.queue_music_rounded,
                          label: queueLabel,
                        ),
                        _InfoChip(
                          icon: currentTrack.isRemote
                              ? Icons.wifi_tethering_rounded
                              : Icons.offline_bolt_rounded,
                          label: currentTrack.sourceLabel,
                        ),
                        if (currentTrack.hasResumePoint)
                          _InfoChip(
                            icon: Icons.bookmark_added_rounded,
                            label:
                                'Saved at ${player.formatDuration(currentTrack.resumePosition)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: player.toggleShuffle,
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: player.shuffleEnabled
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.white70,
                    ),
                  ),
                  IconButton(
                    onPressed: player.cycleLoopMode,
                    icon: Icon(
                      _loopModeIcon(player.loopMode),
                      color: player.loopMode == LoopMode.off
                          ? Colors.white70
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              overlayColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
              thumbColor: Colors.white,
              trackHeight: 4,
            ),
            child: Slider(
              value: clampedPosition,
              min: 0,
              max: maxMilliseconds,
              onChangeStart: (_) {
                setState(() {
                  _isScrubbing = true;
                  _pendingSeekMilliseconds = clampedPosition;
                });
              },
              onChanged: (value) {
                setState(() {
                  _isScrubbing = true;
                  _pendingSeekMilliseconds = value;
                });
              },
              onChangeEnd: (value) async {
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
          ),
          Row(
            children: [
              Text(
                player.formatDuration(
                  Duration(milliseconds: clampedPosition.round()),
                ),
              ),
              const Spacer(),
              Text(player.formatDuration(duration)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: currentTrack.hasResumePoint
                      ? () {
                          player.seek(currentTrack.resumePosition);
                        }
                      : null,
                  icon: const Icon(Icons.bookmark_rounded),
                  label: const Text('Resume Point'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: player.hasPrevious ? player.playPrevious : null,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: player.togglePlayPause,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      const SizedBox(width: 8),
                      Text(player.isPlaying ? 'Pause' : 'Play'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: player.hasNext ? player.playNext : null,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
          if (player.errorMessage case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _loopModeIcon(LoopMode loopMode) {
    return switch (loopMode) {
      LoopMode.one => Icons.repeat_one_rounded,
      LoopMode.all => Icons.repeat_rounded,
      LoopMode.off => Icons.repeat_rounded,
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.76)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

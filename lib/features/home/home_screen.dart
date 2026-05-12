import 'package:custom_media_player/core/models/media_track.dart';
import 'package:custom_media_player/features/library/library_controller.dart';
import 'package:custom_media_player/features/library/sample_tracks.dart';
import 'package:custom_media_player/features/player/audio_player_service.dart';
import 'package:custom_media_player/features/player/player_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E1117), Color(0xFF162033), Color(0xFF1A1825)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFF29F05), Color(0xFFFF6B9D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Music Hub',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore New Music',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  tabs: const [
                    Tab(text: 'Local Library'),
                    Tab(text: 'Online Samples'),
                    Tab(text: 'Your Setup'),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          LocalLibraryTab(
                            searchQuery: _searchQuery,
                            onSearchChanged: (query) {
                              setState(() {
                                _searchQuery = query;
                              });
                            },
                          ),
                          const OnlineSamplesTab(),
                          const SetupGuideTab(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const PlayerPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class LocalLibraryTab extends ConsumerWidget {
  const LocalLibraryTab({
    super.key,
    this.searchQuery = '',
    this.onSearchChanged,
  });

  final String searchQuery;
  final Function(String)? onSearchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    final player = ref.watch(audioPlayerServiceProvider);
    final totalSizeBytes = library.tracks.fold<int>(
      0,
      (sum, track) => sum + (track.fileSizeBytes ?? 0),
    );
    final storedInBrowserCount = library.tracks
        .where((track) => track.storesEmbeddedAudio)
        .length;
    final localTrackDetails = <String Function(MediaTrack)>[
      (track) => track.album ?? '',
      (track) => track.fileSizeBytes == null
          ? ''
          : _formatFileSize(track.fileSizeBytes!),
      (track) => track.hasResumePoint
          ? 'Saved at ${player.formatDuration(track.resumePosition)}'
          : '',
    ];

    return ListView(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your offline collection',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import your own songs from this device or browser, keep them saved locally, and jump back into playback from your last saved spot.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: library.isImporting
                      ? null
                      : () async {
                          final importedCount = await ref
                              .read(libraryControllerProvider)
                              .importSongs();
                          if (!context.mounted) {
                            return;
                          }
                          if (importedCount > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Imported $importedCount song(s) into your saved library.',
                                ),
                              ),
                            );
                          }
                        },
                  icon: library.isImporting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.library_music_rounded),
                  label: Text(
                    library.isImporting ? 'Importing...' : 'Import Music',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: library.tracks.isEmpty
                      ? null
                      : () {
                          ref
                              .read(audioPlayerServiceProvider)
                              .playTracks(library.tracks);
                        },
                  icon: const Icon(Icons.playlist_play_rounded),
                  label: const Text('Play All'),
                ),
                OutlinedButton.icon(
                  onPressed: library.tracks.isEmpty
                      ? null
                      : () {
                          ref
                              .read(audioPlayerServiceProvider)
                              .playTracks(library.tracks, shuffle: true);
                        },
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Shuffle'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Stats section with enhanced design
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _LibraryStatCard(
              title: 'Saved songs',
              value: '${library.tracks.length}',
              caption: library.tracks.isEmpty
                  ? 'Import your first track'
                  : 'Ready for offline playback',
              accentColor: Theme.of(context).colorScheme.primary,
              gradientColors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
            _LibraryStatCard(
              title: 'Library size',
              value: _formatFileSize(totalSizeBytes),
              caption: 'Across all imported files',
              accentColor: Theme.of(context).colorScheme.secondary,
              gradientColors: [
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
            _LibraryStatCard(
              title: 'Browser saved',
              value: '$storedInBrowserCount',
              caption: storedInBrowserCount == 0
                  ? 'Native files only so far'
                  : 'Stored directly in browser DB',
              accentColor: const Color(0xFFD96D1A),
              gradientColors: [
                const Color(0xFFD96D1A).withValues(alpha: 0.3),
                const Color(0xFFD96D1A).withValues(alpha: 0.05),
              ],
            ),
          ],
        ),
        if (library.errorMessage case final message?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        // Trending section with album cards
        if (library.tracks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Trending Now',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: library.tracks.length > 6 ? 6 : library.tracks.length,
              itemBuilder: (context, index) {
                final track = library.tracks[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right:
                        index <
                            (library.tracks.length > 6
                                    ? 6
                                    : library.tracks.length) -
                                1
                        ? 12
                        : 0,
                  ),
                  child: _AlbumCard(
                    track: track,
                    onPressed: () {
                      ref
                          .read(audioPlayerServiceProvider)
                          .playTracks(library.tracks, initialIndex: index);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (library.tracks.isNotEmpty)
          TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by title, artist...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () => onSearchChanged?.call(''),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        const SizedBox(height: 18),
        if (library.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (library.tracks.isEmpty)
          SizedBox(
            height: 320,
            child: _EmptyLibraryState(
              onImportPressed: library.isImporting
                  ? null
                  : () async {
                      await ref.read(libraryControllerProvider).importSongs();
                    },
            ),
          )
        else ...[
          // Filter tracks based on search
          Builder(
            builder: (context) {
              final filteredTracks = searchQuery.isEmpty
                  ? library.tracks
                  : library.tracks
                        .where(
                          (track) =>
                              track.title.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ) ||
                              track.artist.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ) ||
                              (track.album?.toLowerCase().contains(
                                    searchQuery.toLowerCase(),
                                  ) ??
                                  false),
                        )
                        .toList();

              if (filteredTracks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No songs found matching "$searchQuery"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (
                    var index = 0;
                    index < filteredTracks.length;
                    index++
                  ) ...[
                    _TrackTile(
                      track: filteredTracks[index],
                      isActive:
                          player.currentTrack?.source ==
                          filteredTracks[index].source,
                      trailingLabel:
                          player.currentTrack?.source ==
                              filteredTracks[index].source
                          ? player.isPlaying
                                ? 'Playing'
                                : 'Resume'
                          : 'Play',
                      details: localTrackDetails
                          .map((builder) => builder(filteredTracks[index]))
                          .where((detail) => detail.isNotEmpty)
                          .toList(growable: false),
                      onPressed: () {
                        ref
                            .read(audioPlayerServiceProvider)
                            .playTracks(filteredTracks, initialIndex: index);
                      },
                      onRemove: () async {
                        final track = filteredTracks[index];
                        await ref
                            .read(libraryControllerProvider)
                            .removeTrack(track);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Removed ${track.title} from your saved library.',
                            ),
                          ),
                        );
                      },
                    ),
                    if (index < filteredTracks.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class OnlineSamplesTab extends ConsumerWidget {
  const OnlineSamplesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Built-in streaming demos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(audioPlayerServiceProvider).playTracks(sampleTracks);
              },
              icon: const Icon(Icons.playlist_play_rounded),
              label: const Text('Play Sample Queue'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'These are royalty-free sample tracks for testing online playback safely while we build the real search and provider integrations later.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.separated(
            itemCount: sampleTracks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final track = sampleTracks[index];
              return _TrackTile(
                track: track,
                trailingLabel: 'Stream',
                details: [
                  if (track.album != null) track.album!,
                  track.sourceLabel,
                ],
                onPressed: () {
                  ref
                      .read(audioPlayerServiceProvider)
                      .playTracks(sampleTracks, initialIndex: index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SetupGuideTab extends StatelessWidget {
  const SetupGuideTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _GuideCard(
          title: 'How to add your own songs',
          icon: Icons.file_open_rounded,
          lines: [
            'Open the Local Library tab.',
            'Press Import Music.',
            'Choose your own MP3, WAV, M4A, AAC, FLAC, or OGG files.',
            'Tap any imported track to play it, or use Play All / Shuffle.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          title: 'Best options for your own usage',
          icon: Icons.tips_and_updates_rounded,
          lines: [
            'Keep a small test folder of songs on your computer or phone while we build.',
            'Chrome can now save imported songs in the browser database for offline use.',
            'The player now remembers your resume point for imported tracks.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          title: 'Logical next upgrades',
          icon: Icons.route_rounded,
          lines: [
            'Extract metadata and album art from imported files.',
            'Add playlists, favorites, and recent plays.',
            'Add legal online search providers later behind a repository layer.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          title: 'Windows and Android setup notes',
          icon: Icons.settings_suggest_rounded,
          lines: [
            'Windows plugin builds need Developer Mode enabled for symlink support.',
            'Android development also needs Android Studio or a local Android SDK.',
            'Streaming requires internet access, so Android should keep the INTERNET permission.',
          ],
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.track, required this.onPressed});

  final MediaTrack track;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      track.dominantColor?.withValues(alpha: 0.7) ??
                          const Color(0xFFF29F05).withValues(alpha: 0.5),
                      track.dominantColor?.withValues(alpha: 0.3) ??
                          const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: track.albumArtBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          track.albumArtBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : track.albumArtUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          track.albumArtUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.music_note,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.music_note,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Album info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.album ?? track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.onImportPressed});

  final VoidCallback? onImportPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF57C7B6).withValues(alpha: 0.15),
                      const Color(0xFFF29F05).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF57C7B6).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.25),
                            Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Start with your own files',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your personal imports now save locally across sessions, including on Chrome. The next step is upgrading filename-based details into real metadata and artwork.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onImportPressed,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Choose Songs'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LibraryStatCard extends StatelessWidget {
  const _LibraryStatCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.accentColor,
    this.gradientColors,
  });

  final String title;
  final String value;
  final String caption;
  final Color accentColor;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradientColors == null
            ? Colors.white.withValues(alpha: 0.04)
            : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 10,
            width: 42,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $line',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.trailingLabel,
    required this.details,
    required this.onPressed,
    this.onRemove,
    this.isActive = false,
  });

  final MediaTrack track;
  final String trailingLabel;
  final List<String> details;
  final VoidCallback onPressed;
  final VoidCallback? onRemove;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Album art thumbnail
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  track.dominantColor?.withValues(alpha: 0.6) ??
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                  track.dominantColor?.withValues(alpha: 0.2) ??
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: track.albumArtBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      track.albumArtBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                : track.albumArtUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      track.albumArtUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.music_note,
                          color: track.isRemote
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        );
                      },
                    ),
                  )
                : Icon(
                    track.isRemote
                        ? Icons.wifi_tethering_rounded
                        : Icons.music_note,
                    color: track.isRemote
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 14),
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${track.artist} - ${track.sourceLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                  ),
                ),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final detail in details)
                          _TrackPill(label: detail, highlighted: isActive),
                      ],
                    ),
                  ),
                if (track.description case final description?)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: Icon(
                  isActive
                      ? Icons.radio_button_checked
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(
                  trailingLabel,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (onRemove != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IconButton(
                    onPressed: onRemove,
                    tooltip: 'Remove from library',
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackPill extends StatelessWidget {
  const _TrackPill({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.80),
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final fractionDigits = value >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
}

import 'package:custom_media_player/core/models/media_track.dart';

const sampleTracks = <MediaTrack>[
  MediaTrack(
    id: 'sample-3s',
    title: '3-second synth melody',
    artist: 'Samplelib Demo',
    album: 'Sample Pack',
    source: 'https://download.samplelib.com/mp3/sample-3s.mp3',
    sourceType: TrackSourceType.onlineSample,
    description: 'Tiny royalty-free sample for testing basic streaming.',
  ),
  MediaTrack(
    id: 'sample-12s',
    title: '12-second flute and drums',
    artist: 'Samplelib Demo',
    album: 'Sample Pack',
    source: 'https://download.samplelib.com/mp3/sample-12s.mp3',
    sourceType: TrackSourceType.onlineSample,
    description: 'Good for checking short remote playback behavior.',
  ),
  MediaTrack(
    id: 'sample-15s',
    title: '19 seconds of awesome music',
    artist: 'Samplelib Demo',
    album: 'Sample Pack',
    source: 'https://download.samplelib.com/mp3/sample-15s.mp3',
    sourceType: TrackSourceType.onlineSample,
    description: 'A longer demo stream for queue and seek testing.',
  ),
];

import 'dart:async';

import 'package:custom_media_player/core/database/app_database.dart';
import 'package:custom_media_player/core/models/media_track.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

final libraryControllerProvider = ChangeNotifierProvider<LibraryController>((
  ref,
) {
  return LibraryController(ref.watch(appDatabaseProvider));
});

class LibraryController extends ChangeNotifier {
  LibraryController(this._database) {
    unawaited(_hydrateTracks());
  }

  final AppDatabase _database;
  List<MediaTrack> _tracks = const [];
  bool _isLoading = true;
  bool _isImporting = false;
  String? _errorMessage;

  List<MediaTrack> get tracks => _tracks;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String? get errorMessage => _errorMessage;

  Future<int> importSongs() async {
    _isImporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: kIsWeb,
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg'],
      );

      if (result == null) {
        return 0;
      }

      final knownSources = _tracks.map((track) => track.source).toSet();
      final importedTracks = <MediaTrack>[];

      for (final file in result.files) {
        final importedTrack = _buildImportedTrack(file);
        if (importedTrack == null ||
            knownSources.contains(importedTrack.source)) {
          continue;
        }

        knownSources.add(importedTrack.source);
        importedTracks.add(importedTrack);
      }

      if (importedTracks.isNotEmpty) {
        await _database.upsertLocalTracks(importedTracks);
        await _hydrateTracks(showLoading: false);
      } else {
        _errorMessage =
            'No new songs were added. If you picked the same files again, they were skipped to avoid duplicates.';
      }

      return importedTracks.length;
    } catch (error) {
      _errorMessage = 'Import failed: $error';
      return 0;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> removeTrack(MediaTrack track) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _database.deleteLocalTrack(track.source);
      _tracks = _tracks
          .where((existingTrack) => existingTrack.source != track.source)
          .toList(growable: false);
    } catch (error) {
      _errorMessage = 'Could not remove ${track.title}: $error';
    } finally {
      notifyListeners();
    }
  }

  MediaTrack? _buildImportedTrack(PlatformFile file) {
    final metadata = _metadataFromFileName(file.name);
    final storageKey = _storageKeyForFile(file);

    if (storageKey == null) {
      _errorMessage =
          'One or more songs could not be imported because the app could not access the file content.';
      return null;
    }

    final isEmbeddedImport = kIsWeb || file.path == null;

    return MediaTrack(
      id: 'local-$storageKey',
      title: metadata.title,
      artist: metadata.artist,
      album: 'Local Library',
      source: storageKey,
      sourceType: TrackSourceType.local,
      description: isEmbeddedImport
          ? 'Saved inside this browser for offline playback.'
          : file.path,
      fileName: file.name,
      fileSizeBytes: file.size == 0 ? null : file.size,
      fileBytes: isEmbeddedImport ? file.bytes : null,
    );
  }

  String? _storageKeyForFile(PlatformFile file) {
    if (!kIsWeb && file.path != null) {
      return file.path;
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    return 'browser-${file.name}-${file.size}-${_stableHash(bytes)}';
  }

  ({String artist, String title}) _metadataFromFileName(String fileName) {
    final cleanedName = _titleFromFileName(
      fileName,
    ).replaceAll('_', ' ').trim();
    final dividerIndex = cleanedName.indexOf(' - ');

    if (dividerIndex > 0 && dividerIndex < cleanedName.length - 3) {
      return (
        artist: cleanedName.substring(0, dividerIndex).trim(),
        title: cleanedName.substring(dividerIndex + 3).trim(),
      );
    }

    return (artist: 'Imported from your library', title: cleanedName);
  }

  int _stableHash(List<int> bytes) {
    var hash = 17;
    for (final byte in bytes) {
      hash = ((hash * 31) + byte) & 0x7fffffff;
    }
    return hash;
  }

  String _titleFromFileName(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot <= 0) {
      return fileName;
    }
    return fileName.substring(0, lastDot);
  }

  Future<void> _hydrateTracks({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _tracks = await _database.loadLocalTracks();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Could not load your saved library: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

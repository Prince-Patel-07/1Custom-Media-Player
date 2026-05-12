import 'dart:async';

import 'package:custom_media_player/core/models/media_track.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});

class LocalTracks extends Table {
  TextColumn get sourcePath => text()();
  TextColumn get trackId => text()();
  TextColumn get title => text()();
  TextColumn get artist =>
      text().withDefault(const Constant('Imported from your device'))();
  TextColumn get album => text().withDefault(const Constant('Local Library'))();
  TextColumn get description => text().nullable()();
  TextColumn get fileName => text().nullable()();
  BlobColumn get byteData => blob().nullable()();
  IntColumn get fileSizeBytes => integer().nullable()();
  IntColumn get resumePositionMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {sourcePath};
}

@DriftDatabase(tables: [LocalTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(localTracks, localTracks.fileName);
        await migrator.addColumn(localTracks, localTracks.byteData);
        await migrator.addColumn(localTracks, localTracks.fileSizeBytes);
        await migrator.addColumn(localTracks, localTracks.resumePositionMs);
        await customStatement('''
          UPDATE local_tracks
          SET file_name = title
          WHERE file_name IS NULL
          ''');
      }
    },
  );

  Future<List<MediaTrack>> loadLocalTracks() async {
    final rows = await (select(
      localTracks,
    )..orderBy([(track) => OrderingTerm.desc(track.importedAt)])).get();

    return rows.map(_mapRowToTrack).toList(growable: false);
  }

  Future<void> upsertLocalTracks(List<MediaTrack> tracks) async {
    if (tracks.isEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        localTracks,
        tracks.map(_mapTrackToCompanion).toList(growable: false),
      );
    });
  }

  Future<void> updateResumePosition(
    String sourcePath,
    Duration resumePosition,
  ) async {
    await (update(
      localTracks,
    )..where((track) => track.sourcePath.equals(sourcePath))).write(
      LocalTracksCompanion(
        resumePositionMs: Value(
          resumePosition.inMilliseconds < 0 ? 0 : resumePosition.inMilliseconds,
        ),
      ),
    );
  }

  Future<void> deleteLocalTrack(String sourcePath) async {
    await (delete(
      localTracks,
    )..where((track) => track.sourcePath.equals(sourcePath))).go();
  }

  MediaTrack _mapRowToTrack(LocalTrack row) {
    return MediaTrack(
      id: row.trackId,
      title: row.title,
      artist: row.artist,
      album: row.album,
      source: row.sourcePath,
      sourceType: TrackSourceType.local,
      description: row.description,
      fileName: row.fileName,
      fileSizeBytes: row.fileSizeBytes,
      fileBytes: row.byteData,
      resumePosition: Duration(milliseconds: row.resumePositionMs),
    );
  }

  LocalTracksCompanion _mapTrackToCompanion(MediaTrack track) {
    return LocalTracksCompanion.insert(
      sourcePath: track.source,
      trackId: track.id,
      title: track.title,
      artist: Value(track.artist),
      album: Value(track.album ?? 'Local Library'),
      description: Value(track.description),
      fileName: Value(track.fileName),
      byteData: Value(track.fileBytes),
      fileSizeBytes: Value(track.fileSizeBytes),
      resumePositionMs: Value(track.resumePosition.inMilliseconds),
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'custom_media_player',
    web: kIsWeb
        ? DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          )
        : null,
  );
}

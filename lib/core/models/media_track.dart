import 'dart:typed_data';
import 'package:flutter/material.dart';

enum TrackSourceType { local, onlineSample }

class MediaTrack {
  const MediaTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    required this.sourceType,
    this.album,
    this.description,
    this.fileName,
    this.fileSizeBytes,
    this.fileBytes,
    this.resumePosition = Duration.zero,
    this.albumArtBytes,
    this.albumArtUrl,
    this.dominantColor,
  });

  final String id;
  final String title;
  final String artist;
  final String source;
  final TrackSourceType sourceType;
  final String? album;
  final String? description;
  final String? fileName;
  final int? fileSizeBytes;
  final Uint8List? fileBytes;
  final Duration resumePosition;
  final Uint8List? albumArtBytes;
  final String? albumArtUrl;
  final Color? dominantColor;

  bool get isRemote => sourceType == TrackSourceType.onlineSample;
  bool get storesEmbeddedAudio => (fileBytes?.isNotEmpty ?? false);
  bool get hasResumePoint => resumePosition >= const Duration(seconds: 3);

  String get sourceLabel {
    return switch (sourceType) {
      TrackSourceType.local => 'Saved offline',
      TrackSourceType.onlineSample => 'Online sample',
    };
  }

  MediaTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? source,
    TrackSourceType? sourceType,
    String? album,
    String? description,
    String? fileName,
    int? fileSizeBytes,
    Uint8List? fileBytes,
    Duration? resumePosition,
    Uint8List? albumArtBytes,
    String? albumArtUrl,
    Color? dominantColor,
    bool clearAlbum = false,
    bool clearDescription = false,
    bool clearFileName = false,
    bool clearFileSizeBytes = false,
    bool clearFileBytes = false,
    bool clearAlbumArtBytes = false,
    bool clearAlbumArtUrl = false,
    bool clearDominantColor = false,
  }) {
    return MediaTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      source: source ?? this.source,
      sourceType: sourceType ?? this.sourceType,
      album: clearAlbum ? null : album ?? this.album,
      description: clearDescription ? null : description ?? this.description,
      fileName: clearFileName ? null : fileName ?? this.fileName,
      fileSizeBytes: clearFileSizeBytes
          ? null
          : fileSizeBytes ?? this.fileSizeBytes,
      fileBytes: clearFileBytes ? null : fileBytes ?? this.fileBytes,
      resumePosition: resumePosition ?? this.resumePosition,
      albumArtBytes: clearAlbumArtBytes ? null : albumArtBytes ?? this.albumArtBytes,
      albumArtUrl: clearAlbumArtUrl ? null : albumArtUrl ?? this.albumArtUrl,
      dominantColor: clearDominantColor ? null : dominantColor ?? this.dominantColor,
    );
  }
}

# Custom Media Player Blueprint

Last updated: 2026-05-08

## 1. Goal

Build a Flutter-based custom media player that starts as an offline-first music app and later grows into a richer media app with online search and video playback.

## 2. Product Direction

### Phase 1 vision

Start with a clean, reliable local music player:

- Import audio files from the device
- Read metadata like title, artist, album, duration, and cover art
- Save that information in a local database
- Browse songs, albums, artists, and playlists
- Play, pause, seek, skip, shuffle, and repeat
- Resume the last queue and playback position

### Phase 2 vision

Extend the app into a hybrid local + online media player:

- Search remote content from approved APIs
- Show search results beside local library results
- Play supported remote audio/video sources
- Cache selected metadata locally

### Important product rule

For online search, use legal and supported APIs or licensed sources. We should avoid scraping or extracting streams from platforms that do not allow it.

## 3. Recommended Starting Scope

Assumption: build Android-first for the first version.

Why:

- It keeps permissions and storage behavior easier to reason about
- Music-player workflows are strongest on Android
- We can add iOS after the core architecture is stable

## 4. Architecture

Use Flutter's recommended layered MVVM-style structure:

- UI layer: screens, widgets, view models, state providers
- Domain layer: use cases for import, play, search, queue, playlists
- Data layer: repositories that combine local database, file services, and remote APIs
- Service layer: playback engine, file picker, metadata reader, local database, permissions, remote search

### Dependency direction

UI -> Domain -> Repositories -> Services

This matters because it lets us:

- replace the playback engine later without rewriting the whole app
- add online search later without changing the local-library screens
- test the import and playback logic separately from the UI

## 5. Suggested Flutter Stack

These package choices were checked on 2026-05-08 and are good starting points for this app:

- `flutter_riverpod`: app state, dependency injection, async state handling
- `go_router`: app navigation
- `drift`: local SQLite database with type-safe queries
- `file_picker`: import audio/video files through the native picker
- `path_provider`: app storage paths
- `permission_handler`: runtime permissions where needed
- `audio_metadata_reader`: read tags and artwork from local audio files
- `just_audio`: core audio playback
- `audio_service`: background playback and media controls when we reach that step
- `video_player`: later phase for video playback

### Why this stack

- `just_audio` is a strong fit for a music-first app
- `video_player` can be added later without forcing us to over-design v1
- `drift` gives us a strong local database story from day one
- `flutter_riverpod` scales well as features grow

## 6. Proposed Project Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    errors/
    utils/
    services/
  data/
    database/
    models/
    repositories/
    services/
  domain/
    entities/
    usecases/
  features/
    library/
      presentation/
      application/
      data/
    player/
      presentation/
      application/
      data/
    playlists/
      presentation/
      application/
      data/
    search/
      presentation/
      application/
      data/
    settings/
      presentation/
      application/
      data/
  shared/
    widgets/
```

## 7. Core Data Model

We should design the database for both local and future remote media.

### Main entities

- `Track`
  - id
  - sourceType (`local`, `remote`)
  - filePath or streamUrl
  - title
  - artistName
  - albumName
  - durationMs
  - artworkPath or artworkBytes
  - mimeType
  - addedAt
  - lastPlayedAt
  - playCount
- `Album`
- `Artist`
- `Playlist`
- `PlaylistTrack`
- `PlaybackQueueItem`
- `AppSetting`
- `SearchHistory`

### Design rule

Even in v1, every track should have a `sourceType`. That small choice will make future remote search much easier.

## 8. MVP Features

### Must-have for v1

- Create Flutter app shell
- Import audio files manually with a picker
- Extract metadata and store it locally
- Show local library list
- Open now-playing screen
- Play local files
- Queue support
- Shuffle and repeat
- Persist last session

### Nice-to-have after MVP

- Favorites
- Recently played
- Playlist creation
- Search inside the local library
- Waveform or visualizer
- Sleep timer
- Theme customization

### Not in v1

- Full device media scan
- Sync across devices
- Downloading remote content
- Account system
- Complex recommendation engine

## 9. UX Flow

### First-run flow

1. Open app
2. Show empty library state
3. Tap `Import Music`
4. Pick one or more local files
5. Parse metadata
6. Save tracks to local database
7. Render library screen
8. Tap a track to start playback

### Main screens

- Splash / boot screen
- Library screen
- Artists screen
- Albums screen
- Playlists screen
- Now playing screen
- Queue sheet
- Import screen or import dialog
- Settings screen

## 10. Step-by-Step Build Plan

### Step 0: Environment check

- Confirm Flutter SDK works locally
- Run `flutter doctor`
- Decide target device for development
- Create the Flutter project in this folder

### Step 1: App foundation

- Add Riverpod, routing, theming, linting
- Set up folder structure
- Create placeholder screens
- Wire app navigation

### Step 2: Database foundation

- Add Drift
- Define tables and entities
- Create migrations
- Build repository interfaces

### Step 3: Local import pipeline

- Add file picker
- Pick multiple audio files
- Parse metadata
- Save to database
- Skip duplicates safely

### Step 4: Playback engine

- Add `just_audio`
- Create `PlaybackService`
- Build queue logic
- Add play, pause, seek, next, previous, shuffle, repeat

### Step 5: Library UI

- Songs tab
- Albums tab
- Artists tab
- Playlist tab
- Empty-state and loading-state UX

### Step 6: Now-playing experience

- Large artwork
- Progress bar
- Media controls
- Queue bottom sheet
- Persist last playback session

### Step 7: Background playback

- Add `audio_service`
- Hook lock-screen / notification controls
- Handle app resume and interruptions

### Step 8: Local search and polish

- Search songs, artists, albums, playlists
- Add favorites and recent plays
- Improve performance for large libraries

### Step 9: Online search architecture

- Add `RemoteSearchService`
- Add `RemoteMediaRepository`
- Merge remote and local search results in the UI
- Keep playback abstraction clean so local and remote items can share the same screens

### Step 10: Video support

- Add `video_player`
- Create a media-detail player route that can switch between audio and video layouts
- Only enable this after the music flow is stable

## 11. Online Search Plan

When we reach the remote phase, we should not bolt it onto the app randomly. The right design is:

- `LibraryRepository` for local tracks
- `SearchRepository` for local + remote search
- `PlaybackItem` entity that can represent either a file path or a remote URL
- `SourceType` enum to branch logic cleanly

### Remote search options later

- Your own backend with licensed media
- Public APIs that allow search and playback in your app
- Video providers only when their terms explicitly allow your use case

## 12. Biggest Risks

- Android storage and media permissions can get messy if we try to scan the whole device too early
- Metadata quality differs between files, so the UI must handle missing artist/album/artwork
- Background audio is more complex than foreground playback
- Remote video support adds legal, technical, and performance complexity

## 13. Recommended First Milestone

The best first milestone is not "play everything."

It is:

"Import local songs, save them in the database, list them on screen, and play one selected track."

That milestone proves the four hardest foundations:

- file access
- metadata extraction
- local persistence
- playback wiring

## 14. Exact Next Steps

### What we should do next

1. Run `flutter doctor` and confirm the local setup
2. Scaffold the Flutter app in this folder
3. Add the core dependencies
4. Create the folder structure
5. Build the empty screens and router
6. Implement the import pipeline

## 15. Build Order I Recommend For Us

1. Project setup
2. App shell and navigation
3. Database schema
4. File import
5. Local library list
6. Playback service
7. Now playing UI
8. Background audio
9. Local search and playlists
10. Remote search
11. Video support

## 16. Notes For Future Us

- Keep the app offline-first even after adding remote search
- Do not couple the UI directly to package APIs
- Hide playback, database, and remote logic behind repositories/services
- Prefer incremental milestones over trying to build all features at once

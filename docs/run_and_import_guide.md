# Run and Import Guide

Last updated: 2026-05-12

## What is already built

- Flutter app scaffold
- Local file import flow
- Persistent local track storage
- Browser-side import and saving through the local database
- Demo online sample catalog
- Basic player controls for play, pause, seek, previous, next, shuffle, and loop
- Resume-point saving for imported songs

## How to run the app

### Windows desktop

```powershell
flutter run -d windows
```

### Chrome

```powershell
flutter run -d chrome
```

Chrome can now open the local library tab and import your own songs into the browser database for offline testing.

## Before you run on Windows

If Flutter warns that plugin builds need symlink support, enable Windows Developer Mode:

1. Open `Settings`
2. Open `For developers`
3. Enable `Developer Mode`

## Before you run on Android

You still need an Android SDK. After installing Android Studio, check:

```powershell
flutter doctor
```

## How to add your own songs

### Option 1: Use the in-app importer

This is the best option right now.

1. Open `Local Library`
2. Press `Import Music`
3. Select your own audio files
4. Tap a track to play it, or use `Play All` / `Shuffle`

Supported first-pass formats:

- `mp3`
- `wav`
- `m4a`
- `aac`
- `flac`
- `ogg`

### Option 2: Keep a dedicated test folder

Recommended while we build:

- create one folder with 5 to 20 songs you own
- use those same files for repeated testing
- keep a mix of short and long tracks

That gives us predictable test data while we add metadata parsing and artwork extraction.

## Resume points

Imported songs now save a resume point while you listen.

- if you pause and come back later, the player can continue from the saved spot
- near the end of a song, the saved point resets so replay starts fresh
- the player panel also includes a `Resume Point` shortcut button

## Safe online sample tracks

The current starter app uses royalty-free sample audio from Samplelib for streaming tests.

Why this is the right temporary choice:

- easy to test
- legal for development and demo use
- avoids tying the app to unsupported scraping flows

## Best next steps

1. Extract metadata and artwork from local files
2. Add playlists and favorites
3. Track recently played songs
4. Add a legal remote search provider later

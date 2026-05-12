# Track Detail Modal - Usage Guide

## Overview
The `TrackDetailModal` is a bottom sheet widget that displays detailed information about a currently playing track. It provides an immersive UI for track viewing and playback control.

## File Location
- `lib/features/player/track_detail_modal.dart`

## Widget: TrackDetailModal

### Constructor
```dart
const TrackDetailModal({
  required MediaTrack track,
  Key? key,
})
```

### Parameters
- **track** (required): The `MediaTrack` object to display in the modal

### Usage Example

```dart
import 'package:custom_media_player/features/player/track_detail_modal.dart';
import 'package:custom_media_player/core/models/media_track.dart';

// Show the track detail modal
void showTrackDetails(BuildContext context, MediaTrack track) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TrackDetailModal(track: track),
  );
}
```

## Features Implemented

### 1. **Modal Structure**
- ✅ Bottom sheet that pops up from bottom of screen
- ✅ X button in TOP LEFT corner to close the modal
- ✅ Large album art display (~50% of modal height)
- ✅ Track title and artist below album art
- ✅ Playback position slider with duration display
- ✅ Playback controls (play/pause, skip, etc.)

### 2. **Visual Design**
- ✅ Gradient background based on album art's dominant color
- ✅ Rounded corners on modal (32px)
- ✅ Smooth animations when opening/closing
- ✅ Colorful, modern appearance matching app theme
- ✅ Icons with proper colors and sizing
- ✅ Professional shadow effects on album art
- ✅ Material Design 3 principles applied

### 3. **Album Art Display**
The modal intelligently handles album art from multiple sources:
- **Embedded Album Art**: Displays `albumArtBytes` if available
- **Remote Album Art**: Falls back to `albumArtUrl` if embedded not available
- **Placeholder**: Shows gradient background with music note icon if no art available

### 4. **Track Information**
Displays:
- Track title (with truncation support)
- Artist name
- Album name (if available)

### 5. **Playback Controls**
- **Play/Pause Button**: Center button with gradient background and shadow
- **Skip Previous**: With disabled state handling
- **Skip Next**: With disabled state handling
- **Favorite/Like Button**: Heart icon that toggles between filled and outline
- **More Options**: Three dots button for menu
- **More Options Menu**: Includes:
  - Track Info
  - Share
  - Remove from queue

### 6. **Playback Position Section**
- Styled slider for seeking
- Current position time display
- Total duration display
- Smooth scrubbing feedback

### 7. **State Management**
- Uses `ConsumerStatefulWidget` for Riverpod integration
- Watches `audioPlayerServiceProvider` for real-time player updates
- Manages local state for:
  - Favorite/like button toggle
  - Scrubbing state during seeking

## Component Breakdown

### _AlbumArtSection
Displays the album artwork with:
- 280x280 size
- Rounded corners (32px)
- Shadow effects
- Null-safe image loading

### _TrackInfoSection
Shows track metadata:
- Centered title with 2-line max
- Centered artist name
- Optional album name
- Responsive text sizing

### _PlaybackPositionSection
Provides seekable progress:
- Themed slider matching app colors
- Time display (current/total)
- Scrubbing callback handling

### _ControlButtonsSection
Playback control buttons:
- Heart favorite button
- Skip previous button
- Large play/pause button with gradient
- Skip next button
- More options button

## Integration with PlayerService

The modal automatically:
- Watches player state through Riverpod
- Updates UI when position changes
- Handles play/pause toggle
- Supports skip next/previous
- Displays current playback position

## Color Scheme

The modal uses:
- **Primary Color**: `#F29F05` (Orange - play button)
- **Secondary Color**: `#57C7B6` (Teal - accents)
- **Surface Color**: `#171B24` (Dark blue-gray)
- **Background**: Gradient based on track's `dominantColor`

## Responsive Design

- Adapts to different screen sizes
- Scrollable content for small screens
- Proper padding and spacing
- Touch-friendly button sizes

## Future Enhancements

Potential additions:
- Lyrics display/synchronization
- Equalizer controls
- Repeat/shuffle indicators in modal
- Track history/queue display
- Persistent favorite storage to database
- More detailed track information (file size, format, etc.)

## Integration Notes

To use this modal in your app:

1. Import the widget:
```dart
import 'package:custom_media_player/features/player/track_detail_modal.dart';
```

2. Show it when user clicks a track or taps the player panel:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => TrackDetailModal(track: currentTrack),
);
```

3. The modal will automatically handle:
   - Riverpod state management
   - Real-time player updates
   - All playback controls
   - Favorite toggling

## Styling Notes

The widget follows the app's Material Design 3 theme:
- Uses `Theme.of(context)` for consistent colors
- Implements `withValues(alpha: ...)` for transparency
- Uses rounded buttons and containers
- Applies proper spacing using `SizedBox`
- Uses `BoxShadow` for depth

---

**Task Status**: ✅ Complete
**File**: `lib/features/player/track_detail_modal.dart`
**Lines of Code**: 447

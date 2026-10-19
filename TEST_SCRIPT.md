# Platform view defects: manual test script

This throwaway app checks the platform-view defects listed in section 2 of `mapigrade/docs/platform-view-comparison.md`. It uses `flutter_map` with flutter_map_maplibre 0.0.5 and maplibre 0.3.6. `lib/mode_maplibre_layer.dart` is a copy of flutter_map_maplibre's `MapLibreLayer` that also passes the Android platform view options, because `MapLibreLayer` doesn't expose them.

## Setup

- Run with `flutter run --release` on each device. Debug builds are fine for the Share and Effects pages, but use release builds if you judge stutter.
- On Android, the tune icon in the app bar selects the configuration, and the app bar title shows the current one:
  - **A1** `tlhc_vd`, texture: the `maplibre` default
  - **A2** `tlhc_hc`, SurfaceView (`androidTextureMode: false`)
  - **A3** `hc`, SurfaceView
- On iOS there is one configuration (`UiKitView`).
- Record the device, OS version and Flutter version for each run. When a step fails, take a native screenshot (`adb exec-out screencap -p > file.png`, the iOS side button, or `xcrun simctl io booted screenshot file.png`). Don't use an in-app capture as evidence for the Effects and Scroll pages.

Mark each cell **P** (pass: looks like plain Flutter widgets would), **F** (fail: describe it in Notes) or **–** (not run).

## 1. Share page: `RepaintBoundary.toImage`

1. Wait for the map tiles to load.
2. Tap **Export image**.
3. Compare the exported image in the dialog with the live screen.

Pass: the image shows the map tiles, the markers and the forecast card. Fail: the markers and card are there, but the map area is blank or transparent. The dialog also shows the percentage of transparent pixels; it is about 0% when the map was captured.

| Step | iOS sim | iPhone | A1 | A2 | A3 |
| --- | --- | --- | --- | --- | --- |
| 1.1 map in exported image | | fail - map is not rendered, but Flutter overlays are | pass - map is rendered | fail - share map is not rendered in share image, and map view is over top of all Flutter UI | fail - map is not rendered, but Flutter overlays are |

## 2. Effects page: filters on and over the map

The markers are Flutter widgets, so they always show the effect. The test is whether the map tiles show it too. Turn on one chip at a time, then turn it off again.

| Step | Chip | Pass when | iOS sim | iPhone | A1 | A2 | A3 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2.1 | Blur sheet | the map under the bottom sheet is blurred | | pass - blurred | pass | fail | fail |
| 2.2 | Grayscale | the map tiles are gray, like the markers | | fail - not grayscale | pass | fail | fail |
| 2.3 | Opacity 0.5 | purple and yellow stripes show through the tiles | | pass - purple and yellow show through | pass | fail | fail |
| 2.4 | Fade | the map fades to the stripes toward the bottom | | fail - no fading | pass | fail | fail |

## 3. Scroll page: placement and clipping

The map is the eleventh card in the list. The list scrolls under the translucent app bar. Scroll slowly with your finger, and watch the map while you scroll as well as when you stop.

| Step | Action | Pass when | iOS sim | iPhone | A1 | A2 | A3 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3.1 | Scroll until the map card is fully on screen | the map is inside its card, with rounded corners | | pass - map is in its card with rounded corners | pass | fail | pass |
| 3.2 | Scroll the card under the app bar | the map shows faintly through the app bar, and the app bar title stays on top | | pass - map shows through app bar | pass | fail | pass |
| 3.3 | Scroll the card off the top of the screen | no part of the map stays visible | | pass - map goes off screen | pass | fail | pass |
| 3.4 | Fling quickly up and down past the map | the map moves with its card, with no lag or gap | | pass - map stays positioned correctly | pass | fail | pass |
| 3.5 | Overscroll at the top and the bottom of the list (stretch on Android, bounce on iOS) | the map card stretches or moves with the other cards | | pass | pass | fail | pass |

## Notes

| Step | Configuration | Device | What happened |
| --- | --- | --- | --- |
| 3 |  | iPhone | scrolling the map off the top causes the map tiles not to be rendered fully to the bottom of the map view, leaving a gray strip at the bottom of the map view. Map labels are rendered correctly and fully, so this may be a plugin defecct rather than something inherant to using platform views |
|   |  | Pixel 4a 5G | A1+A3 Panning the map causes the overlays to float over the base map - probably caused by the map frame being drawn several frames behind the camera position. |
|   |  | iPhone | Panning the map causes the overlays to float over the base map, but so little that it is almost imperceptible. |
|  | | Pixel 4a 5G | A2 is unusable due to improper positioning and covering Flutter widgets |

## Environment

| Device | OS version | Flutter | Date |
| --- | --- | --- | --- |
| iPhone 15 | 26.7.1 | 3.47.7 | 2026-10-19 |
| Pixel 4a 5G | Android 14 | 3.47.7 | 2026-10-19 |

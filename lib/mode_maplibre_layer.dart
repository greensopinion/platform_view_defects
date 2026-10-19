import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_maplibre/flutter_map_maplibre.dart';
import 'package:maplibre/maplibre.dart';

/// A copy of flutter_map_maplibre 0.0.5's `MapLibreLayer` that also passes the
/// Android platform view options to `MapLibreMap`. `MapLibreLayer` doesn't
/// expose them, so with it the map always uses the `maplibre` defaults.
class ModeMapLibreLayer extends StatefulWidget {
  const ModeMapLibreLayer({
    required this.androidMode,
    required this.androidTextureMode,
    super.key,
  });

  final AndroidPlatformViewMode androidMode;
  final bool androidTextureMode;

  @override
  State<ModeMapLibreLayer> createState() => _ModeMapLibreLayerState();
}

class _ModeMapLibreLayerState extends State<ModeMapLibreLayer> {
  MapController? _controller;
  StreamSubscription<fm.MapEvent>? _streamSub;

  @override
  Widget build(BuildContext context) {
    final fmCamera = fm.MapCamera.of(context);
    final fmController = fm.MapController.of(context);

    _streamSub ??= fmController.mapEventStream.listen((event) {
      if (event case fm.MapEventWithMove()) {
        _controller?.moveCamera(
          center: event.camera.center.toPosition(),
          zoom: event.camera.zoom - 1,
          bearing: -event.camera.rotation,
        );
      }
    });

    return MapLibreMap(
      options: MapOptions(
        initCenter: fmCamera.center.toPosition(),
        initBearing: -fmCamera.rotation,
        initZoom: fmCamera.zoom - 1,
        initStyle: 'https://tiles.openfreemap.org/styles/liberty',
        maxPitch: 0,
        gestures: const MapGestures.none(),
        androidMode: widget.androidMode,
        androidTextureMode: widget.androidTextureMode,
      ),
      gestureRecognizers: const {},
      onMapCreated: (controller) => _controller = controller,
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

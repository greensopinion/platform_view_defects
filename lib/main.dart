import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart';

import 'mode_maplibre_layer.dart';

void main() => runApp(const DefectsApp());

/// The Android platform view configurations under test.
enum AndroidConfig {
  defaults('tlhc_vd, texture (default)', AndroidPlatformViewMode.tlhc_vd, true),
  tlhcHcSurface('tlhc_hc, SurfaceView', AndroidPlatformViewMode.tlhc_hc, false),
  hcSurface('hc, SurfaceView', AndroidPlatformViewMode.hc, false);

  const AndroidConfig(this.label, this.mode, this.textureMode);

  final String label;
  final AndroidPlatformViewMode mode;
  final bool textureMode;
}

class DefectsApp extends StatefulWidget {
  const DefectsApp({super.key});

  @override
  State<DefectsApp> createState() => _DefectsAppState();
}

class _DefectsAppState extends State<DefectsApp> {
  AndroidConfig _config = AndroidConfig.defaults;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final map = TestMap(key: ValueKey(_config), config: _config);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          title: Text(
            isAndroid ? _config.label : 'iOS',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            if (isAndroid)
              PopupMenuButton<AndroidConfig>(
                icon: const Icon(Icons.tune),
                initialValue: _config,
                onSelected: (config) => setState(() => _config = config),
                itemBuilder: (context) => [
                  for (final config in AndroidConfig.values)
                    PopupMenuItem(value: config, child: Text(config.label)),
                ],
              ),
          ],
        ),
        body: switch (_page) {
          0 => SharePage(map: map),
          1 => EffectsPage(map: map),
          _ => ScrollPage(map: map),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _page,
          onDestinationSelected: (page) => setState(() => _page = page),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.ios_share), label: 'Share'),
            NavigationDestination(icon: Icon(Icons.blur_on), label: 'Effects'),
            NavigationDestination(icon: Icon(Icons.list), label: 'Scroll'),
          ],
        ),
      ),
    );
  }
}

/// A `flutter_map` map over London with the MapLibre layer and a few markers.
/// The markers are Flutter widgets, so they show what an effect looks like
/// when Flutter applies it.
class TestMap extends StatelessWidget {
  const TestMap({required this.config, super.key});

  final AndroidConfig config;

  static const _center = LatLng(51.5074, -0.1278);

  @override
  Widget build(BuildContext context) {
    return fm.FlutterMap(
      options: const fm.MapOptions(initialCenter: _center, initialZoom: 13),
      children: [
        ModeMapLibreLayer(
          androidMode: config.mode,
          androidTextureMode: config.textureMode,
        ),
        fm.MarkerLayer(
          markers: [
            for (final (dLat, dLon, color) in const [
              (0.0, 0.0, Colors.red),
              (0.01, 0.02, Colors.blue),
              (-0.01, -0.02, Colors.green),
            ])
              fm.Marker(
                point: LatLng(_center.latitude + dLat, _center.longitude + dLon),
                child: Icon(Icons.location_on, color: color, size: 40),
              ),
          ],
        ),
      ],
    );
  }
}

class SharePage extends StatefulWidget {
  const SharePage({required this.map, super.key});

  final Widget map;

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final _boundaryKey = GlobalKey();

  Future<void> _export() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final rgba = await image.toByteData();
    var transparent = 0;
    for (var i = 3; i < rgba!.lengthInBytes; i += 4) {
      if (rgba.getUint8(i) == 0) transparent++;
    }
    final percent = 100 * transparent / (rgba.lengthInBytes / 4);
    image.dispose();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: Image.memory(png!.buffer.asUint8List()),
            ),
            const SizedBox(height: 8),
            Text('Transparent pixels: ${percent.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Stack(
                children: [
                  widget.map,
                  const Positioned(
                    left: 12,
                    top: 12,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Forecast: 14 °C, light rain'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.image),
              label: const Text('Export image'),
            ),
          ),
        ],
      ),
    );
  }
}

class EffectsPage extends StatefulWidget {
  const EffectsPage({required this.map, super.key});

  final Widget map;

  @override
  State<EffectsPage> createState() => _EffectsPageState();
}

class _EffectsPageState extends State<EffectsPage> {
  bool _blurSheet = false;
  bool _grayscale = false;
  bool _opacity = false;
  bool _fade = false;

  static const _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    Widget map = widget.map;
    if (_grayscale) {
      map = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: map,
      );
    }
    if (_opacity) map = Opacity(opacity: 0.5, child: map);
    if (_fade) {
      map = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: map,
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Stripes show through wherever the map is transparent.
                const Positioned.fill(child: _Stripes()),
                Positioned.fill(child: map),
                if (_blurSheet)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 160,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.2),
                          alignment: Alignment.center,
                          child: const Text(
                            'Blurred sheet',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Blur sheet'),
                selected: _blurSheet,
                onSelected: (v) => setState(() => _blurSheet = v),
              ),
              FilterChip(
                label: const Text('Grayscale'),
                selected: _grayscale,
                onSelected: (v) => setState(() => _grayscale = v),
              ),
              FilterChip(
                label: const Text('Opacity 0.5'),
                selected: _opacity,
                onSelected: (v) => setState(() => _opacity = v),
              ),
              FilterChip(
                label: const Text('Fade'),
                selected: _fade,
                onSelected: (v) => setState(() => _fade = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stripes extends StatelessWidget {
  const _Stripes();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.purple, Colors.yellow, Colors.yellow],
          stops: [0, 0.5, 0.5, 1],
          tileMode: TileMode.repeated,
          end: Alignment(-0.9, -0.9),
        ),
      ),
    );
  }
}

class ScrollPage extends StatelessWidget {
  const ScrollPage({required this.map, super.key});

  final Widget map;

  @override
  Widget build(BuildContext context) {
    Widget card(int n) => Card(
      color: Colors.primaries[n % Colors.primaries.length].shade200,
      child: SizedBox(height: 90, child: Center(child: Text('Card $n'))),
    );
    // The list starts under the translucent app bar, so the map should show
    // through the app bar, and stay clipped to its rounded card, when it is
    // scrolled there.
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top),
        for (var n = 1; n <= 10; n++) card(n),
        Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SizedBox(height: 300, child: map),
        ),
        for (var n = 11; n <= 32; n++) card(n),
      ],
    );
  }
}

import 'package:rive/rive.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'layer.dart';
import 'map_data.dart';

class ProceduralGenerationPage extends StatefulWidget {
  const ProceduralGenerationPage({ Key key }) : super(key: key);

  static const String routeName = '/procedural-generation';

  @override _ProceduralGenerationPageState createState() => _ProceduralGenerationPageState();
}

class _ProceduralGenerationPageState extends State<ProceduralGenerationPage> {
  final TransformationController _transformationController = TransformationController();

  static const double _minScale = 0.5;
  static const double _maxScale = 2.5;
  static const double _scaleRange = _maxScale - _minScale;

  /*
  // Returns true iff the given cell is currently visible. Caches viewport
  // calculations.
  Rect _cachedViewport;
  int _firstVisibleColumn;
  int _firstVisibleRow;
  int _lastVisibleColumn;
  int _lastVisibleRow;
  bool _isCellVisible(int row, int column, Rect viewport) {
    if (viewport != _cachedViewport) {
      _cachedViewport = viewport;
      _firstVisibleRow = (viewport.top / _cellHeight).floor();
      _firstVisibleColumn = (viewport.left / _cellWidth).floor();
      _lastVisibleRow = (viewport.bottom / _cellHeight).floor();
      _lastVisibleColumn = (viewport.right / _cellWidth).floor();
    }
    return row >= _firstVisibleRow && row <= _lastVisibleRow
        && column >= _firstVisibleColumn && column <= _lastVisibleColumn;
  }
  */

  void _onChangeTransformation() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onChangeTransformation);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onChangeTransformation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procedural Generation'),
        actions: <Widget>[
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return InteractiveViewer.builder(
              transformationController: _transformationController,
              maxScale: _maxScale,
              minScale: _minScale,
              builder: (BuildContext context, Rect viewport) {
                final int columns = (viewport.width / cellSize.width).ceil();
                final int rows = (viewport.height / cellSize.height).ceil();

                LayerType layer;
                if (columns > 1000 || rows > 1000) {
                  layer = LayerType.galactic;
                } else if (columns > 100 || rows > 100) {
                  layer = LayerType.solar;
                } else if (columns > 10 || rows > 10) {
                  layer = LayerType.terrestrial;
                } else {
                  layer = LayerType.local;
                }

                return _MapGrid(
                  //columns: (viewport.width / cellSize.width).ceil(),
                  //rows: (viewport.height / cellSize.height).ceil(),
                  columns: columns,
                  rows: rows,
                  firstColumn: (viewport.left / cellSize.width).floor(),
                  firstRow: (viewport.top / cellSize.height).floor(),
                  layer: layer,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MapGrid extends StatelessWidget {
  _MapGrid({
    Key key,
    this.viewport,
    this.columns,
    this.rows,
    this.firstColumn,
    this.firstRow,
    this.layer,
  }) : super(key: key);

  // TODO(justinmc): UI for choosing a seed.
  final MapData _mapData = MapData(seed: 80);
  final Rect viewport;

  final int columns;
  final int rows;
  final int firstColumn;
  final int firstRow;
  final LayerType layer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int row = firstRow; row < firstRow + rows; row++)
          Row(
            children: <Widget>[
              for (int column = firstColumn; column < firstColumn + columns; column++)
                _MapTile(tileData: _mapData.getTileDataAt(Location(
                  row: row,
                  column: column,
                  layerType: LayerType.local,
                ))),
            ],
          ),
      ],
    );
  }
}

class _MapTile extends StatelessWidget {
  _MapTile({
    Key key,
    @required this.tileData,
  }) : super(key: key);

  final TileData tileData;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (tileData.terrain.layer == LayerType.terrestrial && tileData.terrain.terrainType == TerrainType.grassland) {
      child = _Grassland(
        aLocations: tileData.aLocations,
        bLocations: tileData.bLocations,
      );
    } else {
      // TODO(justinmc): Different visuals for different terrains.
      //child = SizedBox.shrink();
      child = _Grassland(
        aLocations: tileData.aLocations,
        bLocations: tileData.bLocations,
      );
    }
      /*
    } else {
      throw new FlutterError('Invalid tile type');
    }
    */

    return Container(
      width: cellSize.width,
      height: cellSize.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black)
      ),
      child: child,
    );
  }
}

class _Grassland extends StatelessWidget {
  const _Grassland({
    this.aLocations,
    this.bLocations,
  });

  final List<Location> aLocations;
  final List<Location> bLocations;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        for (Location location in aLocations)
          Positioned(
            left: location.column * cellSize.width / Layer.layerScale,
            top: location.row * cellSize.height / Layer.layerScale,
            // TODO(justinmc): Make this _Grassland widget a generic widget, and
            // choose child here based on type.
            child: _Grass(),
          ),
        // TODO(justinmc): Something besides grass
          /*
        for (Offset offset in bLocations)
          Positioned(
            left: 50.0,
            top: 0.0,
            child: _Grass(),
          ),
          */
      ],
    );
  }
}

class _Grass extends StatefulWidget {
  const _Grass({
    Key key,
  }) : super(key: key);

  @override _GrassState createState() => _GrassState();
}

class _GrassState extends State<_Grass> {
  Artboard _riveArtboard;
  RiveAnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Load the animation file from the bundle, note that you could also
    // download this. The RiveFile just expects a list of bytes.
    rootBundle.load('assets/grass.riv').then(
      (data) async {
        final file = RiveFile();

        // Load the RiveFile from the binary data.
        if (file.import(data)) {
          // The artboard is the root of the animation and gets drawn in the
          // Rive widget.
          final artboard = file.mainArtboard;
          // Add a controller to play back a known animation on the main/default
          // artboard.We store a reference to it so we can toggle playback.
          _controller = SimpleAnimation('sway');
          artboard.addController(_controller);
          setState(() {
            _riveArtboard = artboard;
            _controller.isActive = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _riveArtboard == null
      ? const SizedBox()
      : SizedBox(
          width: 20.0,
          height: 20.0,
          child: Rive(artboard: _riveArtboard),
        );
  }
}

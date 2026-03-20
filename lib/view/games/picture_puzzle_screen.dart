import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class PicturePuzzleScreen extends StatefulWidget {
  const PicturePuzzleScreen({super.key});

  @override
  State<PicturePuzzleScreen> createState() => _PicturePuzzleScreenState();
}

class _PicturePuzzleScreenState extends State<PicturePuzzleScreen> {
  final Random _random = Random();
  List<int> _tiles = const [];
  int _level = 1;
  int _bestUnlockedLevel = 1;
  int _gridSize = 3;
  int _seed = 1;
  int? _selectedTile;
  bool _celebrating = false;
  String _message = 'Tap one tile, then tap another tile to swap them.';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    _bestUnlockedLevel = snapshot.picturePuzzleLevel;
    _startLevel(snapshot.picturePuzzleLevel);
  }

  void _startLevel(int level) {
    final sizeBoost = ((level - 1) ~/ 3).clamp(0, 2);
    final gridSize = 3 + sizeBoost;
    final tiles = List<int>.generate(gridSize * gridSize, (index) => index);
    do {
      tiles.shuffle(_random);
    } while (_isSolved(tiles));

    setState(() {
      _level = level;
      _gridSize = gridSize;
      _tiles = tiles;
      _seed = _random.nextInt(1 << 31);
      _selectedTile = null;
      _celebrating = false;
      _message = 'Swap the tiles to rebuild the full picture.';
    });
  }

  bool _isSolved(List<int> board) {
    for (var i = 0; i < board.length; i++) {
      if (board[i] != i) return false;
    }
    return true;
  }

  Future<void> _handleTileTap(int index) async {
    if (_celebrating || _tiles.isEmpty) return;
    if (_selectedTile == null) {
      setState(() {
        _selectedTile = index;
        _message = 'Now tap another tile to swap.';
      });
      return;
    }

    if (_selectedTile == index) {
      setState(() {
        _selectedTile = null;
        _message = 'Selection cleared. Pick two tiles to swap.';
      });
      return;
    }

    final nextTiles = List<int>.from(_tiles);
    final first = _selectedTile!;
    final temp = nextTiles[first];
    nextTiles[first] = nextTiles[index];
    nextTiles[index] = temp;

    final solved = _isSolved(nextTiles);
    setState(() {
      _tiles = nextTiles;
      _selectedTile = null;
      _celebrating = solved;
      _message = solved
          ? 'Picture complete. New puzzle loading...'
          : 'Good swap. Keep rebuilding the image.';
    });

    if (!solved) return;

    final nextLevel = _level + 1;
    if (nextLevel > _bestUnlockedLevel) {
      _bestUnlockedLevel = nextLevel;
      await GameStatsStore.instance.recordPicturePuzzleLevel(nextLevel);
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _startLevel(nextLevel);
  }

  void _restartLevel() {
    _startLevel(_level);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Picture Puzzle',
      subtitle: 'Match the avatar picture shown above by swapping the tiles.',
      accent: const [Color(0xff38bdf8), Color(0xff22c55e)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Saved',
            rightValue: _bestUnlockedLevel.toString(),
            footer: 'Grid ${_gridSize}x$_gridSize • Match the avatar reference',
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.image_search_rounded,
                            color: Color(0xfffacc15),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reference picture',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 112,
                              height: 112,
                              child: CustomPaint(
                                painter: _PictureReferencePainter(seed: _seed),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Build this avatar. Match the face, hair, shirt, and background by swapping the puzzle pieces below.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Color(0xff67e8f9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Touch only: tap one piece, then tap another piece to swap. Keep checking the avatar picture above.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tiles.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemBuilder: (context, index) {
                          final selected = _selectedTile == index;
                          return GestureDetector(
                            onTap: () => _handleTileTap(index),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 140),
                              scale: selected ? 0.96 : 1,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xfffacc15)
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: selected ? 3 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: CustomPaint(
                                    painter: _PictureTilePainter(
                                      seed: _seed,
                                      gridSize: _gridSize,
                                      tileIndex: _tiles[index],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_celebrating)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.celebration_rounded,
                                      color: Color(0xfffacc15),
                                      size: 54,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Puzzle complete!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff22c55e)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _celebrating ? null : _restartLevel,
              child: const Text('Shuffle this level again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureTilePainter extends CustomPainter {
  _PictureTilePainter({
    required this.seed,
    required this.gridSize,
    required this.tileIndex,
  });

  final int seed;
  final int gridSize;
  final int tileIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final tileRow = tileIndex ~/ gridSize;
    final tileCol = tileIndex % gridSize;
    final fullSize = Size(size.width * gridSize, size.height * gridSize);

    canvas.save();
    canvas.translate(-(tileCol * size.width), -(tileRow * size.height));
    _paintFullScene(canvas, fullSize);
    canvas.restore();

    final divider = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(11)),
      divider,
    );
  }

  void _paintFullScene(Canvas canvas, Size fullSize) {
    _paintAvatarScene(canvas, fullSize, seed);
  }

  @override
  bool shouldRepaint(covariant _PictureTilePainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.tileIndex != tileIndex;
  }
}

class _PictureReferencePainter extends CustomPainter {
  const _PictureReferencePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    _paintAvatarScene(canvas, size, seed);
  }

  @override
  bool shouldRepaint(covariant _PictureReferencePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}

void _paintAvatarScene(Canvas canvas, Size size, int seed) {
  final random = Random(seed);
  final backgroundPalettes = [
    [const Color(0xff1d4ed8), const Color(0xff38bdf8)],
    [const Color(0xff7c3aed), const Color(0xffc084fc)],
    [const Color(0xffbe123c), const Color(0xfffb7185)],
    [const Color(0xff065f46), const Color(0xff34d399)],
  ];
  final hairColors = [
    const Color(0xff1f2937),
    const Color(0xff7c2d12),
    const Color(0xff92400e),
    const Color(0xff5b21b6),
  ];
  final shirtColors = [
    const Color(0xfff97316),
    const Color(0xff22c55e),
    const Color(0xff38bdf8),
    const Color(0xfff43f5e),
  ];
  final skinTones = [
    const Color(0xfff5c9a5),
    const Color(0xffe8b589),
    const Color(0xffd99a6c),
    const Color(0xffb8794f),
  ];

  final background = backgroundPalettes[seed % backgroundPalettes.length];
  final hair = hairColors[(seed ~/ 3) % hairColors.length];
  final shirt = shirtColors[(seed ~/ 5) % shirtColors.length];
  final skin = skinTones[(seed ~/ 7) % skinTones.length];
  final eyeOffset = 0.08 + random.nextDouble() * 0.02;

  final skyPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: background,
    ).createShader(Offset.zero & size);
  canvas.drawRect(Offset.zero & size, skyPaint);

  final glowPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
  canvas.drawCircle(
    Offset(size.width * 0.22, size.height * 0.18),
    size.width * 0.12,
    glowPaint,
  );

  final floorPaint = Paint()..color = Colors.black.withValues(alpha: 0.14);
  canvas.drawRect(
    Rect.fromLTWH(0, size.height * 0.76, size.width, size.height * 0.24),
    floorPaint,
  );

  final shoulderPaint = Paint()..color = shirt;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.88),
        width: size.width * 0.64,
        height: size.height * 0.34,
      ),
      Radius.circular(size.width * 0.12),
    ),
    shoulderPaint,
  );

  final neckPaint = Paint()..color = skin;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.62),
        width: size.width * 0.12,
        height: size.height * 0.08,
      ),
      Radius.circular(size.width * 0.03),
    ),
    neckPaint,
  );

  final faceRect = Rect.fromCenter(
    center: Offset(size.width * 0.5, size.height * 0.42),
    width: size.width * 0.46,
    height: size.height * 0.5,
  );
  final facePaint = Paint()..color = skin;
  canvas.drawOval(faceRect, facePaint);

  final hairPaint = Paint()..color = hair;
  final hairPath = Path()
    ..moveTo(
      faceRect.left + size.width * 0.02,
      faceRect.top + faceRect.height * 0.28,
    )
    ..quadraticBezierTo(
      faceRect.center.dx,
      faceRect.top - faceRect.height * 0.34,
      faceRect.right - size.width * 0.02,
      faceRect.top + faceRect.height * 0.28,
    )
    ..lineTo(faceRect.right, faceRect.center.dy)
    ..quadraticBezierTo(
      faceRect.center.dx,
      faceRect.top + faceRect.height * 0.1,
      faceRect.left,
      faceRect.center.dy,
    )
    ..close();
  canvas.drawPath(hairPath, hairPaint);

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(faceRect.center.dx, faceRect.top + faceRect.height * 0.18),
      width: faceRect.width * 0.52,
      height: faceRect.height * 0.24,
    ),
    hairPaint,
  );

  final eyePaint = Paint()..color = const Color(0xff0f172a);
  canvas.drawCircle(
    Offset(
      faceRect.center.dx - faceRect.width * 0.16,
      faceRect.top + faceRect.height * (0.46 + eyeOffset),
    ),
    size.width * 0.022,
    eyePaint,
  );
  canvas.drawCircle(
    Offset(
      faceRect.center.dx + faceRect.width * 0.16,
      faceRect.top + faceRect.height * (0.46 - eyeOffset / 2),
    ),
    size.width * 0.022,
    eyePaint,
  );

  final blushPaint = Paint()
    ..color = const Color(0xfffb7185).withValues(alpha: 0.18);
  canvas.drawCircle(
    Offset(
      faceRect.center.dx - faceRect.width * 0.2,
      faceRect.top + faceRect.height * 0.66,
    ),
    size.width * 0.04,
    blushPaint,
  );
  canvas.drawCircle(
    Offset(
      faceRect.center.dx + faceRect.width * 0.2,
      faceRect.top + faceRect.height * 0.66,
    ),
    size.width * 0.04,
    blushPaint,
  );

  final smilePaint = Paint()
    ..color = const Color(0xff7f1d1d)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.018
    ..strokeCap = StrokeCap.round;
  final smileRect = Rect.fromCenter(
    center: Offset(faceRect.center.dx, faceRect.top + faceRect.height * 0.74),
    width: faceRect.width * 0.2,
    height: faceRect.height * 0.1,
  );
  canvas.drawArc(smileRect, 0.2, 2.8, false, smilePaint);

  final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
  for (var i = 0; i < 5; i++) {
    final dx = size.width * (0.12 + (i * 0.18));
    final dy = size.height * (0.12 + ((i % 2) * 0.06));
    canvas.drawCircle(Offset(dx, dy), size.width * 0.014, sparklePaint);
  }
}

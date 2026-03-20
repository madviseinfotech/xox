import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class BrickBreakerScreen extends StatefulWidget {
  const BrickBreakerScreen({super.key});

  @override
  State<BrickBreakerScreen> createState() => _BrickBreakerScreenState();
}

class _BrickBreakerScreenState extends State<BrickBreakerScreen> {
  static const int _baseRows = 4;
  static const int _columns = 6;
  static const double _ballRadius = 0.022;
  static const double _paddleWidth = 0.22;
  static const double _paddleHeight = 0.03;
  static const double _paddleY = 0.92;

  final List<_Brick> _bricks = [];
  final math.Random _random = math.Random();
  Timer? _timer;

  double _paddleX = 0.5;
  double _ballX = 0.5;
  double _ballY = 0.7;
  double _ballDx = 0.008;
  double _ballDy = -0.011;
  bool _running = false;
  bool _roundStarted = false;
  int _level = 1;
  int _score = 0;
  int _bestScore = 0;
  int _lives = 3;
  String _message = 'Tap start, bounce the ball, and break every brick.';

  @override
  void initState() {
    super.initState();
    _loadBest();
    _prepareLevel(resetProgress: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestScore = snapshot.brickBreakerBestScore;
    });
  }

  void _prepareLevel({bool resetProgress = false}) {
    _timer?.cancel();
    _bricks
      ..clear()
      ..addAll(_buildBricks(_level));
    _paddleX = 0.5;
    _ballX = 0.5;
    _ballY = 0.7;
    _ballDx = _random.nextBool() ? 0.0085 : -0.0085;
    _ballDy = -(0.0105 + ((_level - 1) * 0.0007));
    _running = false;
    _roundStarted = !resetProgress;
  }

  List<_Brick> _buildBricks(int level) {
    final bricks = <_Brick>[];
    const top = 0.10;
    const spacing = 0.015;
    final brickWidth = (1 - (spacing * (_columns + 1))) / _columns;
    const brickHeight = 0.055;
    final rowCount = math.min(_baseRows + level - 1, 7);

    for (var row = 0; row < rowCount; row++) {
      for (var column = 0; column < _columns; column++) {
        final x = spacing + column * (brickWidth + spacing);
        final y = top + row * (brickHeight + spacing);
        final hits = row >= 4
            ? 2 + ((level >= 4 && column.isEven) ? 1 : 0)
            : level >= 3 && (row + column).isOdd
            ? 2
            : 1;
        bricks.add(
          _Brick(
            rect: Rect.fromLTWH(x, y, brickWidth, brickHeight),
            color: [
              const Color(0xfffb7185),
              const Color(0xfff59e0b),
              const Color(0xff22c55e),
              const Color(0xff38bdf8),
              const Color(0xffa78bfa),
            ][row % 5],
            hitsRemaining: hits,
          ),
        );
      }
    }
    return bricks;
  }

  void _startRound() {
    if (_running) return;
    setState(() {
      _running = true;
      _roundStarted = true;
      _message = 'Keep the ball alive and clear the wall.';
    });

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) async {
      if (!mounted || !_running) return;

      var nextBallX = _ballX + _ballDx;
      var nextBallY = _ballY + _ballDy;
      var nextDx = _ballDx;
      var nextDy = _ballDy;
      var gainedScore = 0;
      var hitBrick = false;

      if (nextBallX - _ballRadius <= 0 || nextBallX + _ballRadius >= 1) {
        nextDx = -nextDx;
        nextBallX = _ballX + nextDx;
      }
      if (nextBallY - _ballRadius <= 0) {
        nextDy = -nextDy;
        nextBallY = _ballY + nextDy;
      }

      final paddleRect = Rect.fromCenter(
        center: Offset(_paddleX, _paddleY),
        width: _paddleWidth,
        height: _paddleHeight,
      );
      final ballRect = Rect.fromCircle(
        center: Offset(nextBallX, nextBallY),
        radius: _ballRadius,
      );

      if (ballRect.overlaps(paddleRect) && nextDy > 0) {
        final hitOffset = (nextBallX - _paddleX) / (_paddleWidth / 2);
        nextDx = hitOffset * 0.012;
        nextDy = -nextDy.abs();
        nextBallY = _ballY + nextDy;
      }

      final remainingBricks = <_Brick>[];
      for (final brick in _bricks) {
        if (!hitBrick && ballRect.overlaps(brick.rect)) {
          nextDy = -nextDy;
          gainedScore += 10;
          hitBrick = true;
          if (brick.hitsRemaining > 1) {
            remainingBricks.add(
              brick.copyWith(hitsRemaining: brick.hitsRemaining - 1),
            );
          }
          continue;
        }
        remainingBricks.add(brick);
      }

      if (remainingBricks.isEmpty) {
        final nextScore = _score + gainedScore + (50 * _level);
        await _advanceLevel(nextScore);
        timer.cancel();
        return;
      }

      if (nextBallY - _ballRadius > 1) {
        final nextLives = _lives - 1;
        if (nextLives <= 0) {
          final nextScore = _score + gainedScore;
          await _finishRound(
            score: nextScore,
            message: 'Ball lost. Your final score was $nextScore.',
          );
          timer.cancel();
          return;
        }

        setState(() {
          _lives = nextLives;
          _score += gainedScore;
          _bricks
            ..clear()
            ..addAll(remainingBricks);
          _running = false;
          _roundStarted = true;
          _ballX = _paddleX;
          _ballY = 0.7;
          _ballDx = _random.nextBool() ? 0.008 : -0.008;
          _ballDy = -(0.0105 + ((_level - 1) * 0.0007));
          _message = 'Nice save. $nextLives lives left. Tap start again.';
        });
        timer.cancel();
        return;
      }

      setState(() {
        _score += gainedScore;
        _ballX = nextBallX;
        _ballY = nextBallY;
        _ballDx = nextDx;
        _ballDy = nextDy;
        _bricks
          ..clear()
          ..addAll(remainingBricks);
        if (gainedScore > 0) {
          _message = 'Brick smashed. Keep going.';
        }
      });
    });
  }

  Future<void> _advanceLevel(int nextScore) async {
    final isBest = nextScore > _bestScore;
    if (isBest) {
      await GameStatsStore.instance.recordBrickBreakerBestScore(nextScore);
    }
    if (!mounted) return;
    setState(() {
      _score = nextScore;
      if (isBest) {
        _bestScore = nextScore;
      }
      _level += 1;
      _message = 'Level ${_level - 1} clear. Level $_level is ready.';
      _prepareLevel();
    });
  }

  Future<void> _finishRound({
    required int score,
    required String message,
  }) async {
    final isBest = score > _bestScore;
    if (isBest) {
      await GameStatsStore.instance.recordBrickBreakerBestScore(score);
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _score = score;
      if (isBest) {
        _bestScore = score;
      }
      _message = isBest ? 'New best. $message' : message;
    });
  }

  void _movePaddleTo(double localDx, double width) {
    setState(() {
      _setPaddleX(localDx / width);
    });
  }

  void _setPaddleX(double nextX) {
    _paddleX = nextX.clamp(_paddleWidth / 2, 1 - _paddleWidth / 2);
    if (!_running) {
      _ballX = _paddleX;
    }
  }

  void _restartGame() {
    setState(() {
      _level = 1;
      _score = 0;
      _lives = 3;
      _message = 'Tap start, bounce the ball, and break every brick.';
      _prepareLevel(resetProgress: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Brick Breaker',
      subtitle: 'Move the paddle, bounce the ball, and clear the wall.',
      accent: const [Color(0xff38bdf8), Color(0xff8b5cf6)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Lives',
            rightValue: _lives.toString(),
            footer:
                'Score $_score • Best $_bestScore • Bricks left ${_bricks.length}',
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: AspectRatio(
              aspectRatio: 0.8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      _movePaddleTo(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                    },
                    onHorizontalDragUpdate: (details) {
                      _movePaddleTo(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xff0f172a), Color(0xff111827)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          ..._bricks.map((brick) {
                            return Positioned(
                              left: brick.rect.left * constraints.maxWidth,
                              top: brick.rect.top * constraints.maxHeight,
                              child: Container(
                                width: brick.rect.width * constraints.maxWidth,
                                height:
                                    brick.rect.height * constraints.maxHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: brick.hitsRemaining == 1
                                      ? brick.color
                                      : brick.color.withValues(alpha: 0.72),
                                  border: Border.all(
                                    color: brick.hitsRemaining == 1
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.32),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: brick.color.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: brick.hitsRemaining == 1
                                    ? null
                                    : Center(
                                        child: Text(
                                          '${brick.hitsRemaining}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          }),
                          Positioned(
                            left:
                                (_paddleX - (_paddleWidth / 2)) *
                                constraints.maxWidth,
                            top:
                                (_paddleY - (_paddleHeight / 2)) *
                                constraints.maxHeight,
                            child: Container(
                              width: _paddleWidth * constraints.maxWidth,
                              height: _paddleHeight * constraints.maxHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff67e8f9),
                                    Color(0xff3b82f6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (_ballX - _ballRadius) * constraints.maxWidth,
                            top: (_ballY - _ballRadius) * constraints.maxHeight,
                            child: Container(
                              width: _ballRadius * 2 * constraints.maxWidth,
                              height: _ballRadius * 2 * constraints.maxHeight,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!_roundStarted || !_running)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Center(
                                  child: Text(
                                    _roundStarted
                                        ? 'Touch anywhere to move paddle\nTap Start for Level $_level'
                                        : 'Touch or drag to move paddle\nBreak bricks to level up',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff8b5cf6)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _startRound,
                  child: Text(_running ? 'Running...' : 'Start'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Restart game', onPressed: _restartGame),
        ],
      ),
    );
  }
}

class _Brick {
  const _Brick({
    required this.rect,
    required this.color,
    required this.hitsRemaining,
  });

  final Rect rect;
  final Color color;
  final int hitsRemaining;

  _Brick copyWith({Rect? rect, Color? color, int? hitsRemaining}) {
    return _Brick(
      rect: rect ?? this.rect,
      color: color ?? this.color,
      hitsRemaining: hitsRemaining ?? this.hitsRemaining,
    );
  }
}

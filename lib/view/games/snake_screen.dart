import 'dart:async';
import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  static const int _boardSize = 10;

  final Random _random = Random();
  Timer? _timer;

  List<int> _snake = [14, 13, 12];
  int _food = 50;
  _Direction _direction = _Direction.right;
  _Direction _queuedDirection = _Direction.right;
  bool _running = false;
  bool _gameOver = false;
  int _bestLength = 3;
  String _message = 'Tap start, then guide the snake to the food.';

  @override
  void initState() {
    super.initState();
    _placeFood();
    _loadBest();
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
      _bestLength = snapshot.snakeBestLength == 0
          ? 3
          : snapshot.snakeBestLength;
    });
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _snake = [14, 13, 12];
      _food = 50;
      _direction = _Direction.right;
      _queuedDirection = _Direction.right;
      _running = true;
      _gameOver = false;
      _message = 'Collect food and avoid the walls.';
    });
    _placeFood();
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running) return;
    _direction = _queuedDirection;
    final head = _snake.first;
    final next = switch (_direction) {
      _Direction.up => head - _boardSize,
      _Direction.down => head + _boardSize,
      _Direction.left => head - 1,
      _Direction.right => head + 1,
    };

    final hitWall =
        next < 0 ||
        next >= _boardSize * _boardSize ||
        (_direction == _Direction.left && head % _boardSize == 0) ||
        (_direction == _Direction.right && head % _boardSize == _boardSize - 1);
    final hitSelf = _snake.contains(next) && next != _snake.last;

    if (hitWall || hitSelf) {
      await _endGame();
      return;
    }

    final nextSnake = [next, ..._snake];
    if (next == _food) {
      if (nextSnake.length > _bestLength) {
        _bestLength = nextSnake.length;
        GameStatsStore.instance.recordSnakeBestLength(_bestLength);
      }
      setState(() {
        _snake = nextSnake;
        _message = 'Nice. Length ${_snake.length}. Keep going.';
      });
      _placeFood();
      return;
    }

    nextSnake.removeLast();
    setState(() {
      _snake = nextSnake;
    });
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    setState(() {
      _running = false;
      _gameOver = true;
      _message = 'Game over. Final length ${_snake.length}.';
    });
    GameStatsStore.instance.recordSnakeBestLength(_snake.length);
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
  }

  void _placeFood() {
    int nextFood = _food;
    do {
      nextFood = _random.nextInt(_boardSize * _boardSize);
    } while (_snake.contains(nextFood));
    setState(() {
      _food = nextFood;
    });
  }

  void _changeDirection(_Direction direction) {
    if ((_direction == _Direction.up && direction == _Direction.down) ||
        (_direction == _Direction.down && direction == _Direction.up) ||
        (_direction == _Direction.left && direction == _Direction.right) ||
        (_direction == _Direction.right && direction == _Direction.left)) {
      return;
    }
    setState(() {
      _queuedDirection = direction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Snake',
      subtitle: 'Grow fast, dodge walls, and stay in control.',
      accent: const [Color(0xff22c55e), Color(0xff84cc16)],
      scrollable: false,
      compactHeader: true,
      minimalHeader: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CompactMetricCard(
                      label: 'Length',
                      value: _snake.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CompactMetricCard(
                      label: 'Best',
                      value: _bestLength.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              InlineStatusStrip(
                message: _message,
                accent: _gameOver
                    ? const Color(0xffef4444)
                    : const Color(0xff84cc16),
                compact: true,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight * 0.86,
                    ),
                    child: GamePanel(
                      padding: const EdgeInsets.all(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          itemCount: _boardSize * _boardSize,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _boardSize,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                          itemBuilder: (context, index) {
                            final isHead = index == _snake.first;
                            final isBody = _snake.contains(index);
                            final isFood = index == _food;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isFood
                                    ? const Color(0xffef4444)
                                    : isHead
                                    ? const Color(0xffbef264)
                                    : isBody
                                    ? const Color(0xff22c55e)
                                    : const Color(0xff132033),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _DirectionPad(onPressed: _changeDirection)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: math.min(132, constraints.maxWidth * 0.32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _running ? null : _startGame,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: Text(_running ? 'Running...' : 'Start'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _startGame,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Restart'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onPressed});

  final ValueChanged<_Direction> onPressed;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, _Direction direction) {
      return SizedBox(
        width: 68,
        height: 42,
        child: ElevatedButton(
          onPressed: () => onPressed(direction),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon),
        ),
      );
    }

    return Column(
      children: [
        arrow(Icons.keyboard_arrow_up_rounded, _Direction.up),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            arrow(Icons.keyboard_arrow_left_rounded, _Direction.left),
            const SizedBox(width: 12),
            arrow(Icons.keyboard_arrow_right_rounded, _Direction.right),
          ],
        ),
        const SizedBox(height: 8),
        arrow(Icons.keyboard_arrow_down_rounded, _Direction.down),
      ],
    );
  }
}

enum _Direction { up, down, left, right }

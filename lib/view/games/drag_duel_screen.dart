import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class DragDuelScreen extends StatefulWidget {
  const DragDuelScreen({super.key});

  @override
  State<DragDuelScreen> createState() => _DragDuelScreenState();
}

class _DragDuelScreenState extends State<DragDuelScreen> {
  static const double _finishLine = 100.0;
  static const Duration _tick = Duration(milliseconds: 40);

  Timer? _timer;
  final Stopwatch _clock = Stopwatch();

  double _p1dist = 0;
  double _p2dist = 0;
  double _p1speed = 0;
  double _p2speed = 0;
  int _p1wins = 0;
  int _p2wins = 0;
  int _round = 0;
  bool _p1held = false;
  bool _p2held = false;
  bool _running = false;
  bool _finished = false;
  bool _countdown = false;
  int _countdownVal = 3;
  String _winner = '';
  String _message = 'Player 1 taps LEFT side. Player 2 taps RIGHT side. Race to the finish!';

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }

  Future<void> _startRound() async {
    _timer?.cancel();
    _clock.stop();
    _clock.reset();
    setState(() {
      _p1dist = 0;
      _p2dist = 0;
      _p1speed = 0;
      _p2speed = 0;
      _p1held = false;
      _p2held = false;
      _running = false;
      _finished = false;
      _countdown = true;
      _countdownVal = 3;
      _winner = '';
      _message = 'Get ready...';
    });

    for (int i = 3; i >= 1; i--) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _countdownVal = i);
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _countdown = false;
      _running = true;
      _countdownVal = 0;
      _message = 'GO! Hold your side to accelerate!';
    });
    _clock.start();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (!_running || !mounted) return;

    // P1 speed
    double s1 = _p1speed;
    if (_p1held) {
      s1 += 0.6;
    } else {
      s1 -= 0.4;
    }
    s1 = s1.clamp(0.0, 8.0);

    // P2 speed
    double s2 = _p2speed;
    if (_p2held) {
      s2 += 0.6;
    } else {
      s2 -= 0.4;
    }
    s2 = s2.clamp(0.0, 8.0);

    final d1 = _p1dist + s1;
    final d2 = _p2dist + s2;

    if (d1 >= _finishLine || d2 >= _finishLine) {
      _timer?.cancel();
      _clock.stop();
      String winner;
      if (d1 >= _finishLine && d2 >= _finishLine) {
        winner = 'TIE!';
      } else if (d1 >= _finishLine) {
        winner = 'Player 1 Wins!';
        _p1wins++;
      } else {
        winner = 'Player 2 Wins!';
        _p2wins++;
      }
      _round++;
      setState(() {
        _p1dist = d1.clamp(0, _finishLine);
        _p2dist = d2.clamp(0, _finishLine);
        _p1speed = s1;
        _p2speed = s2;
        _running = false;
        _finished = true;
        _p1held = false;
        _p2held = false;
        _winner = winner;
        _message = '$winner  Round $_round complete.';
      });
      GameInterstitialService.instance.registerRoundCompletion();
      if (_round % 3 == 0) {
        unawaited(GameInterstitialService.instance.maybeShow());
      }
      return;
    }

    setState(() {
      _p1dist = d1;
      _p2dist = d2;
      _p1speed = s1;
      _p2speed = s2;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xffef4444), Color(0xff3b82f6)];
    final p1progress = (_p1dist / _finishLine).clamp(0.0, 1.0);
    final p2progress = (_p2dist / _finishLine).clamp(0.0, 1.0);

    return GameScaffold(
      title: 'Drag Duel',
      subtitle: '2 players, same screen. Hold your side to race to the finish.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'P1 Wins',
            leftValue: '$_p1wins',
            rightLabel: 'P2 Wins',
            rightValue: '$_p2wins',
            footer: 'Round $_round  •  Best of any number',
          ),
          const SizedBox(height: 14),
          StatusCard(
            message: _countdown
                ? (_countdownVal > 0 ? '$_countdownVal...' : 'GO!')
                : _message,
            accent: _finished
                ? (_winner.contains('1')
                      ? const Color(0xffef4444)
                      : _winner.contains('2')
                      ? const Color(0xff3b82f6)
                      : const Color(0xfffacc15))
                : const Color(0xfff97316),
            highlight: _finished || _countdown,
            headline: _finished ? _winner : null,
          ),
          const SizedBox(height: 14),
          // Track
          GamePanel(
            child: Column(
              children: [
                _TrackLane(
                  label: 'Player 1',
                  color: const Color(0xffef4444),
                  progress: p1progress,
                  speed: _p1speed,
                  held: _p1held,
                ),
                const SizedBox(height: 16),
                _TrackLane(
                  label: 'Player 2',
                  color: const Color(0xff3b82f6),
                  progress: p2progress,
                  speed: _p2speed,
                  held: _p2held,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Controls
          SizedBox(
            height: 120,
            child: Row(
              children: [
                // P1 button
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (_running) setState(() => _p1held = true);
                    },
                    onTapUp: (_) => setState(() => _p1held = false),
                    onTapCancel: () => setState(() => _p1held = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _p1held
                            ? const Color(0xffef4444).withValues(alpha: 0.35)
                            : const Color(0xffef4444).withValues(alpha: 0.14),
                        border: Border.all(
                          color: const Color(0xffef4444).withValues(
                            alpha: _p1held ? 0.9 : 0.35,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: const Color(0xffef4444),
                            size: _p1held ? 36 : 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PLAYER 1',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: _p1held ? 15 : 13,
                            ),
                          ),
                          Text(
                            'Hold to race',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Middle start button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      child: ElevatedButton(
                        onPressed: _running || _countdown ? null : _startRound,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _finished ? 'Again' : 'Start',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // P2 button
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (_running) setState(() => _p2held = true);
                    },
                    onTapUp: (_) => setState(() => _p2held = false),
                    onTapCancel: () => setState(() => _p2held = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _p2held
                            ? const Color(0xff3b82f6).withValues(alpha: 0.35)
                            : const Color(0xff3b82f6).withValues(alpha: 0.14),
                        border: Border.all(
                          color: const Color(0xff3b82f6).withValues(
                            alpha: _p2held ? 0.9 : 0.35,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: const Color(0xff3b82f6),
                            size: _p2held ? 36 : 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PLAYER 2',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: _p2held ? 15 : 13,
                            ),
                          ),
                          Text(
                            'Hold to race',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackLane extends StatelessWidget {
  const _TrackLane({
    required this.label,
    required this.color,
    required this.progress,
    required this.speed,
    required this.held,
  });

  final String label;
  final Color color;
  final double progress;
  final double speed;
  final bool held;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '${(speed * 30).round()} km/h',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              // Finish line
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
              // Car
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxLeft = constraints.maxWidth - 40.0;
                  final left = (progress * maxLeft).clamp(0.0, maxLeft);
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 40),
                    curve: Curves.linear,
                    left: left,
                    top: 4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: color,
                        boxShadow: held
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class PenaltyKickScreen extends StatefulWidget {
  const PenaltyKickScreen({super.key});

  @override
  State<PenaltyKickScreen> createState() => _PenaltyKickScreenState();
}

class _PenaltyKickScreenState extends State<PenaltyKickScreen> {
  static const int _laneCount = 5;

  final Random _random = Random();

  Timer? _aimTimer;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _keeperLane = 2;
  int _aimLane = 0;
  int _aimDirection = 1;
  bool _roundActive = false;
  String _message = 'Time your shot and avoid the keeper.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  @override
  void dispose() {
    _aimTimer?.cancel();
    super.dispose();
  }

  void _startRound({bool resetGame = false}) {
    _aimTimer?.cancel();
    final keeperLane = _random.nextInt(_laneCount);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _keeperLane = keeperLane;
      _aimLane = _random.nextInt(_laneCount);
      _aimDirection = _random.nextBool() ? 1 : -1;
      _roundActive = true;
      _message = 'Shoot into an open lane. The keeper blocks one target.';
    });

    _aimTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted || !_roundActive) return;
      setState(() {
        final nextLane = _aimLane + _aimDirection;
        if (nextLane < 0 || nextLane >= _laneCount) {
          _aimDirection *= -1;
          _aimLane += _aimDirection;
        } else {
          _aimLane = nextLane;
        }
      });
    });
  }

  Future<void> _shoot() async {
    if (!_roundActive || _lives == 0) return;
    _aimTimer?.cancel();

    final scored = _aimLane != _keeperLane;
    setState(() {
      _roundActive = false;
      if (scored) {
        _score += 1;
        _message = 'Goal! Clean finish into lane ${_aimLane + 1}.';
      } else {
        _lives -= 1;
        _message = _lives == 0
            ? 'Saved by the keeper. Match over.'
            : 'Saved. $_lives lives left, line up the next shot.';
      }
    });

    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted || _lives == 0) return;

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _round += 1;
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff22c55e), Color(0xff0ea5e9)];
    return GameScaffold(
      title: 'Penalty Kick',
      subtitle: 'Stop the moving aim and slot your shot away from the keeper.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Goals',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Lanes: $_laneCount',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick the open lane',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The blue marker moves left and right. Tap shoot before it lands on the keeper lane.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: List.generate(_laneCount, (index) {
                    final blocked = index == _keeperLane;
                    final aimed = index == _aimLane;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        margin: EdgeInsets.only(
                          right: index == _laneCount - 1 ? 0 : 10,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: blocked
                              ? const Color(0xff0f172a)
                              : Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: aimed
                                ? const Color(0xff38bdf8)
                                : blocked
                                ? const Color(0xff22c55e)
                                : Colors.white.withValues(alpha: 0.08),
                            width: aimed ? 2.4 : 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              blocked ? 'GK' : 'GOAL',
                              style: TextStyle(
                                color: blocked
                                    ? const Color(0xff86efac)
                                    : Colors.white70,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedScale(
                              scale: aimed ? 1.08 : 1,
                              duration: const Duration(milliseconds: 140),
                              child: Text(
                                aimed
                                    ? '⚽'
                                    : blocked
                                    ? '🧤'
                                    : ' ',
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _roundActive && _lives > 0 ? _shoot : null,
                    child: Text(_lives == 0 ? 'Match finished' : 'Shoot'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}

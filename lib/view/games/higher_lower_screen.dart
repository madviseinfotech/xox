import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class HigherLowerScreen extends StatefulWidget {
  const HigherLowerScreen({super.key});

  @override
  State<HigherLowerScreen> createState() => _HigherLowerScreenState();
}

class _HigherLowerScreenState extends State<HigherLowerScreen> {
  final Random _random = Random();

  int _current = 0;
  int? _nextPreview;
  int _currentStreak = 0;
  int _bestStreak = 0;
  String _message = 'Predict whether the next card will be higher or lower.';

  @override
  void initState() {
    super.initState();
    _startFresh();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestStreak = snapshot.higherLowerBestStreak;
    });
  }

  void _startFresh() {
    setState(() {
      _current = _drawCard();
      _nextPreview = null;
      _currentStreak = 0;
      _message = 'Predict whether the next card will be higher or lower.';
    });
  }

  int _drawCard() => _random.nextInt(13) + 1;

  Future<void> _makeGuess(bool guessHigher) async {
    final next = _drawCard();
    final isCorrect = guessHigher ? next >= _current : next <= _current;
    final newStreak = isCorrect ? _currentStreak + 1 : 0;

    if (isCorrect && newStreak > _bestStreak) {
      _bestStreak = newStreak;
      await GameStatsStore.instance.recordHigherLowerStreak(newStreak);
    }

    setState(() {
      _nextPreview = next;
      _message = isCorrect
          ? 'Nice call. ${_labelFor(next)} was ${guessHigher ? 'higher' : 'lower'} than ${_labelFor(_current)}.'
          : 'Missed it. ${_labelFor(next)} broke the streak.';
      _current = next;
      _currentStreak = newStreak;
    });
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
  }

  String _labelFor(int value) {
    switch (value) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Higher or Lower',
      subtitle: 'Keep a streak alive by calling the next card value.',
      accent: const [Color(0xffef4444), Color(0xfff59e0b)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Streak',
            leftValue: _currentStreak.toString(),
            rightLabel: 'Best',
            rightValue: _bestStreak.toString(),
            footer: 'Equal values count as correct either way.',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xfff59e0b)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _makeGuess(false),
                  child: const Text('Lower'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _makeGuess(true),
                  child: const Text('Higher'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _startFresh,
            child: const Text('Shuffle new round'),
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current card',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.15, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _CardFace(
                      key: ValueKey('current_$_current'),
                      label: _labelFor(_current),
                      accent: const Color(0xfff97316),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_nextPreview != null) ...[
                    Text(
                      'Last reveal',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _CardFace(
                        key: ValueKey('preview_$_nextPreview'),
                        label: _labelFor(_nextPreview!),
                        accent: const Color(0xfffacc15),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({super.key, required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 42,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

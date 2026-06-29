import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class OddOneOutScreen extends StatefulWidget {
  const OddOneOutScreen({super.key});

  @override
  State<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends State<OddOneOutScreen> {
  final Random _random = Random();

  static const List<_OddRoundTemplate> _templates = [
    _OddRoundTemplate(mainEmoji: '🍎', oddEmoji: '🍏', label: 'apple'),
    _OddRoundTemplate(mainEmoji: '🐶', oddEmoji: '🐺', label: 'animal'),
    _OddRoundTemplate(mainEmoji: '🌞', oddEmoji: '⭐', label: 'sky'),
    _OddRoundTemplate(mainEmoji: '🚗', oddEmoji: '🚕', label: 'car'),
    _OddRoundTemplate(mainEmoji: '🎈', oddEmoji: '🎁', label: 'party'),
    _OddRoundTemplate(mainEmoji: '🍩', oddEmoji: '🧁', label: 'treat'),
    _OddRoundTemplate(mainEmoji: '⚽', oddEmoji: '🏀', label: 'sports'),
    _OddRoundTemplate(mainEmoji: '🌼', oddEmoji: '🌻', label: 'flower'),
  ];

  late _OddRound _round;
  int _level = 1;
  int _streak = 0;
  int _bestStreak = 0;
  int _roundsPlayed = 0;
  String _message = 'Find the one tile that looks different.';

  @override
  void initState() {
    super.initState();
    _round = _buildRound();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestStreak = snapshot.oddOneOutBestStreak;
    });
  }

  int get _tileCount {
    if (_level >= 6) return 9;
    if (_level >= 3) return 6;
    return 4;
  }

  int get _crossAxisCount => _tileCount == 4 ? 2 : 3;

  _OddRound _buildRound() {
    final template = _templates[_random.nextInt(_templates.length)];
    return _OddRound(
      template: template,
      oddIndex: _random.nextInt(_tileCount),
      tileCount: _tileCount,
    );
  }

  Future<void> _pickTile(int index) async {
    final correct = index == _round.oddIndex;
    final nextStreak = correct ? _streak + 1 : 0;
    final leveledUp = correct && nextStreak > 0 && nextStreak % 5 == 0;
    final nextLevel = leveledUp ? _level + 1 : _level;

    setState(() {
      _roundsPlayed += 1;
      _streak = nextStreak;
      _level = nextLevel;
      _message = correct
          ? leveledUp
              ? 'Nice catch. Level up.'
              : 'Correct. You found the odd ${_round.template.label} tile.'
          : 'Not that one. Find the tile that is different.';
    });

    if (correct && nextStreak > _bestStreak) {
      await GameStatsStore.instance.recordOddOneOutBestStreak(nextStreak);
      if (!mounted) return;
      setState(() {
        _bestStreak = nextStreak;
      });
    }

    if (leveledUp) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
    }

    if (!mounted) return;
    setState(() {
      _round = _buildRound();
    });
  }

  void _resetGame() {
    setState(() {
      _level = 1;
      _streak = 0;
      _roundsPlayed = 0;
      _message = 'Find the one tile that looks different.';
      _round = _buildRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff59e0b), Color(0xffef4444)];
    return GameScaffold(
      title: 'Odd One Out',
      subtitle: 'Spot the different tile before the board grows.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Best',
            rightValue: _bestStreak.toString(),
            footer: 'Streak $_streak • Rounds played: $_roundsPlayed',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap the tile that is different',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every 5 correct picks adds a harder board.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _round.tileCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: _round.tileCount == 4 ? 1.3 : 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final isOdd = index == _round.oddIndex;
                    final emoji = isOdd
                        ? _round.template.oddEmoji
                        : _round.template.mainEmoji;
                    return ElevatedButton(
                      onPressed: () => _pickTile(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: _round.tileCount == 9 ? 36 : 42,
                          ),
                        ),
                      ),
                    );
                  },
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

class _OddRound {
  const _OddRound({
    required this.template,
    required this.oddIndex,
    required this.tileCount,
  });

  final _OddRoundTemplate template;
  final int oddIndex;
  final int tileCount;
}

class _OddRoundTemplate {
  const _OddRoundTemplate({
    required this.mainEmoji,
    required this.oddEmoji,
    required this.label,
  });

  final String mainEmoji;
  final String oddEmoji;
  final String label;
}

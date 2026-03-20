import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class WordBlankScreen extends StatefulWidget {
  const WordBlankScreen({super.key});

  @override
  State<WordBlankScreen> createState() => _WordBlankScreenState();
}

class _WordBlankScreenState extends State<WordBlankScreen> {
  final Random _random = Random();
  final List<int> _remainingIndexes = [];

  late _WordBlankRound _round;
  int _level = 1;
  int _completed = 0;
  int _bestLevel = 1;
  int? _selectedIndex;
  bool _answered = false;
  bool _correctAnswer = false;
  String _message = 'Pick the missing letter to complete the word.';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    _level = snapshot.wordBlankLevel == 0 ? 1 : snapshot.wordBlankLevel;
    _bestLevel = _level;
    _refillQueue();
    _nextRound();
  }

  int get _goalPerLevel => min(8, 4 + _level);

  void _refillQueue() {
    _remainingIndexes
      ..clear()
      ..addAll(List.generate(_wordEntries.length, (index) => index))
      ..shuffle(_random);
  }

  void _nextRound() {
    if (_remainingIndexes.isEmpty) {
      _refillQueue();
    }
    final entry = _wordEntries[_remainingIndexes.removeLast()];
    final blankIndex =
        entry.blankIndex ??
        max(1, min(entry.word.length - 2, entry.word.length ~/ 2));
    final correctLetter = entry.word[blankIndex].toUpperCase();
    final options = <String>{correctLetter};
    const distractors = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    while (options.length < 4) {
      options.add(distractors[_random.nextInt(distractors.length)]);
    }
    final shuffled = options.toList()..shuffle(_random);

    _round = _WordBlankRound(
      entry: entry,
      blankIndex: blankIndex,
      options: shuffled,
      answer: correctLetter,
    );
    if (mounted) {
      setState(() {
        _selectedIndex = null;
        _answered = false;
        _correctAnswer = false;
      });
    }
  }

  Future<void> _selectOption(int index) async {
    if (_answered) return;
    final picked = _round.options[index];
    final correct = picked == _round.answer;
    var nextMessage = _message;
    var nextCompleted = _completed;
    var nextLevel = _level;

    if (correct) {
      nextCompleted += 1;
      nextMessage =
          '${_round.entry.word} means ${_round.entry.description} ${_round.entry.intro}';
      if (nextCompleted >= _goalPerLevel) {
        nextLevel += 1;
        nextCompleted = 0;
        await GameStatsStore.instance.recordWordBlankLevel(nextLevel);
        _bestLevel = max(_bestLevel, nextLevel);
        nextMessage =
            'Level clear. ${_round.entry.word}: ${_round.entry.description} ${_round.entry.intro}';
      }
    } else {
      nextMessage =
          'Not quite. ${_round.entry.word} is the correct word. ${_round.entry.description}';
    }

    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _correctAnswer = correct;
      _completed = nextCompleted;
      _level = nextLevel;
      _message = nextMessage;
    });
  }

  Future<void> _goNext() async {
    _nextRound();
    if (!mounted) return;
    setState(() {
      _message = 'Pick the missing letter to complete the word.';
    });
  }

  Future<void> _resetProgress() async {
    await GameStatsStore.instance.recordWordBlankLevel(1);
    _level = 1;
    _bestLevel = max(_bestLevel, 1);
    _completed = 0;
    _refillQueue();
    _nextRound();
    if (!mounted) return;
    setState(() {
      _message = 'Progress reset to level 1.';
    });
  }

  String get _promptWord {
    final chars = _round.entry.word.split('');
    chars[_round.blankIndex] = '_';
    return chars.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final headline = _answered
        ? (_correctAnswer ? 'Word Complete!' : 'Try The Next One')
        : _round.entry.emoji;

    return GameScaffold(
      title: 'Word Blank',
      subtitle: 'Fill the blank, learn the word, and keep unlocking levels.',
      accent: const [Color(0xff14b8a6), Color(0xff06b6d4)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Goal',
            rightValue: '$_completed/$_goalPerLevel',
            footer: 'Saved level: $_bestLevel on this device',
          ),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Text(
                  _round.entry.clue,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xffbae6fd),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _promptWord,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: List.generate(_round.options.length, (index) {
              final selected = _selectedIndex == index;
              final correct =
                  _answered && _round.options[index] == _round.answer;
              final wrong = _answered && selected && !correct;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: correct
                      ? const Color(0xff22c55e)
                      : wrong
                      ? const Color(0xffef4444)
                      : Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: _answered ? null : () => _selectOption(index),
                child: Text(
                  _round.options[index],
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          StatusCard(
            message: _message,
            accent: const Color(0xff06b6d4),
            highlight: _answered,
            headline: headline,
          ),
          const SizedBox(height: 18),
          if (_answered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goNext,
                child: const Text('Next word'),
              ),
            ),
          const SizedBox(height: 10),
          ResetActionButton(
            label: 'Reset to level 1',
            onPressed: _resetProgress,
          ),
        ],
      ),
    );
  }
}

class _WordBlankRound {
  const _WordBlankRound({
    required this.entry,
    required this.blankIndex,
    required this.options,
    required this.answer,
  });

  final _WordEntry entry;
  final int blankIndex;
  final List<String> options;
  final String answer;
}

class _WordEntry {
  const _WordEntry({
    required this.word,
    required this.clue,
    required this.description,
    required this.intro,
    required this.emoji,
    this.blankIndex,
  });

  final String word;
  final String clue;
  final String description;
  final String intro;
  final String emoji;
  final int? blankIndex;
}

const List<_WordEntry> _wordEntries = [
  _WordEntry(
    word: 'APPLE',
    clue: 'A red or green fruit',
    description: 'a sweet fruit',
    intro: 'You can eat an apple as a healthy snack.',
    emoji: '🍎',
    blankIndex: 2,
  ),
  _WordEntry(
    word: 'TIGER',
    clue: 'A big striped animal',
    description: 'a wild cat',
    intro: 'Tigers are strong animals that live in forests.',
    emoji: '🐯',
    blankIndex: 1,
  ),
  _WordEntry(
    word: 'TRAIN',
    clue: 'It runs on tracks',
    description: 'a vehicle with many coaches',
    intro: 'A train carries people and goods from one place to another.',
    emoji: '🚆',
    blankIndex: 3,
  ),
  _WordEntry(
    word: 'BREAD',
    clue: 'You can eat it for breakfast',
    description: 'a soft baked food',
    intro: 'Bread is often eaten with butter or jam.',
    emoji: '🍞',
    blankIndex: 2,
  ),
  _WordEntry(
    word: 'CLOUD',
    clue: 'It floats in the sky',
    description: 'a soft white shape in the sky',
    intro: 'Clouds can bring shade and sometimes rain.',
    emoji: '☁️',
    blankIndex: 1,
  ),
  _WordEntry(
    word: 'PLANT',
    clue: 'It grows in soil',
    description: 'a living green thing',
    intro: 'Plants need water and sunlight to grow.',
    emoji: '🪴',
    blankIndex: 2,
  ),
  _WordEntry(
    word: 'MUSIC',
    clue: 'You can hear songs in it',
    description: 'pleasant sound and rhythm',
    intro: 'Music can make people feel happy and relaxed.',
    emoji: '🎵',
    blankIndex: 3,
  ),
  _WordEntry(
    word: 'OCEAN',
    clue: 'A very big body of water',
    description: 'a huge saltwater sea',
    intro: 'The ocean is home to many fish and sea animals.',
    emoji: '🌊',
    blankIndex: 1,
  ),
  _WordEntry(
    word: 'ROBOT',
    clue: 'A smart machine',
    description: 'a machine that can do tasks',
    intro: 'Robots can help people at home, in factories, and in space.',
    emoji: '🤖',
    blankIndex: 2,
  ),
  _WordEntry(
    word: 'CANDLE',
    clue: 'It gives a small light',
    description: 'a wax light',
    intro: 'A candle glows when its wick is lit.',
    emoji: '🕯️',
    blankIndex: 4,
  ),
  _WordEntry(
    word: 'GARDEN',
    clue: 'Flowers and plants grow here',
    description: 'a place for plants',
    intro: 'A garden can be full of flowers, trees, and butterflies.',
    emoji: '🌷',
    blankIndex: 3,
  ),
  _WordEntry(
    word: 'CASTLE',
    clue: 'A big old stone building',
    description: 'a strong historic home',
    intro: 'Castles were built for kings, queens, and protection.',
    emoji: '🏰',
    blankIndex: 1,
  ),
];

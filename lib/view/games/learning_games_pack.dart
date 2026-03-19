import 'package:flutter/material.dart';

import 'game_scaffold.dart';

class LearningQuizQuestion {
  const LearningQuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.detail,
    this.emoji,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String detail;
  final String? emoji;
}

class _LearningQuizGameScreen extends StatefulWidget {
  const _LearningQuizGameScreen({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.questions,
  });

  final String title;
  final String subtitle;
  final List<Color> accent;
  final List<LearningQuizQuestion> questions;

  @override
  State<_LearningQuizGameScreen> createState() =>
      _LearningQuizGameScreenState();
}

class _LearningQuizGameScreenState extends State<_LearningQuizGameScreen> {
  int _index = 0;
  int _correctAnswers = 0;
  int _bestStreak = 0;
  int _currentStreak = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;
  bool _highlight = false;
  String? _headline;
  String _message = 'Tap the best answer to begin.';

  LearningQuizQuestion get _question => widget.questions[_index];

  void _answer(int index) {
    if (_answered || _finished) return;
    final correct = index == _question.correctIndex;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      _highlight = correct;
      _headline = correct ? 'Great job' : 'Keep trying';
      if (correct) {
        _correctAnswers += 1;
        _currentStreak += 1;
        if (_currentStreak > _bestStreak) {
          _bestStreak = _currentStreak;
        }
        _message = _question.detail;
      } else {
        _currentStreak = 0;
        _message =
            'Nice try. ${_question.options[_question.correctIndex]} is right. ${_question.detail}';
      }
    });
  }

  void _next() {
    if (!_answered) return;
    if (_index == widget.questions.length - 1) {
      setState(() {
        _finished = true;
        _highlight = true;
        _headline = 'Round complete';
        _message =
            'You answered $_correctAnswers of ${widget.questions.length} correctly.';
      });
      return;
    }

    setState(() {
      _index += 1;
      _selectedIndex = null;
      _answered = false;
      _highlight = false;
      _headline = null;
      _message = 'Keep going. You are doing great.';
    });
  }

  void _reset() {
    setState(() {
      _index = 0;
      _correctAnswers = 0;
      _bestStreak = 0;
      _currentStreak = 0;
      _selectedIndex = null;
      _answered = false;
      _finished = false;
      _highlight = false;
      _headline = null;
      _message = 'Tap the best answer to begin.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      accent: widget.accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Correct',
            leftValue: _correctAnswers.toString(),
            rightLabel: 'Best streak',
            rightValue: _bestStreak.toString(),
            footer: _finished
                ? 'Round finished'
                : 'Question ${_index + 1} of ${widget.questions.length}',
          ),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Text(
                  _question.emoji ?? '🎓',
                  style: const TextStyle(fontSize: 44),
                ),
                const SizedBox(height: 12),
                Text(
                  _question.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_question.options.length, (optionIndex) {
              return SizedBox(
                width: 148,
                child: _QuizOptionButton(
                  label: _question.options[optionIndex],
                  accent: widget.accent.last,
                  enabled: !_answered && !_finished,
                  selected: _selectedIndex == optionIndex,
                  isCorrect: _answered && optionIndex == _question.correctIndex,
                  isWrong:
                      _answered &&
                      _selectedIndex == optionIndex &&
                      optionIndex != _question.correctIndex,
                  onTap: () => _answer(optionIndex),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          StatusCard(
            message: _message,
            accent: widget.accent.last,
            highlight: _highlight,
            headline: _headline,
          ),
          const SizedBox(height: 18),
          if (_answered && !_finished)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: const Text('Next question'),
              ),
            ),
          if (_finished)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reset,
                child: const Text('Play again'),
              ),
            ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset round', onPressed: _reset),
        ],
      ),
    );
  }
}

class _QuizOptionButton extends StatelessWidget {
  const _QuizOptionButton({
    required this.label,
    required this.accent,
    required this.enabled,
    required this.selected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool enabled;
  final bool selected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCorrect
        ? const Color(0xff22c55e)
        : isWrong
        ? const Color(0xffef4444)
        : selected
        ? accent
        : Colors.white.withValues(alpha: 0.08);
    final fillColor = isCorrect
        ? const Color(0xff22c55e).withValues(alpha: 0.18)
        : isWrong
        ? const Color(0xffef4444).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.06);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AlphabetAdventureScreen extends StatelessWidget {
  const AlphabetAdventureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Alphabet Adventure',
      subtitle: 'Pick letters, finish sequences, and grow alphabet confidence.',
      accent: [Color(0xff38bdf8), Color(0xff0ea5e9)],
      questions: _alphabetQuestions,
    );
  }
}

class CountingFunScreen extends StatelessWidget {
  const CountingFunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Counting Fun',
      subtitle: 'Count groups and choose the correct number.',
      accent: [Color(0xfff59e0b), Color(0xfff97316)],
      questions: _countingQuestions,
    );
  }
}

class ShapeMatchScreen extends StatelessWidget {
  const ShapeMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Shape Match',
      subtitle: 'Spot shapes and match them with the correct names.',
      accent: [Color(0xff8b5cf6), Color(0xff6366f1)],
      questions: _shapeQuestions,
    );
  }
}

class AnimalMatchScreen extends StatelessWidget {
  const AnimalMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Animal Match',
      subtitle: 'Learn animal names and clues through easy questions.',
      accent: [Color(0xff22c55e), Color(0xff16a34a)],
      questions: _animalQuestions,
    );
  }
}

class MathSprintScreen extends StatelessWidget {
  const MathSprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Math Sprint',
      subtitle: 'Solve small number puzzles and quick sums.',
      accent: [Color(0xffef4444), Color(0xfff97316)],
      questions: _mathQuestions,
    );
  }
}

class WordBuilderScreen extends StatelessWidget {
  const WordBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Word Builder',
      subtitle: 'Choose the missing letter to finish simple words.',
      accent: [Color(0xff14b8a6), Color(0xff06b6d4)],
      questions: _wordBuilderQuestions,
    );
  }
}

class PatternPlayScreen extends StatelessWidget {
  const PatternPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Pattern Play',
      subtitle: 'Find the next item in fun repeating patterns.',
      accent: [Color(0xfff97316), Color(0xfffb7185)],
      questions: _patternQuestions,
    );
  }
}

class OppositeDayScreen extends StatelessWidget {
  const OppositeDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Opposite Day',
      subtitle: 'Pick the opposite word and build language skills.',
      accent: [Color(0xff6366f1), Color(0xff38bdf8)],
      questions: _oppositeQuestions,
    );
  }
}

class EmojiCountScreen extends StatelessWidget {
  const EmojiCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Emoji Count',
      subtitle: 'Count emoji groups in quick playful rounds.',
      accent: [Color(0xffec4899), Color(0xfff59e0b)],
      questions: _emojiCountQuestions,
    );
  }
}

class SightWordSprintScreen extends StatelessWidget {
  const SightWordSprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LearningQuizGameScreen(
      title: 'Sight Word Sprint',
      subtitle: 'Practice common words and quick reading choices.',
      accent: [Color(0xff22c55e), Color(0xff10b981)],
      questions: _sightWordQuestions,
    );
  }
}

const List<LearningQuizQuestion> _alphabetQuestions = [
  LearningQuizQuestion(
    prompt: 'Which letter comes after C?',
    options: ['D', 'F', 'B', 'G'],
    correctIndex: 0,
    detail: 'D comes right after C in the alphabet.',
    emoji: '🔤',
  ),
  LearningQuizQuestion(
    prompt: 'Which letter starts the word Apple?',
    options: ['A', 'E', 'P', 'L'],
    correctIndex: 0,
    detail: 'Apple starts with the letter A.',
    emoji: '🍎',
  ),
  LearningQuizQuestion(
    prompt: 'Pick the missing letter: H, I, __, K',
    options: ['L', 'J', 'M', 'G'],
    correctIndex: 1,
    detail: 'J fits between I and K.',
    emoji: '🧩',
  ),
  LearningQuizQuestion(
    prompt: 'Which one is a vowel?',
    options: ['T', 'O', 'R', 'N'],
    correctIndex: 1,
    detail: 'O is one of the five vowels.',
    emoji: '🎵',
  ),
  LearningQuizQuestion(
    prompt: 'Which letter comes before Z?',
    options: ['X', 'Y', 'W', 'A'],
    correctIndex: 1,
    detail: 'Y comes right before Z.',
    emoji: '⭐',
  ),
  LearningQuizQuestion(
    prompt: 'Pick the letter that matches this sound: /b/',
    options: ['B', 'D', 'P', 'G'],
    correctIndex: 0,
    detail: 'The /b/ sound is made by the letter B.',
    emoji: '🎤',
  ),
];

const List<LearningQuizQuestion> _countingQuestions = [
  LearningQuizQuestion(
    prompt: 'How many stars are here? ⭐⭐⭐⭐',
    options: ['3', '4', '5', '6'],
    correctIndex: 1,
    detail: 'There are 4 stars.',
    emoji: '⭐',
  ),
  LearningQuizQuestion(
    prompt: 'Count the apples: 🍎🍎🍎',
    options: ['2', '3', '4', '5'],
    correctIndex: 1,
    detail: 'There are 3 apples.',
    emoji: '🍎',
  ),
  LearningQuizQuestion(
    prompt: 'How many ducks? 🦆🦆🦆🦆🦆',
    options: ['5', '6', '4', '7'],
    correctIndex: 0,
    detail: 'There are 5 ducks.',
    emoji: '🦆',
  ),
  LearningQuizQuestion(
    prompt: 'Which number is bigger than 7?',
    options: ['5', '6', '8', '4'],
    correctIndex: 2,
    detail: '8 is bigger than 7.',
    emoji: '📈',
  ),
  LearningQuizQuestion(
    prompt: 'What number comes after 9?',
    options: ['10', '8', '7', '11'],
    correctIndex: 0,
    detail: '10 comes after 9.',
    emoji: '🔢',
  ),
  LearningQuizQuestion(
    prompt: 'Count the balloons: 🎈🎈',
    options: ['1', '2', '3', '4'],
    correctIndex: 1,
    detail: 'There are 2 balloons.',
    emoji: '🎈',
  ),
];

const List<LearningQuizQuestion> _shapeQuestions = [
  LearningQuizQuestion(
    prompt: 'Which one is a circle?',
    options: ['⬛', '⚪', '🔺', '⭐'],
    correctIndex: 1,
    detail: 'A circle is round like ⚪.',
    emoji: '🟣',
  ),
  LearningQuizQuestion(
    prompt: 'A shape with 3 sides is a...',
    options: ['Square', 'Triangle', 'Circle', 'Oval'],
    correctIndex: 1,
    detail: 'Triangles have 3 sides.',
    emoji: '🔺',
  ),
  LearningQuizQuestion(
    prompt: 'Which one is a square?',
    options: ['⬛', '⚪', '🔷', '❤️'],
    correctIndex: 0,
    detail: 'A square has 4 equal sides.',
    emoji: '⬛',
  ),
  LearningQuizQuestion(
    prompt: 'Which shape has no corners?',
    options: ['Triangle', 'Rectangle', 'Circle', 'Square'],
    correctIndex: 2,
    detail: 'Circles are smooth and round with no corners.',
    emoji: '🟠',
  ),
  LearningQuizQuestion(
    prompt: 'A long square is called a...',
    options: ['Rectangle', 'Circle', 'Triangle', 'Star'],
    correctIndex: 0,
    detail: 'A rectangle is longer than a square.',
    emoji: '▭',
  ),
  LearningQuizQuestion(
    prompt: 'Which one looks like a diamond?',
    options: ['🔷', '⬛', '⚪', '🔺'],
    correctIndex: 0,
    detail: '🔷 is a diamond shape.',
    emoji: '💎',
  ),
];

const List<LearningQuizQuestion> _animalQuestions = [
  LearningQuizQuestion(
    prompt: 'Which animal says "moo"?',
    options: ['Dog', 'Cow', 'Cat', 'Duck'],
    correctIndex: 1,
    detail: 'Cows say moo.',
    emoji: '🐄',
  ),
  LearningQuizQuestion(
    prompt: 'Which animal has a long trunk?',
    options: ['Lion', 'Elephant', 'Horse', 'Pig'],
    correctIndex: 1,
    detail: 'Elephants have long trunks.',
    emoji: '🐘',
  ),
  LearningQuizQuestion(
    prompt: 'Which animal barks?',
    options: ['Dog', 'Fish', 'Bird', 'Cow'],
    correctIndex: 0,
    detail: 'Dogs bark.',
    emoji: '🐶',
  ),
  LearningQuizQuestion(
    prompt: 'Which animal gives us wool?',
    options: ['Sheep', 'Duck', 'Rabbit', 'Goat'],
    correctIndex: 0,
    detail: 'Sheep give us wool.',
    emoji: '🐑',
  ),
  LearningQuizQuestion(
    prompt: 'Which animal can fly?',
    options: ['Bird', 'Cat', 'Cow', 'Horse'],
    correctIndex: 0,
    detail: 'Birds can fly high in the sky.',
    emoji: '🐦',
  ),
  LearningQuizQuestion(
    prompt: 'Which one lives in the sea?',
    options: ['Fish', 'Tiger', 'Goat', 'Dog'],
    correctIndex: 0,
    detail: 'Fish live in water.',
    emoji: '🐟',
  ),
];

const List<LearningQuizQuestion> _mathQuestions = [
  LearningQuizQuestion(
    prompt: 'What is 2 + 3?',
    options: ['4', '5', '6', '7'],
    correctIndex: 1,
    detail: '2 + 3 makes 5.',
    emoji: '➕',
  ),
  LearningQuizQuestion(
    prompt: 'What is 6 - 2?',
    options: ['3', '4', '5', '6'],
    correctIndex: 1,
    detail: '6 minus 2 equals 4.',
    emoji: '➖',
  ),
  LearningQuizQuestion(
    prompt: 'Which number is even?',
    options: ['3', '5', '8', '7'],
    correctIndex: 2,
    detail: '8 is even because it can be split into pairs.',
    emoji: '🔢',
  ),
  LearningQuizQuestion(
    prompt: 'What is 1 + 1 + 1?',
    options: ['2', '3', '4', '5'],
    correctIndex: 1,
    detail: 'Three ones make 3.',
    emoji: '🧠',
  ),
  LearningQuizQuestion(
    prompt: 'What is 10 - 1?',
    options: ['8', '7', '9', '6'],
    correctIndex: 2,
    detail: '10 minus 1 equals 9.',
    emoji: '🎯',
  ),
  LearningQuizQuestion(
    prompt: 'Which is bigger?',
    options: ['4', '9', '2', '5'],
    correctIndex: 1,
    detail: '9 is the biggest number here.',
    emoji: '📚',
  ),
];

const List<LearningQuizQuestion> _wordBuilderQuestions = [
  LearningQuizQuestion(
    prompt: 'Fill the missing letter: C _ T',
    options: ['A', 'E', 'I', 'O'],
    correctIndex: 0,
    detail: 'CAT is spelled with A in the middle.',
    emoji: '🐱',
  ),
  LearningQuizQuestion(
    prompt: 'Fill the missing letter: S U _',
    options: ['M', 'N', 'P', 'T'],
    correctIndex: 1,
    detail: 'SUN ends with N.',
    emoji: '☀️',
  ),
  LearningQuizQuestion(
    prompt: 'Fill the missing letter: B _ T',
    options: ['A', 'O', 'E', 'U'],
    correctIndex: 0,
    detail: 'BAT uses A.',
    emoji: '🏏',
  ),
  LearningQuizQuestion(
    prompt: 'Fill the missing letter: F I _ H',
    options: ['S', 'T', 'N', 'P'],
    correctIndex: 0,
    detail: 'FISH uses S.',
    emoji: '🐟',
  ),
  LearningQuizQuestion(
    prompt: 'Fill the missing letter: C A R _',
    options: ['D', 'T', 'S', 'E'],
    correctIndex: 1,
    detail: 'CART ends with T.',
    emoji: '🚗',
  ),
  LearningQuizQuestion(
    prompt: 'Fill the missing letter: B O O _',
    options: ['T', 'K', 'P', 'D'],
    correctIndex: 1,
    detail: 'BOOK ends with K.',
    emoji: '📘',
  ),
];

const List<LearningQuizQuestion> _patternQuestions = [
  LearningQuizQuestion(
    prompt: 'What comes next? 🔴 🔵 🔴 🔵 __',
    options: ['🔴', '🟢', '🟡', '⚫'],
    correctIndex: 0,
    detail: 'The pattern repeats red, blue, red, blue.',
    emoji: '🎨',
  ),
  LearningQuizQuestion(
    prompt: 'What comes next? ⭐ 🌙 ⭐ 🌙 __',
    options: ['☁️', '⭐', '🌙', '☀️'],
    correctIndex: 1,
    detail: 'Star and moon keep repeating.',
    emoji: '✨',
  ),
  LearningQuizQuestion(
    prompt: 'What comes next? 2, 4, 6, __',
    options: ['7', '8', '9', '10'],
    correctIndex: 1,
    detail: 'The pattern counts by twos.',
    emoji: '🔢',
  ),
  LearningQuizQuestion(
    prompt: 'What comes next? 🍎 🍌 🍎 🍌 __',
    options: ['🍎', '🍇', '🍉', '🍒'],
    correctIndex: 0,
    detail: 'Apple and banana repeat.',
    emoji: '🍎',
  ),
  LearningQuizQuestion(
    prompt: 'What comes next? ⬜ ⬛ ⬜ ⬛ __',
    options: ['⬜', '🔺', '⚪', '🔷'],
    correctIndex: 0,
    detail: 'White and black squares repeat.',
    emoji: '🧩',
  ),
  LearningQuizQuestion(
    prompt: 'What comes next? 5, 10, 15, __',
    options: ['18', '20', '25', '30'],
    correctIndex: 1,
    detail: 'The pattern adds 5 each time.',
    emoji: '📈',
  ),
];

const List<LearningQuizQuestion> _oppositeQuestions = [
  LearningQuizQuestion(
    prompt: 'What is the opposite of HOT?',
    options: ['Cold', 'Warm', 'Big', 'Dry'],
    correctIndex: 0,
    detail: 'Cold is the opposite of hot.',
    emoji: '❄️',
  ),
  LearningQuizQuestion(
    prompt: 'What is the opposite of BIG?',
    options: ['Tall', 'Small', 'Wide', 'Long'],
    correctIndex: 1,
    detail: 'Small is the opposite of big.',
    emoji: '📏',
  ),
  LearningQuizQuestion(
    prompt: 'What is the opposite of UP?',
    options: ['Over', 'Under', 'Down', 'Around'],
    correctIndex: 2,
    detail: 'Down is the opposite of up.',
    emoji: '⬇️',
  ),
  LearningQuizQuestion(
    prompt: 'What is the opposite of DAY?',
    options: ['Morning', 'Night', 'Light', 'Sun'],
    correctIndex: 1,
    detail: 'Night is the opposite of day.',
    emoji: '🌙',
  ),
  LearningQuizQuestion(
    prompt: 'What is the opposite of FULL?',
    options: ['Round', 'Tiny', 'Empty', 'Fast'],
    correctIndex: 2,
    detail: 'Empty is the opposite of full.',
    emoji: '🥛',
  ),
  LearningQuizQuestion(
    prompt: 'What is the opposite of HAPPY?',
    options: ['Sleepy', 'Sad', 'Loud', 'Short'],
    correctIndex: 1,
    detail: 'Sad is the opposite of happy.',
    emoji: '🙂',
  ),
];

const List<LearningQuizQuestion> _emojiCountQuestions = [
  LearningQuizQuestion(
    prompt: 'How many hearts? ❤️❤️❤️❤️❤️',
    options: ['4', '5', '6', '7'],
    correctIndex: 1,
    detail: 'There are 5 hearts.',
    emoji: '❤️',
  ),
  LearningQuizQuestion(
    prompt: 'How many suns? ☀️☀️☀️',
    options: ['2', '3', '4', '5'],
    correctIndex: 1,
    detail: 'There are 3 suns.',
    emoji: '☀️',
  ),
  LearningQuizQuestion(
    prompt: 'How many cars? 🚗🚗🚗🚗',
    options: ['3', '4', '5', '6'],
    correctIndex: 1,
    detail: 'There are 4 cars.',
    emoji: '🚗',
  ),
  LearningQuizQuestion(
    prompt: 'How many books? 📘📘',
    options: ['1', '2', '3', '4'],
    correctIndex: 1,
    detail: 'There are 2 books.',
    emoji: '📘',
  ),
  LearningQuizQuestion(
    prompt: 'How many stars? ⭐⭐⭐⭐⭐⭐',
    options: ['5', '6', '7', '8'],
    correctIndex: 1,
    detail: 'There are 6 stars.',
    emoji: '⭐',
  ),
  LearningQuizQuestion(
    prompt: 'How many balls? ⚽⚽⚽⚽⚽⚽⚽',
    options: ['6', '7', '8', '9'],
    correctIndex: 1,
    detail: 'There are 7 balls.',
    emoji: '⚽',
  ),
];

const List<LearningQuizQuestion> _sightWordQuestions = [
  LearningQuizQuestion(
    prompt: 'Tap the word "the".',
    options: ['and', 'the', 'cat', 'run'],
    correctIndex: 1,
    detail: 'The word is "the".',
    emoji: '📖',
  ),
  LearningQuizQuestion(
    prompt: 'Tap the word "you".',
    options: ['you', 'me', 'we', 'go'],
    correctIndex: 0,
    detail: 'The word is "you".',
    emoji: '👀',
  ),
  LearningQuizQuestion(
    prompt: 'Tap the word "come".',
    options: ['play', 'come', 'look', 'stop'],
    correctIndex: 1,
    detail: 'Come is the correct sight word.',
    emoji: '🚶',
  ),
  LearningQuizQuestion(
    prompt: 'Tap the word "here".',
    options: ['there', 'home', 'here', 'near'],
    correctIndex: 2,
    detail: 'Here is the correct word.',
    emoji: '📍',
  ),
  LearningQuizQuestion(
    prompt: 'Tap the word "look".',
    options: ['look', 'book', 'cook', 'took'],
    correctIndex: 0,
    detail: 'Look is the correct sight word.',
    emoji: '👓',
  ),
  LearningQuizQuestion(
    prompt: 'Tap the word "play".',
    options: ['stay', 'play', 'clay', 'gray'],
    correctIndex: 1,
    detail: 'Play is the correct sight word.',
    emoji: '🎲',
  ),
];

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class CarWashSortScreen extends StatefulWidget {
  const CarWashSortScreen({super.key});

  @override
  State<CarWashSortScreen> createState() => _CarWashSortScreenState();
}

class _CarWashSortScreenState extends State<CarWashSortScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<_WashRound> _rounds = <_WashRound>[
    _WashRound(
      carName: 'Dusty SUV',
      problem: 'Covered in dry dirt after an off-road trip.',
      correctLane: 'Mud Wash',
      lanes: <String>['Mud Wash', 'Quick Shine', 'Interior Care'],
      color: Color(0xfff59e0b),
    ),
    _WashRound(
      carName: 'City Sedan',
      problem: 'Only light dust and finger marks on the body.',
      correctLane: 'Quick Shine',
      lanes: <String>['Mud Wash', 'Quick Shine', 'Interior Care'],
      color: Color(0xff0ea5e9),
    ),
    _WashRound(
      carName: 'Family Van',
      problem: 'Seats are messy and the cabin needs cleaning.',
      correctLane: 'Interior Care',
      lanes: <String>['Mud Wash', 'Quick Shine', 'Interior Care'],
      color: Color(0xff22c55e),
    ),
    _WashRound(
      carName: 'Rainy Hatch',
      problem: 'Splash marks and road grime cover the outside.',
      correctLane: 'Mud Wash',
      lanes: <String>['Mud Wash', 'Quick Shine', 'Interior Care'],
      color: Color(0xff8b5cf6),
    ),
    _WashRound(
      carName: 'Showroom Coupe',
      problem: 'Looks clean already and just needs a glossy finish.',
      correctLane: 'Quick Shine',
      lanes: <String>['Mud Wash', 'Quick Shine', 'Interior Care'],
      color: Color(0xfffb7185),
    ),
    _WashRound(
      carName: 'Taxi Cab',
      problem: 'The floor mats and back seats need the most attention.',
      correctLane: 'Interior Care',
      lanes: <String>['Mud Wash', 'Quick Shine', 'Interior Care'],
      color: Color(0xff14b8a6),
    ),
  ];

  late _WashRound _currentRound;
  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  String _message = 'Pick the best wash lane for each car.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  bool get _gameOver => _lives == 0;

  void _startRound({bool resetGame = false}) {
    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = _maxLives;
      }
      _currentRound = _rounds[_random.nextInt(_rounds.length)];
      _message = 'Read the car condition and choose the right wash lane.';
    });
  }

  Future<void> _pickLane(String lane) async {
    if (_gameOver) return;

    if (lane == _currentRound.correctLane) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = '${_currentRound.carName} sent to $lane. Next car ready.';
      });
      _startRound();
      return;
    }

    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _message =
            'Wash station closed. Best lane was ${_currentRound.correctLane}.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong lane. Best lane was ${_currentRound.correctLane}. Lives left: $nextLives.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff38bdf8), Color(0xff14b8a6)];
    return GameScaffold(
      title: 'Car Wash Sort',
      subtitle: 'Read each car condition and send it to the best wash lane.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/$_maxLives • Car care sorting game',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Wash rules',
            message:
                'Mud Wash for heavy outside dirt. Quick Shine for light exterior cleanup. Interior Care for messy seats and cabin.',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _currentRound.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_car_wash_rounded,
                            color: _currentRound.color,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _currentRound.carName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentRound.problem,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._currentRound.lanes.map(
                  (lane) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _gameOver ? null : () => _pickLane(lane),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(18),
                        ),
                        child: Text(
                          lane,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset wash', onPressed: _resetGame),
        ],
      ),
    );
  }
}

class _WashRound {
  const _WashRound({
    required this.carName,
    required this.problem,
    required this.correctLane,
    required this.lanes,
    required this.color,
  });

  final String carName;
  final String problem;
  final String correctLane;
  final List<String> lanes;
  final Color color;
}

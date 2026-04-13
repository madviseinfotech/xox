import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class FuelGradePickScreen extends StatefulWidget {
  const FuelGradePickScreen({super.key});

  @override
  State<FuelGradePickScreen> createState() => _FuelGradePickScreenState();
}

class _FuelGradePickScreenState extends State<FuelGradePickScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<_FuelRound> _rounds = <_FuelRound>[
    _FuelRound(
      carName: 'Eco Hatch',
      need: 'Daily city car that uses regular petrol.',
      correctFuel: 'Regular',
      options: <String>['Regular', 'Premium', 'Diesel'],
      color: Color(0xff22c55e),
    ),
    _FuelRound(
      carName: 'Turbo Coupe',
      need: 'Performance engine that prefers high-octane fuel.',
      correctFuel: 'Premium',
      options: <String>['Regular', 'Premium', 'Diesel'],
      color: Color(0xffef4444),
    ),
    _FuelRound(
      carName: 'Cargo Van',
      need: 'Work van with a diesel engine.',
      correctFuel: 'Diesel',
      options: <String>['Regular', 'Premium', 'Diesel'],
      color: Color(0xfff59e0b),
    ),
    _FuelRound(
      carName: 'Family Sedan',
      need: 'Standard commuter car with no premium requirement.',
      correctFuel: 'Regular',
      options: <String>['Regular', 'Premium', 'Diesel'],
      color: Color(0xff0ea5e9),
    ),
    _FuelRound(
      carName: 'Track Special',
      need: 'High-performance engine tuned for premium petrol.',
      correctFuel: 'Premium',
      options: <String>['Regular', 'Premium', 'Diesel'],
      color: Color(0xfffb7185),
    ),
    _FuelRound(
      carName: 'Highway SUV',
      need: 'Large diesel-powered SUV for long-distance hauling.',
      correctFuel: 'Diesel',
      options: <String>['Regular', 'Premium', 'Diesel'],
      color: Color(0xff8b5cf6),
    ),
  ];

  late _FuelRound _currentRound;
  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  String _message = 'Pick the right fuel grade for each vehicle.';

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
      _message = 'Read the car profile and choose the best fuel.';
    });
  }

  Future<void> _pickFuel(String fuel) async {
    if (_gameOver) return;

    if (fuel == _currentRound.correctFuel) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message =
            '${_currentRound.carName} fueled with $fuel. Next car in line.';
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
            'Fuel station closed. Correct choice was ${_currentRound.correctFuel}.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong fuel. Correct choice was ${_currentRound.correctFuel}. Lives left: $nextLives.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff59e0b), Color(0xffef4444)];
    return GameScaffold(
      title: 'Fuel Grade Pick',
      subtitle:
          'Match each car with the right fuel grade before mistakes pile up.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/$_maxLives • Fuel station challenge',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Fuel rules',
            message:
                'Regular for standard petrol cars, Premium for performance petrol cars, and Diesel for diesel engines.',
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
                            Icons.local_gas_station_rounded,
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
                        _currentRound.need,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._currentRound.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _gameOver ? null : () => _pickFuel(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(18),
                        ),
                        child: Text(
                          option,
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
          ResetActionButton(label: 'Reset station', onPressed: _resetGame),
        ],
      ),
    );
  }
}

class _FuelRound {
  const _FuelRound({
    required this.carName,
    required this.need,
    required this.correctFuel,
    required this.options,
    required this.color,
  });

  final String carName;
  final String need;
  final String correctFuel;
  final List<String> options;
  final Color color;
}

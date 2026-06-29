import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class GarageSortScreen extends StatefulWidget {
  const GarageSortScreen({super.key});

  @override
  State<GarageSortScreen> createState() => _GarageSortScreenState();
}

class _GarageSortScreenState extends State<GarageSortScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<_GarageBay> _bayTemplates = <_GarageBay>[
    _GarageBay(
      name: 'Charge Bay',
      description: 'EV or hybrid only',
      matcher: _GarageRule.evOrHybrid,
      color: Color(0xff22c55e),
    ),
    _GarageBay(
      name: 'Lift Bay',
      description: 'SUV or van only',
      matcher: _GarageRule.suvOrVan,
      color: Color(0xfff59e0b),
    ),
    _GarageBay(
      name: 'Quick Lane',
      description: 'Sedan or coupe only',
      matcher: _GarageRule.sedanOrCoupe,
      color: Color(0xff38bdf8),
    ),
  ];

  late _GarageCar _currentCar;
  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  String _message = 'Send each car to the correct garage bay.';

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
      _currentCar = _randomCar();
      _message = 'Read the car profile and choose the correct bay.';
    });
  }

  _GarageCar _randomCar() {
    const cars = <_GarageCar>[
      _GarageCar(name: 'Neon EV', body: 'Hatch', power: 'EV'),
      _GarageCar(name: 'Metro Hybrid', body: 'Sedan', power: 'Hybrid'),
      _GarageCar(name: 'Trail SUV', body: 'SUV', power: 'Diesel'),
      _GarageCar(name: 'Cargo Van', body: 'Van', power: 'Petrol'),
      _GarageCar(name: 'Silver Sedan', body: 'Sedan', power: 'Petrol'),
      _GarageCar(name: 'Sun Coupe', body: 'Coupe', power: 'Petrol'),
    ];
    return cars[_random.nextInt(cars.length)];
  }

  Future<void> _chooseBay(_GarageBay bay) async {
    if (_gameOver) return;

    if (_matchesBay(_currentCar, bay.matcher)) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = '${_currentCar.name} parked in ${bay.name}. Next car ready.';
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
            'Wrong bay. Garage closed for the day. Tap reset to try again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message = 'Wrong bay for ${_currentCar.name}. Lives left: $nextLives.';
    });
    _startRound();
  }

  bool _matchesBay(_GarageCar car, _GarageRule rule) {
    switch (rule) {
      case _GarageRule.evOrHybrid:
        return car.power == 'EV' || car.power == 'Hybrid';
      case _GarageRule.suvOrVan:
        return car.body == 'SUV' || car.body == 'Van';
      case _GarageRule.sedanOrCoupe:
        return car.body == 'Sedan' || car.body == 'Coupe';
    }
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff0ea5e9), Color(0xff22c55e)];
    return GameScaffold(
      title: 'Garage Sort',
      subtitle:
          'Read the car profile and send every vehicle to the right service bay.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/$_maxLives • Offline car sorting challenge',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Garage rules',
            message:
                'Charge Bay takes EV or hybrid cars. Lift Bay takes SUV or van. Quick Lane takes sedan or coupe.',
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentCar.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _GarageChip(label: 'Body: ${_currentCar.body}'),
                          _GarageChip(label: 'Power: ${_currentCar.power}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._bayTemplates.map(
                  (bay) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _gameOver ? null : () => _chooseBay(bay),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bay.color.withValues(alpha: 0.16),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bay.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(bay.description),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset garage', onPressed: _resetGame),
        ],
      ),
    );
  }
}

enum _GarageRule { evOrHybrid, suvOrVan, sedanOrCoupe }

class _GarageBay {
  const _GarageBay({
    required this.name,
    required this.description,
    required this.matcher,
    required this.color,
  });

  final String name;
  final String description;
  final _GarageRule matcher;
  final Color color;
}

class _GarageCar {
  const _GarageCar({
    required this.name,
    required this.body,
    required this.power,
  });

  final String name;
  final String body;
  final String power;
}

class _GarageChip extends StatelessWidget {
  const _GarageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

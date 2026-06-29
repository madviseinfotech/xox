import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class AirportControlScreen extends StatefulWidget {
  const AirportControlScreen({super.key});

  @override
  State<AirportControlScreen> createState() => _AirportControlScreenState();
}

class _AirportControlScreenState extends State<AirportControlScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<String> _codes = [
    'AX',
    'JT',
    'SK',
    'VR',
    'QN',
    'DL',
    'PK',
    'AR',
  ];

  late List<_Flight> _flights;
  late _Flight _priorityFlight;

  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  String _message = 'Choose which flight gets the runway next.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  bool get _gameOver => _lives == 0;

  void _startRound({bool resetGame = false}) {
    late List<_Flight> flights;
    late _Flight priorityFlight;

    while (true) {
      final usedCodes = <String>{};
      flights = List.generate(3, (index) {
        String code;
        do {
          code =
              '${_codes[_random.nextInt(_codes.length)]}${100 + _random.nextInt(900)}';
        } while (!usedCodes.add(code));

        final action = _random.nextBool() ? _FlightAction.landing : _FlightAction.takeoff;
        return _Flight(
          code: code,
          action: action,
          fuel: action == _FlightAction.landing
              ? 1 + _random.nextInt(8)
              : 4 + _random.nextInt(6),
          passengers: 80 + _random.nextInt(171),
        );
      });

      final ranked = [...flights]..sort(_compareFlights);
      if (_compareFlights(ranked[0], ranked[1]) != 0) {
        priorityFlight = ranked.first;
        break;
      }
    }

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = _maxLives;
        _message = 'Choose which flight gets the runway next.';
      }
      _flights = flights;
      _priorityFlight = priorityFlight;
    });
  }

  int _compareFlights(_Flight a, _Flight b) {
    final aEmergency = a.action == _FlightAction.landing && a.fuel <= 2;
    final bEmergency = b.action == _FlightAction.landing && b.fuel <= 2;
    if (aEmergency != bEmergency) {
      return aEmergency ? -1 : 1;
    }

    if (a.action != b.action) {
      return a.action == _FlightAction.landing ? -1 : 1;
    }

    if (a.action == _FlightAction.landing) {
      final fuelCompare = a.fuel.compareTo(b.fuel);
      if (fuelCompare != 0) return fuelCompare;
      final passengerCompare = b.passengers.compareTo(a.passengers);
      if (passengerCompare != 0) return passengerCompare;
      return a.code.compareTo(b.code);
    }

    final passengerCompare = b.passengers.compareTo(a.passengers);
    if (passengerCompare != 0) return passengerCompare;
    final fuelCompare = a.fuel.compareTo(b.fuel);
    if (fuelCompare != 0) return fuelCompare;
    return a.code.compareTo(b.code);
  }

  Future<void> _pickFlight(_Flight flight) async {
    if (_gameOver) return;

    if (flight == _priorityFlight) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = '${flight.code} cleared correctly. Prepare the next runway call.';
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
            'Wrong runway call. ${_priorityFlight.code} should have gone first.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong runway call. ${_priorityFlight.code} had priority. Lives left: $nextLives.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff1d4ed8), Color(0xff0ea5e9)];
    return GameScaffold(
      title: 'Airport Control',
      subtitle: 'Decide which flight gets runway priority based on live conditions.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/$_maxLives',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Runway rules',
            message:
                'Emergency landings first. Then landings before takeoffs. For landings, lower fuel wins. For takeoffs, higher passengers win.',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: _flights
                  .map(
                    (flight) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _gameOver ? null : () => _pickFlight(flight),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      flight.code,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${flight.action.label} • Fuel ${flight.fuel} • ${flight.passengers} passengers',
                                      style: const TextStyle(
                                        color: Color(0xffcbd5e1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                flight.action == _FlightAction.landing
                                    ? Icons.flight_land_rounded
                                    : Icons.flight_takeoff_rounded,
                                color: accent.last,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}

enum _FlightAction {
  landing('Landing'),
  takeoff('Takeoff');

  const _FlightAction(this.label);

  final String label;
}

class _Flight {
  const _Flight({
    required this.code,
    required this.action,
    required this.fuel,
    required this.passengers,
  });

  final String code;
  final _FlightAction action;
  final int fuel;
  final int passengers;
}

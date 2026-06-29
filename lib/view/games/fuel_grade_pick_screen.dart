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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FuelHeroCard(
            round: _round,
            score: _score,
            lives: _lives,
            maxLives: _maxLives,
            accent: _currentRound.color,
            gameOver: _gameOver,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.tune_rounded,
                  label: 'Station Mood',
                  value: _gameOver ? 'Closed for reset' : 'Fast lane active',
                  accent: const Color(0xff22c55e),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  icon: Icons.flash_on_rounded,
                  label: 'Quick Hint',
                  value: 'Premium for tuned petrol, diesel for work engines',
                  accent: const Color(0xffa855f7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FuelDashboardCard(
                  round: _currentRound,
                  message: _message,
                  gameOver: _gameOver,
                ),
                const SizedBox(height: 18),
                _StationInsightStrip(
                  currentFuel: _currentRound.correctFuel,
                  accent: _currentRound.color,
                  gameOver: _gameOver,
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose pump',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _gameOver
                      ? 'Station is closed. Reset to start a fresh shift.'
                      : 'Tap the fuel that best matches this vehicle profile.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                ..._currentRound.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FuelOptionCard(
                      label: option,
                      color: _fuelColor(option),
                      onTap: _gameOver ? null : () => _pickFuel(option),
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

  Color _fuelColor(String fuel) {
    switch (fuel) {
      case 'Regular':
        return const Color(0xff22c55e);
      case 'Premium':
        return const Color(0xfff97316);
      case 'Diesel':
        return const Color(0xfffacc15);
      default:
        return Colors.white;
    }
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

class _FuelHeroCard extends StatelessWidget {
  const _FuelHeroCard({
    required this.round,
    required this.score,
    required this.lives,
    required this.maxLives,
    required this.accent,
    required this.gameOver,
  });

  final int round;
  final int score;
  final int lives;
  final int maxLives;
  final Color accent;
  final bool gameOver;

  @override
  Widget build(BuildContext context) {
    final progress = (lives / maxLives).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.92),
            const Color(0xff7c2d12),
            const Color(0xff111827),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_gas_station_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gameOver ? 'Station closed' : 'Fuel bay online',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$round',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            gameOver ? 'Shift Over' : 'Fuel Match Arena',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gameOver
                ? 'You are out of lives. Reset the station and try a cleaner run.'
                : 'Scan the car request, trust the clue, and send every driver to the perfect pump.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Station stability',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      gameOver ? const Color(0xffef4444) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Score',
                  value: '$score',
                  icon: Icons.emoji_events_rounded,
                  tone: const Color(0xfffde68a),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Lives',
                  value: '$lives/$maxLives',
                  icon: Icons.favorite_rounded,
                  tone: const Color(0xfffda4af),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Pressure',
                  value: gameOver
                      ? 'Max'
                      : lives == maxLives
                      ? 'Low'
                      : 'Medium',
                  icon: Icons.speed_rounded,
                  tone: const Color(0xff93c5fd),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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

class _FuelDashboardCard extends StatelessWidget {
  const _FuelDashboardCard({
    required this.round,
    required this.message,
    required this.gameOver,
  });

  final _FuelRound round;
  final String message;
  final bool gameOver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            round.color.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: round.color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: round.color.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        round.color.withValues(alpha: 0.34),
                        round.color.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          color: round.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Now entering bay',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              round.carName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FuelSpecChip(
                                  label: _vehicleMood(round.correctFuel),
                                  color: round.color,
                                ),
                                _FuelSpecChip(
                                  label: _fuelAudience(round.correctFuel),
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Driver note',
            child: Text(
              round.need,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DashboardSection(
            title: 'Best match',
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: round.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _FuelOptionCard._fuelIcon(round.correctFuel),
                    color: round.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${round.correctFuel} fits this vehicle profile best.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DashboardSection(
            title: gameOver ? 'Station update' : 'Control panel',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: gameOver ? const Color(0xffef4444) : round.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.74),
                      height: 1.45,
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

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FuelSpecChip extends StatelessWidget {
  const _FuelSpecChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StationInsightStrip extends StatelessWidget {
  const _StationInsightStrip({
    required this.currentFuel,
    required this.accent,
    required this.gameOver,
  });

  final String currentFuel;
  final Color accent;
  final bool gameOver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              gameOver ? Icons.restart_alt_rounded : Icons.auto_graph_rounded,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameOver ? 'Start fresh' : 'Featured pump vibe',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gameOver
                      ? 'Reset the station and jump back into a cleaner run.'
                      : '$currentFuel lane feels right for this request.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
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

class _FuelOptionCard extends StatelessWidget {
  const _FuelOptionCard({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [
                      color.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.03),
                    ],
            ),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _fuelIcon(label),
                  color: enabled ? color : Colors.white38,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: enabled
                            ? color.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _fuelTagline(label),
                        style: TextStyle(
                          color: enabled ? color : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white54,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fuelDescription(label),
                      style: TextStyle(
                        color: enabled
                            ? Colors.white.withValues(alpha: 0.72)
                            : Colors.white38,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: enabled ? Colors.white : Colors.white30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _fuelIcon(String label) {
    switch (label) {
      case 'Regular':
        return Icons.eco_rounded;
      case 'Premium':
        return Icons.bolt_rounded;
      case 'Diesel':
        return Icons.local_shipping_rounded;
      default:
        return Icons.local_gas_station_rounded;
    }
  }

  static String _fuelDescription(String label) {
    switch (label) {
      case 'Regular':
        return 'Best for standard petrol cars and daily city driving.';
      case 'Premium':
        return 'For high-performance petrol engines needing extra octane.';
      case 'Diesel':
        return 'Built for diesel vehicles, vans, and hauling machines.';
      default:
        return 'Select this pump for the current car.';
    }
  }

  static String _fuelTagline(String label) {
    switch (label) {
      case 'Regular':
        return 'CITY FRIENDLY';
      case 'Premium':
        return 'HIGH OCTANE';
      case 'Diesel':
        return 'HEAVY DUTY';
      default:
        return 'READY';
    }
  }
}

String _vehicleMood(String fuel) {
  switch (fuel) {
    case 'Regular':
      return 'Daily commute';
    case 'Premium':
      return 'Performance tuned';
    case 'Diesel':
      return 'Long-haul power';
    default:
      return 'General use';
  }
}

String _fuelAudience(String fuel) {
  switch (fuel) {
    case 'Regular':
      return 'Petrol standard';
    case 'Premium':
      return 'Turbo petrol';
    case 'Diesel':
      return 'Diesel engine';
    default:
      return 'Fuel match';
  }
}

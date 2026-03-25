import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';
import 'reward_action_button.dart';

class TurboTrafficScreen extends StatefulWidget {
  const TurboTrafficScreen({super.key});

  @override
  State<TurboTrafficScreen> createState() => _TurboTrafficScreenState();
}

class _TurboTrafficScreenState extends State<TurboTrafficScreen> {
  static const int _laneCount = 3;
  static const double _trackHeight = 360;
  static const double _playerCarHeight = 72;
  static const double _obstacleHeight = 64;

  final Random _random = Random();
  Timer? _timer;
  final List<_TrafficObstacle> _obstacles = [];
  final List<_TrafficPickup> _pickups = [];
  int _playerLane = 1;
  int _score = 0;
  int _bestScore = 0;
  int _speedLevel = 1;
  int _nearMisses = 0;
  int _coins = 0;
  int _boostFrames = 0;
  double _distance = 0;
  double _dashOffset = 0;
  bool _running = false;
  bool _crashed = false;
  bool _rewardContinueUsed = false;
  _TrafficSkin _selectedSkin = _TrafficSkin.cyan;
  String _message = 'Use left and right to stay clear of traffic.';

  @override
  void initState() {
    super.initState();
    _loadBest();
    _resetRace();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestScore = snapshot.turboTrafficBestScore;
    });
  }

  void _resetRace() {
    _playerLane = 1;
    _obstacles
      ..clear()
      ..add(
        _TrafficObstacle(
          lane: _random.nextInt(_laneCount),
          y: -_obstacleHeight,
        ),
      );
    _pickups.clear();
  }

  void _startRun() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _speedLevel = 1;
      _nearMisses = 0;
      _coins = 0;
      _boostFrames = 0;
      _distance = 0;
      _dashOffset = 0;
      _running = true;
      _crashed = false;
      _rewardContinueUsed = false;
      _message = 'Race on. Grab coins and hit boost pads when the road opens.';
      _resetRace();
    });
    _runLoop();
  }

  void _runLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) async {
      if (!mounted || !_running) return;
      final boosted = _boostFrames > 0;
      final speed = 5.0 + (_speedLevel * 0.75) + (boosted ? 2.8 : 0);
      final playerY = _trackHeight - _playerCarHeight - 14;
      final playerTop = playerY + 8;
      final playerBottom = playerY + _playerCarHeight - 8;

      var crashed = false;
      var dodgedCars = 0;
      var nearMissGain = 0;
      var collectedCoins = 0;
      var collectedBoost = false;
      final updatedObstacles = <_TrafficObstacle>[];
      final updatedPickups = <_TrafficPickup>[];

      for (final obstacle in _obstacles) {
        final nextY = obstacle.y + speed;
        final passedPlayer =
            obstacle.y + _obstacleHeight <= playerTop &&
            nextY + _obstacleHeight >= playerTop;
        final overlapsPlayer =
            obstacle.lane == _playerLane &&
            nextY < playerBottom &&
            nextY + _obstacleHeight > playerTop;

        if (overlapsPlayer) {
          crashed = true;
          break;
        }

        if (passedPlayer) {
          dodgedCars += 1;
          if ((obstacle.lane - _playerLane).abs() == 1) {
            nearMissGain += 1;
          }
        }

        if (nextY < _trackHeight + _obstacleHeight) {
          updatedObstacles.add(obstacle.copyWith(y: nextY));
        }
      }

      for (final pickup in _pickups) {
        final nextY = pickup.y + speed;
        final overlapsPlayer =
            pickup.lane == _playerLane &&
            nextY < playerBottom &&
            nextY + pickup.height > playerTop;

        if (overlapsPlayer) {
          if (pickup.type == _TrafficPickupType.coin) {
            collectedCoins += 1;
          } else {
            collectedBoost = true;
          }
          continue;
        }

        if (nextY < _trackHeight + pickup.height) {
          updatedPickups.add(pickup.copyWith(y: nextY));
        }
      }

      if (crashed) {
        timer.cancel();
        await _finishRun();
        return;
      }

      final newDistance = _distance + speed * 1.5;
      final shouldSpawn =
          updatedObstacles.isEmpty ||
          updatedObstacles.last.y > 92 + _random.nextInt(70);

      if (shouldSpawn) {
        final blockedLane = updatedObstacles.isNotEmpty
            ? updatedObstacles.last.lane
            : -1;
        int nextLane = _random.nextInt(_laneCount);
        if (nextLane == blockedLane) {
          nextLane =
              (nextLane + 1 + _random.nextInt(_laneCount - 1)) % _laneCount;
        }
        updatedObstacles.add(
          _TrafficObstacle(lane: nextLane, y: -_obstacleHeight),
        );
      }

      if (_random.nextDouble() < 0.04 && updatedPickups.length < 2) {
        updatedPickups.add(
          _TrafficPickup(
            lane: _random.nextInt(_laneCount),
            y: -40,
            type: _random.nextDouble() < 0.75
                ? _TrafficPickupType.coin
                : _TrafficPickupType.boost,
          ),
        );
      }

      setState(() {
        _obstacles
          ..clear()
          ..addAll(updatedObstacles);
        _pickups
          ..clear()
          ..addAll(updatedPickups);
        _distance = newDistance;
        _dashOffset = (_dashOffset + speed) % 48;
        if (dodgedCars > 0) {
          _score += dodgedCars;
          _nearMisses += nearMissGain;
        }
        if (collectedCoins > 0) {
          _coins += collectedCoins;
          _score += collectedCoins;
        }
        if (collectedBoost) {
          _boostFrames = 40;
        } else if (_boostFrames > 0) {
          _boostFrames -= 1;
        }
        _speedLevel = 1 + (_score ~/ 5);
        _message = collectedBoost
            ? 'Boost engaged. Fly through the gap.'
            : collectedCoins > 0
            ? 'Coin line collected. Keep pushing.'
            : dodgedCars > 0
            ? nearMissGain > 0
                  ? 'Near miss. Stay sharp.'
                  : 'Clean pass. Keep the line.'
            : boosted
            ? 'Boost active. Distance ${(newDistance / 10).floor()} m.'
            : 'Distance ${(newDistance / 10).floor()} m.';
      });
    });
  }

  Future<void> _finishRun() async {
    final isBest = _score > _bestScore;
    if (isBest) {
      await GameStatsStore.instance.recordTurboTrafficBestScore(_score);
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _crashed = true;
      if (isBest) {
        _bestScore = _score;
      }
      _message = isBest
          ? 'Crash, but new best. You dodged $_score cars.'
          : 'Crash. You dodged $_score cars over ${(_distance / 10).floor()} m.';
    });
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
  }

  Future<void> _continueAfterCrash() async {
    if (_running || !_crashed || _rewardContinueUsed) return;
    final earned = await RewardedAdService.instance.show(
      context: context,
      onRewardEarned: () {
        if (!mounted) return;
        final clearFromY = _trackHeight - _playerCarHeight - 120;
        setState(() {
          _crashed = false;
          _running = true;
          _rewardContinueUsed = true;
          _boostFrames = max(_boostFrames, 20);
          _obstacles.removeWhere(
            (obstacle) =>
                obstacle.lane == _playerLane && obstacle.y >= clearFromY,
          );
          _pickups.removeWhere(
            (pickup) => pickup.lane == _playerLane && pickup.y >= clearFromY,
          );
          _message = 'Bonus continue unlocked. Back into traffic.';
        });
        _runLoop();
      },
      unavailableMessage: 'Add a rewarded ad unit to unlock continue rewards.',
    );
    if (!earned && mounted) {
      showGameAdSnackBar(
        context,
        'Continue reward was not unlocked this time.',
      );
    }
  }

  void _shiftLane(int delta) {
    if (!_running) return;
    setState(() {
      _playerLane = (_playerLane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0 ? 'Cutting left.' : 'Cutting right.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Turbo Traffic',
      subtitle: 'Thread the car through traffic and survive the rush.',
      accent: const [Color(0xfff97316), Color(0xffef4444)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Dodges',
            leftValue: _score.toString(),
            rightLabel: 'Best',
            rightValue: _bestScore.toString(),
            footer:
                'Coins $_coins • Speed $_speedLevel • Near misses $_nearMisses • Distance ${(_distance / 10).floor()} m',
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < 0) {
                  _shiftLane(-1);
                } else if (details.primaryVelocity! > 0) {
                  _shiftLane(1);
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth / _laneCount;
                  final playerY = _trackHeight - _playerCarHeight - 14;
                  return Container(
                    height: _trackHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xff0f172a), Color(0xff111827)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Row(
                            children: List.generate(_laneCount, (lane) {
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: lane == _laneCount - 1
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        ...List.generate(8, (index) {
                          final top =
                              ((index * 56.0) + _dashOffset) %
                                  (_trackHeight + 40) -
                              40;
                          return Positioned(
                            left: constraints.maxWidth / 2 - 3,
                            top: top,
                            child: Container(
                              height: 26,
                              width: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }),
                        ..._obstacles.map((obstacle) {
                          final left =
                              (obstacle.lane * laneWidth) +
                              (laneWidth - 42) / 2;
                          return Positioned(
                            left: left,
                            top: obstacle.y,
                            child: _TrafficCar(
                              color: obstacle.lane == 0
                                  ? const Color(0xfffb7185)
                                  : obstacle.lane == 1
                                  ? const Color(0xfff59e0b)
                                  : const Color(0xffa78bfa),
                              icon: Icons.local_shipping_rounded,
                            ),
                          );
                        }),
                        ..._pickups.map((pickup) {
                          final left =
                              (pickup.lane * laneWidth) +
                              (laneWidth - pickup.width) / 2;
                          return Positioned(
                            left: left,
                            top: pickup.y,
                            child: _TrafficPickupWidget(type: pickup.type),
                          );
                        }),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOut,
                          left:
                              (_playerLane * laneWidth) + (laneWidth - 44) / 2,
                          top: playerY,
                          child: _TrafficCar(
                            color: _crashed
                                ? const Color(0xffef4444)
                                : _selectedSkin.color,
                            icon: Icons.directions_car_filled_rounded,
                            highlight: true,
                            boosted: _boostFrames > 0,
                          ),
                        ),
                        if (!_running)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: Colors.black.withValues(alpha: 0.32),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_flags_rounded,
                                    color: Colors.white,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _crashed
                                        ? 'Tap Start to race again'
                                        : 'Tap Start and steer around traffic',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xffef4444)),
          const SizedBox(height: 14),
          if (_crashed && !_running && !_rewardContinueUsed) ...[
            RewardActionButton(
              label: 'Watch ad to continue the race',
              onPressed: _continueAfterCrash,
            ),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _TrafficSkin.values
                .map((skin) {
                  final selected = skin == _selectedSkin;
                  return GestureDetector(
                    onTap: _running
                        ? null
                        : () => setState(() {
                            _selectedSkin = skin;
                            _message =
                                '${skin.label} car ready for the next run.';
                          }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selected
                            ? skin.color.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: selected
                              ? skin.color
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 14,
                            width: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: skin.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            skin.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _shiftLane(-1) : _startRun,
                  child: Text(_running ? 'Move left' : 'Start run'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _shiftLane(1) : null,
                  child: const Text('Move right'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResetActionButton(
            label: _running ? 'Restart race' : 'Reset track',
            onPressed: _startRun,
          ),
        ],
      ),
    );
  }
}

class _TrafficObstacle {
  const _TrafficObstacle({required this.lane, required this.y});

  final int lane;
  final double y;

  _TrafficObstacle copyWith({int? lane, double? y}) {
    return _TrafficObstacle(lane: lane ?? this.lane, y: y ?? this.y);
  }
}

class _TrafficPickup {
  const _TrafficPickup({
    required this.lane,
    required this.y,
    required this.type,
  });

  final int lane;
  final double y;
  final _TrafficPickupType type;

  double get width => type == _TrafficPickupType.coin ? 24 : 30;
  double get height => type == _TrafficPickupType.coin ? 24 : 30;

  _TrafficPickup copyWith({int? lane, double? y, _TrafficPickupType? type}) {
    return _TrafficPickup(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      type: type ?? this.type,
    );
  }
}

enum _TrafficPickupType { coin, boost }

enum _TrafficSkin {
  cyan('Cyan', Color(0xff38bdf8)),
  lime('Lime', Color(0xff84cc16)),
  violet('Violet', Color(0xffa78bfa)),
  sunset('Sunset', Color(0xfffb7185));

  const _TrafficSkin(this.label, this.color);

  final String label;
  final Color color;
}

class _TrafficCar extends StatelessWidget {
  const _TrafficCar({
    required this.color,
    required this.icon,
    this.highlight = false,
    this.boosted = false,
  });

  final Color color;
  final IconData icon;
  final bool highlight;
  final bool boosted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _TurboTrafficScreenState._obstacleHeight,
      width: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.92), color],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          if (highlight)
            BoxShadow(
              color: color.withValues(alpha: boosted ? 0.52 : 0.32),
              blurRadius: boosted ? 24 : 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Icon(icon, color: Colors.white, size: 20),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            height: 6,
            width: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficPickupWidget extends StatelessWidget {
  const _TrafficPickupWidget({required this.type});

  final _TrafficPickupType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _TrafficPickupType.coin:
        return Container(
          height: 24,
          width: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xfffcd34d), Color(0xfff59e0b)],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.monetization_on_rounded,
              color: Color(0xff78350f),
              size: 16,
            ),
          ),
        );
      case _TrafficPickupType.boost:
        return Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xff22d3ee), Color(0xff2563eb)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff38bdf8).withValues(alpha: 0.35),
                blurRadius: 14,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
          ),
        );
    }
  }
}

class BikeSprintScreen extends StatefulWidget {
  const BikeSprintScreen({super.key});

  @override
  State<BikeSprintScreen> createState() => _BikeSprintScreenState();
}

class _BikeSprintScreenState extends State<BikeSprintScreen> {
  static const int _roundSeconds = 18;

  Timer? _timer;
  Timer? _meterTimer;
  double _needle = 0.2;
  double _direction = 0.08;
  int _level = 1;
  int _timeLeft = _roundSeconds;
  int _distance = 0;
  int _bestDistance = 0;
  int _combo = 0;
  int _perfectBoosts = 0;
  bool _running = false;
  bool _rewardBoostUsed = false;
  String _message = 'Tap boost while the needle is inside the green zone.';

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _meterTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestDistance = snapshot.bikeSprintBestDistance;
    });
  }

  int get _targetDistance => 140 + ((_level - 1) * 45);

  void _startRide() {
    _timer?.cancel();
    _meterTimer?.cancel();
    setState(() {
      _running = true;
      _timeLeft = _roundSeconds;
      _distance = 0;
      _combo = 0;
      _perfectBoosts = 0;
      _rewardBoostUsed = false;
      _needle = 0.2;
      _direction = 0.08 + ((_level - 1) * 0.006);
      _message = 'Level $_level: ride to $_targetDistance m.';
    });

    _meterTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted || !_running) return;
      setState(() {
        _needle += _direction;
        if (_needle >= 1.0 || _needle <= 0.0) {
          _direction *= -1;
          _needle = _needle.clamp(0.0, 1.0);
        }
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        _meterTimer?.cancel();
        final isBest = _distance > _bestDistance;
        if (isBest) {
          await GameStatsStore.instance.recordBikeSprintBestDistance(_distance);
        }
        if (!mounted) return;
        setState(() {
          _running = false;
          _timeLeft = 0;
          if (isBest) {
            _bestDistance = _distance;
          }
          _message = isBest
              ? 'Photo finish. New best distance: $_distance m.'
              : 'Ride complete. You covered $_distance m.';
        });
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        return;
      }
      setState(() {
        _timeLeft -= 1;
      });
    });
  }

  void _boost() {
    if (!_running) return;
    final inPerfectZone = _needle >= 0.42 && _needle <= 0.62;
    final inGoodZone = _needle >= 0.28 && _needle <= 0.76;
    var nextDistance = _distance;
    var nextCombo = _combo;
    var nextPerfectBoosts = _perfectBoosts;
    var nextMessage = _message;

    if (inPerfectZone) {
      nextCombo += 1;
      nextPerfectBoosts += 1;
      nextDistance += 18 + (nextCombo * 2);
      nextMessage = 'Perfect push. Combo x$nextCombo.';
    } else if (inGoodZone) {
      nextCombo = 0;
      nextDistance += 10;
      nextMessage = 'Solid push. Keep the cadence steady.';
    } else {
      nextCombo = 0;
      nextDistance = max(0, nextDistance - 4);
      nextMessage = 'Bad timing. You lost momentum.';
    }

    if (nextDistance >= _targetDistance) {
      _timer?.cancel();
      _meterTimer?.cancel();
      setState(() {
        _distance = nextDistance;
        _combo = nextCombo;
        _perfectBoosts = nextPerfectBoosts;
        if (nextDistance > _bestDistance) {
          _bestDistance = nextDistance;
        }
        _running = false;
        _level += 1;
        _message = 'Level clear. Level $_level is ready.';
      });
      if (nextDistance > _bestDistance) {
        GameStatsStore.instance.recordBikeSprintBestDistance(nextDistance);
      }
      GameInterstitialService.instance.registerRoundCompletion();
      GameInterstitialService.instance.maybeShow();
      return;
    }

    setState(() {
      _distance = nextDistance;
      _combo = nextCombo;
      _perfectBoosts = nextPerfectBoosts;
      _message = nextMessage;
    });
  }

  void _resetSprint() {
    _timer?.cancel();
    _meterTimer?.cancel();
    setState(() {
      _level = 1;
      _timeLeft = _roundSeconds;
      _distance = 0;
      _combo = 0;
      _perfectBoosts = 0;
      _running = false;
      _needle = 0.2;
      _direction = 0.08;
      _rewardBoostUsed = false;
      _message = 'Tap boost while the needle is inside the green zone.';
    });
  }

  Future<void> _watchAdForBonusBoost() async {
    if (!_running || _rewardBoostUsed) return;
    final earned = await RewardedAdService.instance.show(
      context: context,
      onRewardEarned: () {
        if (!mounted) return;
        final nextDistance = _distance + 35;
        final reachedGoal = nextDistance >= _targetDistance;
        setState(() {
          _rewardBoostUsed = true;
          _distance = nextDistance;
          _combo += 1;
          _message = reachedGoal
              ? 'Reward boost launched you across the finish line.'
              : 'Reward boost unlocked. +35 m distance.';
        });
        if (reachedGoal) {
          _timer?.cancel();
          _meterTimer?.cancel();
          final finalDistance = _distance;
          final beatBest = finalDistance > _bestDistance;
          setState(() {
            _running = false;
            _level += 1;
            if (beatBest) {
              _bestDistance = finalDistance;
            }
            _message = 'Reward boost clear. Level $_level is ready.';
          });
          if (beatBest) {
            GameStatsStore.instance.recordBikeSprintBestDistance(finalDistance);
          }
          GameInterstitialService.instance.registerRoundCompletion();
          GameInterstitialService.instance.maybeShow();
        }
      },
      unavailableMessage: 'Add a rewarded ad unit to unlock bonus boosts.',
    );
    if (!earned && mounted) {
      showGameAdSnackBar(context, 'Bonus boost was not unlocked this time.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Bike Sprint',
      subtitle: 'Time each pedal burst to hit the fastest line.',
      accent: const [Color(0xff06b6d4), Color(0xff2563eb)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Best',
            rightValue: '${_bestDistance}m',
            footer:
                'Distance ${_distance}m/$_targetDistance m • Time left ${_timeLeft}s • Perfect $_perfectBoosts',
          ),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                const Icon(
                  Icons.pedal_bike_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final trackWidth = constraints.maxWidth;
                    final markerLeft = max(0.0, (trackWidth - 8) * _needle);
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 22,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.18,
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(
                                0xfff59e0b,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(-0.02, 0),
                          child: FractionallySizedBox(
                            widthFactor: 0.22,
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: const Color(
                                  0xff22c55e,
                                ).withValues(alpha: 0.62),
                              ),
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: 0.18,
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(
                                0xfff59e0b,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        Positioned(
                          left: markerLeft,
                          child: Container(
                            height: 34,
                            width: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff2563eb)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _running ? _boost : _startRide,
              child: Text(_running ? 'Boost now' : 'Start sprint'),
            ),
          ),
          const SizedBox(height: 10),
          if (_running && !_rewardBoostUsed) ...[
            RewardActionButton(
              label: 'Watch ad for bonus boost',
              onPressed: _watchAdForBonusBoost,
            ),
            const SizedBox(height: 10),
          ],
          ResetActionButton(label: 'Reset levels', onPressed: _resetSprint),
        ],
      ),
    );
  }
}

class CycleDashScreen extends StatefulWidget {
  const CycleDashScreen({super.key});

  @override
  State<CycleDashScreen> createState() => _CycleDashScreenState();
}

class _CycleDashScreenState extends State<CycleDashScreen> {
  static const int _laneCount = 3;
  static const double _trackHeight = 280;

  final Random _random = Random();
  Timer? _timer;
  final List<_CycleItem> _items = [];
  int _lane = 1;
  int _distance = 0;
  int _bestDistance = 0;
  int _stars = 0;
  int _hearts = 3;
  double _scrollOffset = 0;
  bool _running = false;
  bool _rewardContinueUsed = false;
  String _message = 'Tap start, then move left or right to collect stars.';

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestDistance = snapshot.cycleDashBestDistance;
    });
  }

  void _resetRide() {
    _timer?.cancel();
    setState(() {
      _lane = 1;
      _distance = 0;
      _stars = 0;
      _hearts = 3;
      _scrollOffset = 0;
      _running = false;
      _rewardContinueUsed = false;
      _items.clear();
      _message = 'Tap start, then move left or right to collect stars.';
    });
  }

  void _startRide() {
    _timer?.cancel();
    setState(() {
      _lane = 1;
      _distance = 0;
      _stars = 0;
      _hearts = 3;
      _scrollOffset = 0;
      _running = true;
      _rewardContinueUsed = false;
      _items.clear();
      _message = 'Ride on. Grab stars and avoid puddles.';
    });
    _runRideLoop();
  }

  void _runRideLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) async {
      if (!mounted || !_running) return;

      final speed = 18 + min(18, _distance ~/ 20);
      var gainedStars = 0;
      var hitPuddle = false;
      final updatedItems = <_CycleItem>[];

      for (final item in _items) {
        final nextY = item.y + speed;
        final reachedBike = nextY >= 214 && nextY <= 252 && item.lane == _lane;

        if (reachedBike) {
          if (item.kind == _CycleItemKind.star) {
            gainedStars += 1;
          } else {
            hitPuddle = true;
          }
          continue;
        }

        if (nextY < _trackHeight + 36) {
          updatedItems.add(item.copyWith(y: nextY));
        }
      }

      if (_random.nextDouble() < 0.42) {
        updatedItems.add(
          _CycleItem(
            lane: _random.nextInt(_laneCount),
            y: -24,
            kind: _random.nextDouble() < 0.68
                ? _CycleItemKind.star
                : _CycleItemKind.puddle,
          ),
        );
      }

      final nextHearts = hitPuddle ? _hearts - 1 : _hearts;
      final nextDistance = _distance + (gainedStars > 0 ? 10 : 6);

      if (nextHearts <= 0) {
        final isBest = nextDistance > _bestDistance;
        if (isBest) {
          await GameStatsStore.instance.recordCycleDashBestDistance(
            nextDistance,
          );
        }
        if (!mounted) return;
        setState(() {
          _running = false;
          _distance = nextDistance;
          _stars += gainedStars;
          _hearts = 0;
          _items
            ..clear()
            ..addAll(updatedItems);
          if (isBest) {
            _bestDistance = nextDistance;
          }
          _message = isBest
              ? 'New best ride. You reached ${nextDistance}m.'
              : 'Oops, splash. You reached ${nextDistance}m.';
        });
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        return;
      }

      setState(() {
        _distance = nextDistance;
        _stars += gainedStars;
        _hearts = nextHearts;
        _scrollOffset = (_scrollOffset + 16) % 44;
        _items
          ..clear()
          ..addAll(updatedItems);
        _message = hitPuddle
            ? 'Splash. Be careful.'
            : gainedStars > 0
            ? 'Nice. Star collected.'
            : 'Keep riding.';
      });
    });
  }

  Future<void> _continueRideWithReward() async {
    if (_running || _hearts > 0 || _rewardContinueUsed) return;
    final earned = await RewardedAdService.instance.show(
      context: context,
      onRewardEarned: () {
        if (!mounted) return;
        setState(() {
          _hearts = 1;
          _running = true;
          _rewardContinueUsed = true;
          _items.removeWhere(
            (item) => item.lane == _lane && item.y >= _trackHeight - 90,
          );
          _message = 'Extra heart unlocked. Ride again.';
        });
        _runRideLoop();
      },
      unavailableMessage: 'Add a rewarded ad unit to unlock continue rewards.',
    );
    if (!earned && mounted) {
      showGameAdSnackBar(context, 'Ride continue was not unlocked this time.');
    }
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _lane = (_lane + delta).clamp(0, _laneCount - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Cycle Dash',
      subtitle:
          'A simple cycle ride for kids. Collect stars and dodge puddles.',
      accent: const [Color(0xff22c55e), Color(0xff84cc16)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Distance',
            leftValue: '${_distance}m',
            rightLabel: 'Stars',
            rightValue: _stars.toString(),
            footer: 'Best ${_bestDistance}m • Hearts $_hearts',
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < 0) {
                  _move(-1);
                } else if (details.primaryVelocity! > 0) {
                  _move(1);
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth / _laneCount;
                  return Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xff14532d), Color(0xff166534)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Row(
                            children: List.generate(_laneCount, (index) {
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: index == _laneCount - 1
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        ...List.generate(7, (index) {
                          final top =
                              ((index * 48.0) + _scrollOffset) %
                                  (_trackHeight + 30) -
                              30;
                          return Positioned(
                            left: constraints.maxWidth / 2 - 22,
                            top: top,
                            child: Container(
                              height: 18,
                              width: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                          );
                        }),
                        ..._items.map((item) {
                          final left =
                              (item.lane * laneWidth) + (laneWidth - 28) / 2;
                          return Positioned(
                            left: left,
                            top: item.y,
                            child: item.kind == _CycleItemKind.star
                                ? const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xfffde047),
                                    size: 28,
                                  )
                                : Container(
                                    height: 28,
                                    width: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(
                                        0xff0f172a,
                                      ).withValues(alpha: 0.6),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.water_drop_rounded,
                                        color: Color(0xff38bdf8),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                          );
                        }),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOut,
                          left: (_lane * laneWidth) + (laneWidth - 42) / 2,
                          bottom: 20,
                          child: Column(
                            children: [
                              const Text('🙂', style: TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Container(
                                height: 54,
                                width: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xfffacc15),
                                      Color(0xfff59e0b),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.pedal_bike_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_running)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Tap Start\nCollect stars\nAvoid puddles',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff84cc16)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _move(-1) : _startRide,
                  child: Text(_running ? 'Move left' : 'Start ride'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _move(1) : null,
                  child: const Text('Move right'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_hearts == 0 && !_running && !_rewardContinueUsed) ...[
            RewardActionButton(
              label: 'Watch ad to restore 1 heart',
              onPressed: _continueRideWithReward,
            ),
            const SizedBox(height: 10),
          ],
          ResetActionButton(label: 'Reset ride', onPressed: _resetRide),
        ],
      ),
    );
  }
}

class _CycleItem {
  const _CycleItem({required this.lane, required this.y, required this.kind});

  final int lane;
  final double y;
  final _CycleItemKind kind;

  _CycleItem copyWith({int? lane, double? y, _CycleItemKind? kind}) {
    return _CycleItem(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      kind: kind ?? this.kind,
    );
  }
}

enum _CycleItemKind { star, puddle }

class AvatarRushScreen extends StatefulWidget {
  const AvatarRushScreen({super.key});

  @override
  State<AvatarRushScreen> createState() => _AvatarRushScreenState();
}

class _AvatarRushScreenState extends State<AvatarRushScreen> {
  static const int _laneCount = 3;
  static const double _trackHeight = 300;

  final Random _random = Random();
  Timer? _timer;
  final List<_AvatarItem> _items = [];
  int _lane = 1;
  int _score = 0;
  int _bestScore = 0;
  int _lives = 3;
  int _stars = 0;
  double _scrollOffset = 0;
  bool _running = false;
  bool _rewardContinueUsed = false;
  String _message = 'Tap start, then move left or right to catch stars.';

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestScore = snapshot.avatarRushBestScore;
    });
  }

  void _resetRun() {
    _timer?.cancel();
    setState(() {
      _lane = 1;
      _score = 0;
      _lives = 3;
      _stars = 0;
      _scrollOffset = 0;
      _running = false;
      _rewardContinueUsed = false;
      _items.clear();
      _message = 'Tap start, then move left or right to catch stars.';
    });
  }

  void _startRun() {
    _timer?.cancel();
    setState(() {
      _lane = 1;
      _score = 0;
      _lives = 3;
      _stars = 0;
      _scrollOffset = 0;
      _running = true;
      _rewardContinueUsed = false;
      _items.clear();
      _message = 'Run fast. Catch stars and dodge blocks.';
    });
    _runLoop();
  }

  void _runLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) async {
      if (!mounted || !_running) return;

      final speed = 16 + min(20, _score);
      var gainedStars = 0;
      var hitBlock = false;
      final updatedItems = <_AvatarItem>[];

      for (final item in _items) {
        final nextY = item.y + speed;
        final reachedRunner =
            nextY >= 226 && nextY <= 264 && item.lane == _lane;

        if (reachedRunner) {
          if (item.kind == _AvatarItemKind.star) {
            gainedStars += 1;
          } else {
            hitBlock = true;
          }
          continue;
        }

        if (nextY < _trackHeight + 34) {
          updatedItems.add(item.copyWith(y: nextY));
        }
      }

      if (_random.nextDouble() < 0.44) {
        updatedItems.add(
          _AvatarItem(
            lane: _random.nextInt(_laneCount),
            y: -28,
            kind: _random.nextDouble() < 0.7
                ? _AvatarItemKind.star
                : _AvatarItemKind.block,
          ),
        );
      }

      final nextLives = hitBlock ? _lives - 1 : _lives;
      final nextScore = _score + gainedStars + 1;

      if (nextLives <= 0) {
        final isBest = nextScore > _bestScore;
        if (isBest) {
          await GameStatsStore.instance.recordAvatarRushBestScore(nextScore);
        }
        if (!mounted) return;
        setState(() {
          _running = false;
          _score = nextScore;
          _stars += gainedStars;
          _lives = 0;
          _items
            ..clear()
            ..addAll(updatedItems);
          if (isBest) {
            _bestScore = nextScore;
          }
          _message = isBest
              ? 'New best run. You reached $nextScore.'
              : 'Oops, you were bumped. Score $nextScore.';
        });
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        return;
      }

      setState(() {
        _score = nextScore;
        _stars += gainedStars;
        _lives = nextLives;
        _scrollOffset = (_scrollOffset + 14) % 46;
        _items
          ..clear()
          ..addAll(updatedItems);
        _message = hitBlock
            ? 'Ouch. Avoid the blocks.'
            : gainedStars > 0
            ? 'Nice catch.'
            : 'Keep running.';
      });
    });
  }

  Future<void> _continueRunWithReward() async {
    if (_running || _lives > 0 || _rewardContinueUsed) return;
    final earned = await RewardedAdService.instance.show(
      context: context,
      onRewardEarned: () {
        if (!mounted) return;
        setState(() {
          _lives = 1;
          _running = true;
          _rewardContinueUsed = true;
          _items.removeWhere(
            (item) => item.lane == _lane && item.y >= _trackHeight - 92,
          );
          _message = 'Bonus continue unlocked. Back on the track.';
        });
        _runLoop();
      },
      unavailableMessage: 'Add a rewarded ad unit to unlock continue rewards.',
    );
    if (!earned && mounted) {
      showGameAdSnackBar(context, 'Run continue was not unlocked this time.');
    }
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _lane = (_lane + delta).clamp(0, _laneCount - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Avatar Rush',
      subtitle: 'A simple runner game. Catch stars and dodge blocks.',
      accent: const [Color(0xff8b5cf6), Color(0xffec4899)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Score',
            leftValue: _score.toString(),
            rightLabel: 'Lives',
            rightValue: _lives.toString(),
            footer: 'Stars $_stars • Best run $_bestScore',
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < 0) {
                  _move(-1);
                } else if (details.primaryVelocity! > 0) {
                  _move(1);
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth / _laneCount;
                  return Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xff312e81), Color(0xff831843)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Row(
                            children: List.generate(_laneCount, (index) {
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: index == _laneCount - 1
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        ...List.generate(7, (index) {
                          final top =
                              ((index * 50.0) + _scrollOffset) %
                                  (_trackHeight + 30) -
                              30;
                          return Positioned(
                            left: constraints.maxWidth / 2 - 16,
                            top: top,
                            child: Container(
                              height: 16,
                              width: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                          );
                        }),
                        ..._items.map((item) {
                          final left =
                              (item.lane * laneWidth) + (laneWidth - 30) / 2;
                          return Positioned(
                            left: left,
                            top: item.y,
                            child: item.kind == _AvatarItemKind.star
                                ? const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xfffde047),
                                    size: 30,
                                  )
                                : Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: const Color(0xff1f2937),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.stop_rounded,
                                        color: Color(0xfffb7185),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                          );
                        }),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          left: (_lane * laneWidth) + (laneWidth - 42) / 2,
                          bottom: 20,
                          child: Column(
                            children: [
                              const Text('😄', style: TextStyle(fontSize: 22)),
                              const SizedBox(height: 2),
                              Container(
                                height: 56,
                                width: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xffc084fc),
                                      Color(0xffec4899),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.directions_run_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_running)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                color: Colors.black.withValues(alpha: 0.22),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Tap Start\nCatch stars\nAvoid blocks',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xffec4899)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _move(-1) : _startRun,
                  child: Text(_running ? 'Move left' : 'Start run'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _move(1) : null,
                  child: const Text('Move right'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_lives == 0 && !_running && !_rewardContinueUsed) ...[
            RewardActionButton(
              label: 'Watch ad to continue the run',
              onPressed: _continueRunWithReward,
            ),
            const SizedBox(height: 10),
          ],
          ResetActionButton(label: 'Reset run', onPressed: _resetRun),
        ],
      ),
    );
  }
}

class _AvatarItem {
  const _AvatarItem({required this.lane, required this.y, required this.kind});

  final int lane;
  final double y;
  final _AvatarItemKind kind;

  _AvatarItem copyWith({int? lane, double? y, _AvatarItemKind? kind}) {
    return _AvatarItem(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      kind: kind ?? this.kind,
    );
  }
}

enum _AvatarItemKind { star, block }

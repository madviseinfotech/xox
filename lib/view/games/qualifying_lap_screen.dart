import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class QualifyingLapScreen extends StatefulWidget {
  const QualifyingLapScreen({super.key});

  @override
  State<QualifyingLapScreen> createState() => _QualifyingLapScreenState();
}

class _QualifyingLapScreenState extends State<QualifyingLapScreen> {
  static const Duration _tick = Duration(milliseconds: 50);
  static const double _trackLength = 2600;
  static const double _maxOffset = 1.0;
  static const int _targetTimeMs = 78500;
  static const List<_QualiSection> _sections = [
    _QualiSection(
      label: 'Start Straight',
      start: 0.00,
      end: 0.16,
      targetSpeed: 228,
      curve: 0.00,
      drsAllowed: true,
    ),
    _QualiSection(
      label: 'Turn 1',
      start: 0.16,
      end: 0.30,
      targetSpeed: 108,
      curve: 0.74,
      drsAllowed: false,
    ),
    _QualiSection(
      label: 'Middle Sweep',
      start: 0.30,
      end: 0.48,
      targetSpeed: 186,
      curve: -0.28,
      drsAllowed: false,
    ),
    _QualiSection(
      label: 'Back Straight',
      start: 0.48,
      end: 0.66,
      targetSpeed: 234,
      curve: 0.02,
      drsAllowed: true,
    ),
    _QualiSection(
      label: 'Hairpin',
      start: 0.66,
      end: 0.80,
      targetSpeed: 84,
      curve: -0.92,
      drsAllowed: false,
    ),
    _QualiSection(
      label: 'Final Sector',
      start: 0.80,
      end: 1.00,
      targetSpeed: 168,
      curve: 0.36,
      drsAllowed: false,
    ),
  ];

  Timer? _timer;
  final Stopwatch _lapClock = Stopwatch();

  double _speed = 0;
  double _distance = 0;
  double _offset = 0;
  double _grip = 100;
  double _tireTemp = 82;
  int _drsFrames = 0;
  int _currentSector = 1;
  int? _sector1Ms;
  int? _sector2Ms;
  bool _running = false;
  bool _finished = false;
  bool _throttleHeld = false;
  bool _brakeHeld = false;
  bool _leftHeld = false;
  bool _rightHeld = false;
  String _message =
      'Build one clean qualifying lap. Brake hard, hit the apex, and use DRS on the straights.';

  @override
  void dispose() {
    _timer?.cancel();
    _lapClock.stop();
    super.dispose();
  }

  double get _progress => (_distance % _trackLength) / _trackLength;

  _QualiSection get _section => _sectionFor(_progress);

  double get _ghostDistance {
    final elapsedRatio = (_lapClock.elapsedMilliseconds / _targetTimeMs).clamp(
      0.0,
      1.15,
    );
    return elapsedRatio * _trackLength;
  }

  int get _gapMeters => ((_ghostDistance - _distance) / 10).round();

  void _startLap() {
    _timer?.cancel();
    _lapClock
      ..stop()
      ..reset()
      ..start();
    setState(() {
      _speed = 0;
      _distance = 0;
      _offset = 0;
      _grip = 100;
      _tireTemp = 82;
      _drsFrames = 0;
      _currentSector = 1;
      _sector1Ms = null;
      _sector2Ms = null;
      _running = true;
      _finished = false;
      _throttleHeld = false;
      _brakeHeld = false;
      _leftHeld = false;
      _rightHeld = false;
      _message = 'Push lap started. Warm the tires and attack Turn 1 cleanly.';
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  _QualiSection _sectionFor(double progress) {
    return _sections.firstWhere(
      (section) => progress >= section.start && progress < section.end,
      orElse: () => _sections.last,
    );
  }

  Future<void> _onTick() async {
    if (!_running || !mounted) return;

    final section = _section;
    var nextSpeed = _speed;
    if (_throttleHeld) {
      nextSpeed += 7.1;
    } else {
      nextSpeed -= 3.0;
    }
    if (_brakeHeld) {
      nextSpeed -= 10.8;
    }
    if (_drsFrames > 0 && section.drsAllowed && section.curve.abs() < 0.12) {
      nextSpeed += 4.0;
    }
    nextSpeed = nextSpeed.clamp(0.0, 246.0);

    var steerForce = 0.0;
    if (_leftHeld) steerForce -= 0.084;
    if (_rightHeld) steerForce += 0.084;

    final targetOffset = (-section.curve * 0.56).clamp(-_maxOffset, _maxOffset);
    var nextOffset = _offset + steerForce;
    if (!_leftHeld && !_rightHeld) {
      nextOffset += (targetOffset - nextOffset) * 0.13;
    }
    nextOffset = nextOffset.clamp(-1.2, 1.2);

    var nextGrip = _grip;
    var nextTemp = _tireTemp;
    final overspeed = math.max(0, nextSpeed - section.targetSpeed).toDouble();
    final lineError = (nextOffset - targetOffset).abs();
    final cornerLoad = section.curve.abs();

    if (cornerLoad > 0.2) {
      nextGrip -= overspeed * 0.046;
      nextGrip -= lineError * 6.0;
      nextTemp += 0.85 + (overspeed * 0.012);
    } else {
      nextGrip += 1.3;
      nextTemp -= 0.65;
    }
    if (_drsFrames > 0) {
      nextTemp += 0.32;
    }
    nextGrip = nextGrip.clamp(0.0, 100.0);
    nextTemp = nextTemp.clamp(72.0, 118.0);

    if (nextGrip <= 0 || nextOffset.abs() > 1.1) {
      await _finishLap(
        won: false,
        reason: 'Lap invalidated. You ran out of road and lost the car.',
      );
      return;
    }

    final previousDistance = _distance;
    final nextDistance = previousDistance + (nextSpeed * 0.8);
    final nextProgress = (nextDistance / _trackLength).clamp(0.0, 1.2);

    if (_sector1Ms == null && nextProgress >= 0.33) {
      _sector1Ms = _lapClock.elapsedMilliseconds;
      _currentSector = 2;
    }
    if (_sector2Ms == null && nextProgress >= 0.66) {
      _sector2Ms = _lapClock.elapsedMilliseconds;
      _currentSector = 3;
    }

    if (nextDistance >= _trackLength) {
      _distance = nextDistance;
      await _finishLap(
        won: _lapClock.elapsedMilliseconds <= _targetTimeMs,
        reason: _lapClock.elapsedMilliseconds <= _targetTimeMs
            ? 'Front-row lap. You beat the target qualifying time.'
            : 'Lap complete, but you missed the target marker.',
      );
      return;
    }

    setState(() {
      _speed = nextSpeed;
      _distance = nextDistance;
      _offset = nextOffset;
      _grip = nextGrip;
      _tireTemp = nextTemp;
      _drsFrames = math.max(0, _drsFrames - 1);
      if (cornerLoad > 0.2 && overspeed > 16) {
        _message =
            'Too deep into ${section.label}. Brake earlier and clip the apex.';
      } else if (section.drsAllowed && _drsFrames == 0) {
        _message =
            'DRS zone open. Straighten the car and deploy for top speed.';
      } else if (lineError > 0.24) {
        _message = 'You are off the racing line. Unwind the steering.';
      } else {
        _message = 'Good lap. Push toward ${_nextSection(section).label}.';
      }
    });
  }

  _QualiSection _nextSection(_QualiSection current) {
    final index = _sections.indexOf(current);
    return _sections[(index + 1) % _sections.length];
  }

  Future<void> _finishLap({required bool won, required String reason}) async {
    _timer?.cancel();
    _lapClock.stop();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _throttleHeld = false;
      _brakeHeld = false;
      _leftHeld = false;
      _rightHeld = false;
      _drsFrames = 0;
      final lap = _formatDuration(_lapClock.elapsed);
      final delta = ((_lapClock.elapsedMilliseconds - _targetTimeMs) / 1000)
          .toStringAsFixed(2);
      _message = won
          ? '$reason Lap $lap.'
          : '$reason Lap $lap • Delta +$delta s.';
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundredths = ((duration.inMilliseconds % 1000) / 10)
        .floor()
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$hundredths';
  }

  String _formatSector(int? sectorMs, int baselineMs) {
    if (sectorMs == null) return '--.--';
    final delta = (sectorMs - baselineMs) / 1000;
    return delta <= 0
        ? (sectorMs / 1000).toStringAsFixed(2)
        : '${(sectorMs / 1000).toStringAsFixed(2)} (+${delta.toStringAsFixed(2)})';
  }

  void _deployDrs() {
    if (!_running) return;
    if (!_section.drsAllowed ||
        _section.curve.abs() > 0.12 ||
        _offset.abs() > 0.22) {
      setState(() {
        _message =
            'DRS not safe here. Straighten the car on the main straight.';
      });
      return;
    }
    setState(() {
      _drsFrames = 15;
      _message = 'DRS open. Car is gaining speed down the straight.';
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xff06b6d4), Color(0xff8b5cf6)];
    return GameScaffold(
      title: 'Qualifying Lap',
      subtitle:
          'Drive one full push lap, hit the sectors cleanly, and chase a front-row time.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Sector',
            leftValue: 'S$_currentSector',
            rightLabel: 'Speed',
            rightValue: '${_speed.round()} km/h',
            footer:
                'Grip ${_grip.round()}% • Tires ${_tireTemp.round()}C • Ghost ${_gapMeters >= 0 ? '+' : ''}$_gapMeters m',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compact = width < 360;
                final laneCarX = width / 2 + (_offset * width * 0.22);
                final ghostGap = ((_ghostDistance - _distance) * 0.08).clamp(
                  -120.0,
                  130.0,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: compact ? 230 : 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xff0f172a), Color(0xff020617)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: CustomPaint(
                                  painter: _QualifyingRoadPainter(
                                    laneOffset: _section.curve * 34,
                                    drsActive: _drsFrames > 0,
                                    drsAllowed: _section.drsAllowed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 18,
                            right: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                _formatDuration(_lapClock.elapsed),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 26,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                _section.label,
                                style: const TextStyle(
                                  color: Color(0xffe2e8f0),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 78 + ghostGap,
                            left: width / 2 - 17,
                            child: const Opacity(
                              opacity: 0.72,
                              child: _FormulaCar(
                                color: Color(0xff38bdf8),
                                glow: Color(0xff60a5fa),
                                scale: 0.82,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 34,
                            left: laneCarX - 26,
                            child: Transform.rotate(
                              angle: (_offset + (_section.curve * 0.35)) * 0.32,
                              child: _FormulaCar(
                                color: const Color(0xff8b5cf6),
                                glow: _drsFrames > 0
                                    ? const Color(0xff06b6d4)
                                    : const Color(0xffc084fc),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SectorChip(
                            label: 'S1',
                            value: _formatSector(_sector1Ms, 25500),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SectorChip(
                            label: 'S2',
                            value: _formatSector(
                              _sector2Ms == null || _sector1Ms == null
                                  ? null
                                  : _sector2Ms! - _sector1Ms!,
                              25800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SectorChip(label: 'Target', value: '1:18.50'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _HoldControl(
                            icon: Icons.keyboard_double_arrow_left_rounded,
                            label: 'Left',
                            active: _leftHeld,
                            onChanged: (value) =>
                                setState(() => _leftHeld = value),
                          ),
                        ),
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _HoldControl(
                            icon: Icons.speed_rounded,
                            label: 'Throttle',
                            active: _throttleHeld,
                            accent: const Color(0xff22c55e),
                            onChanged: (value) =>
                                setState(() => _throttleHeld = value),
                          ),
                        ),
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _HoldControl(
                            icon: Icons.stop_circle_outlined,
                            label: 'Brake',
                            active: _brakeHeld,
                            accent: const Color(0xffef4444),
                            onChanged: (value) =>
                                setState(() => _brakeHeld = value),
                          ),
                        ),
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _HoldControl(
                            icon: Icons.keyboard_double_arrow_right_rounded,
                            label: 'Right',
                            active: _rightHeld,
                            onChanged: (value) =>
                                setState(() => _rightHeld = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _running ? _deployDrs : null,
                            icon: const Icon(Icons.air_rounded),
                            label: Text(
                              _section.drsAllowed ? 'Deploy DRS' : 'DRS Closed',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _running ? null : _startLap,
                            child: Text(
                              _finished ? 'Push again' : 'Start qualifying',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QualiSection {
  const _QualiSection({
    required this.label,
    required this.start,
    required this.end,
    required this.targetSpeed,
    required this.curve,
    required this.drsAllowed,
  });

  final String label;
  final double start;
  final double end;
  final int targetSpeed;
  final double curve;
  final bool drsAllowed;
}

class _SectorChip extends StatelessWidget {
  const _SectorChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff94a3b8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldControl extends StatelessWidget {
  const _HoldControl({
    required this.icon,
    required this.label,
    required this.active,
    required this.onChanged,
    this.accent = const Color(0xff38bdf8),
  });

  final IconData icon;
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: accent.withValues(alpha: active ? 0.28 : 0.14),
          border: Border.all(
            color: accent.withValues(alpha: active ? 0.72 : 0.32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaCar extends StatelessWidget {
  const _FormulaCar({required this.color, required this.glow, this.scale = 1});

  final Color color;
  final Color glow;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 52,
        height: 72,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.34),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 18,
              right: 18,
              top: 4,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.24), color],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 5,
              right: 5,
              top: 24,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 10,
              width: 10,
              height: 18,
              child: _wheel(),
            ),
            Positioned(
              right: 4,
              top: 10,
              width: 10,
              height: 18,
              child: _wheel(),
            ),
            Positioned(
              left: 4,
              bottom: 10,
              width: 10,
              height: 18,
              child: _wheel(),
            ),
            Positioned(
              right: 4,
              bottom: 10,
              width: 10,
              height: 18,
              child: _wheel(),
            ),
            Positioned(
              left: 21,
              right: 21,
              top: 12,
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xffdbeafe).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff020617),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _QualifyingRoadPainter extends CustomPainter {
  const _QualifyingRoadPainter({
    required this.laneOffset,
    required this.drsAllowed,
    required this.drsActive,
  });

  final double laneOffset;
  final bool drsAllowed;
  final bool drsActive;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff1f2937), Color(0xff020617)],
      ).createShader(Offset.zero & size);
    final edgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          drsActive
              ? const Color(0xff22d3ee).withValues(alpha: 0.30)
              : const Color(0xffef4444).withValues(alpha: 0.18),
          drsAllowed
              ? const Color(0xff8b5cf6).withValues(alpha: 0.30)
              : const Color(0xfff97316).withValues(alpha: 0.24),
        ],
      ).createShader(Offset.zero & size);
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = 3;

    canvas.drawRect(Offset.zero & size, roadPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 12, size.height), edgePaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 12, 0, 12, size.height),
      edgePaint,
    );

    final center = size.width / 2 + laneOffset;
    for (double y = -44; y < size.height + 44; y += 44) {
      final taper = (y / size.height) * laneOffset;
      canvas.drawLine(
        Offset(center - 54 + taper, y),
        Offset(center - 54 + taper, y + 22),
        lanePaint,
      );
      canvas.drawLine(
        Offset(center + 54 + taper, y),
        Offset(center + 54 + taper, y + 22),
        lanePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QualifyingRoadPainter oldDelegate) {
    return oldDelegate.laneOffset != laneOffset ||
        oldDelegate.drsAllowed != drsAllowed ||
        oldDelegate.drsActive != drsActive;
  }
}

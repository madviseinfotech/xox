import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class RangePickerScreen extends StatefulWidget {
  const RangePickerScreen({super.key});

  @override
  State<RangePickerScreen> createState() => _RangePickerScreenState();
}

class _RangePickerScreenState extends State<RangePickerScreen> {
  final Random _random = Random();
  final TextEditingController _controller = TextEditingController(text: '10');

  int _latestPick = 0;
  int _lastMax = 10;
  int _largestRange = 0;
  String _message =
      'Pass a max value and get a random pick from 1 to that value.';
  bool _isPicking = false;
  Timer? _pickTimer;

  @override
  void initState() {
    super.initState();
    _loadLargestRange();
  }

  @override
  void dispose() {
    _pickTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLargestRange() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _largestRange = snapshot.rangePickerLargestRange;
    });
  }

  Future<void> _pickNumber() async {
    if (_isPicking) return;
    final maxValue = int.tryParse(_controller.text.trim());
    if (maxValue == null || maxValue < 1) {
      setState(() {
        _message = 'Enter a positive number like 10 or 100.';
      });
      return;
    }

    final result = _random.nextInt(maxValue) + 1;
    setState(() {
      _lastMax = maxValue;
      _isPicking = true;
      _message = 'Picking a number from 1 to $maxValue...';
      if (maxValue > _largestRange) {
        _largestRange = maxValue;
      }
    });

    var ticks = 0;
    final completer = Completer<void>();
    _pickTimer?.cancel();
    _pickTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      ticks += 1;
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }
      setState(() {
        _latestPick = _random.nextInt(maxValue) + 1;
      });
      if (ticks >= 14) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
    if (!mounted) return;
    setState(() {
      _latestPick = result;
      _isPicking = false;
      _message = 'Random pick from 1 to $maxValue is $result.';
    });

    await GameStatsStore.instance.recordRangePickerRange(maxValue);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Range Picker',
      subtitle:
          'Pass a value like 10 or 100 and let the app pick from 1 to that limit.',
      accent: const [Color(0xff14b8a6), Color(0xff06b6d4)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Last max',
            leftValue: _lastMax.toString(),
            rightLabel: 'Largest used',
            rightValue: _largestRange == 0 ? '--' : _largestRange.toString(),
            footer: _latestPick == 0
                ? 'No pick yet.'
                : 'Latest random number: $_latestPick',
          ),
          const SizedBox(height: 22),
          GamePanel(
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter a max value',
                    hintStyle: const TextStyle(color: Color(0xff94a3b8)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPicking ? null : _pickNumber,
                    child: Text(_isPicking ? 'Picking...' : 'Pick number'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff06b6d4)),
          const SizedBox(height: 18),
          if (_latestPick != 0)
            GamePanel(
              child: Column(
                children: [
                  Text(
                    'Latest pick',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      _latestPick == 0 && _isPicking
                          ? '?'
                          : _latestPick.toString(),
                      key: ValueKey(
                        _isPicking ? 'pick_$_latestPick' : _latestPick,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
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

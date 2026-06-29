import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class ShopCashierScreen extends StatefulWidget {
  const ShopCashierScreen({super.key});

  @override
  State<ShopCashierScreen> createState() => _ShopCashierScreenState();
}

class _ShopCashierScreenState extends State<ShopCashierScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<String> _customerNames = [
    'Aarav',
    'Diya',
    'Kabir',
    'Meera',
    'Riya',
    'Vivaan',
    'Ishaan',
    'Anaya',
  ];
  static const List<_StoreItem> _catalog = [
    _StoreItem('Bread', 35),
    _StoreItem('Milk', 40),
    _StoreItem('Juice', 55),
    _StoreItem('Rice', 80),
    _StoreItem('Soap', 30),
    _StoreItem('Biscuits', 25),
    _StoreItem('Noodles', 45),
    _StoreItem('Tea Pack', 60),
    _StoreItem('Oil Bottle', 95),
    _StoreItem('Egg Tray', 70),
    _StoreItem('Apple Pack', 50),
    _StoreItem('Chocolate', 20),
  ];
  static const List<int> _payments = [100, 150, 200, 250, 300, 500];

  late String _customerName;
  late List<_StoreItem> _basket;
  late int _subtotal;
  late int _payment;
  late int _correctChange;
  late List<int> _options;

  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  String _message = 'Count the total and return the correct change.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  bool get _gameOver => _lives == 0;

  void _startRound({bool resetGame = false}) {
    final customerName =
        _customerNames[_random.nextInt(_customerNames.length)];
    final catalog = [..._catalog]..shuffle(_random);
    final itemCount = 2 + _random.nextInt(3);
    final basket = catalog.take(itemCount).toList(growable: false);
    final subtotal = basket.fold<int>(0, (sum, item) => sum + item.price);
    final validPayments = _payments
        .where((payment) => payment > subtotal)
        .toList(growable: false);
    final payment = validPayments[_random.nextInt(validPayments.length)];
    final correctChange = payment - subtotal;
    final options = <int>{correctChange};

    while (options.length < 4) {
      final drift = (_random.nextInt(9) + 1) * 5;
      final signed = _random.nextBool() ? drift : -drift;
      final candidate = correctChange + signed;
      if (candidate > 0) {
        options.add(candidate);
      }
    }

    final optionList = options.toList()..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = _maxLives;
        _message = 'Count the total and return the correct change.';
      }
      _customerName = customerName;
      _basket = basket;
      _subtotal = subtotal;
      _payment = payment;
      _correctChange = correctChange;
      _options = optionList;
    });
  }

  Future<void> _pickChange(int amount) async {
    if (_gameOver) return;

    if (amount == _correctChange) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = 'Correct change. Next customer is ready.';
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
            'Wrong change. Correct return was Rs $_correctChange. Shift over.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong change. Correct return was Rs $_correctChange. Lives left: $nextLives.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff0ea5e9), Color(0xff14b8a6)];
    return GameScaffold(
      title: 'Shop Cashier',
      subtitle: 'Bill the basket, count the payment, and hand back the right change.',
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
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: $_customerName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in _basket) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      Text(
                        'Rs ${item.price}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xffcbd5e1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Total')),
                          Text('Rs $_subtotal'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: Text('Customer paid')),
                          Text('Rs $_payment'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose the correct change',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xffe2e8f0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _options
                      .map(
                        (option) => SizedBox(
                          width: 140,
                          child: ElevatedButton(
                            onPressed: _gameOver ? null : () => _pickChange(option),
                            child: Text('Rs $option'),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}

class _StoreItem {
  const _StoreItem(this.name, this.price);

  final String name;
  final int price;
}

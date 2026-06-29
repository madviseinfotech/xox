import 'package:flutter/material.dart';

import 'game_scaffold.dart';

class GameModeOption<T> {
  const GameModeOption({required this.value, required this.label});

  final T value;
  final String label;
}

class GameModeSelector<T> extends StatelessWidget {
  const GameModeSelector({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    required this.accentColor,
    this.dense = false,
  });

  final T selectedValue;
  final List<GameModeOption<T>> options;
  final ValueChanged<T> onChanged;
  final Color accentColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: EdgeInsets.all(dense ? 4 : 6),
      child: Row(
        children: options
            .map((option) {
              final selected = option.value == selectedValue;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: () => onChanged(option.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected
                          ? accentColor
                          : Colors.white.withValues(alpha: 0.06),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: dense ? 11 : 14),
                    ),
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: dense ? 13 : 15),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

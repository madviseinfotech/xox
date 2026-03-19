import 'package:shared_preferences/shared_preferences.dart';

class GameStatsSnapshot {
  const GameStatsSnapshot({
    required this.memoryBestMoves,
    required this.numberGuessBestAttempts,
    required this.rangePickerLargestRange,
    required this.headsOrTailsBestStreak,
    required this.rockPaperScissorsWins,
    required this.diceDuelWins,
    required this.higherLowerBestStreak,
    required this.quickTapBestScore,
    required this.snakeBestLength,
    required this.sudokuSolvedBoards,
    required this.cricketWins,
    required this.snakesAndLaddersWins,
    required this.balloonPopBestScore,
    required this.colorMatchBestScore,
    required this.totalMiniGamesPlayed,
  });

  final int memoryBestMoves;
  final int numberGuessBestAttempts;
  final int rangePickerLargestRange;
  final int headsOrTailsBestStreak;
  final int rockPaperScissorsWins;
  final int diceDuelWins;
  final int higherLowerBestStreak;
  final int quickTapBestScore;
  final int snakeBestLength;
  final int sudokuSolvedBoards;
  final int cricketWins;
  final int snakesAndLaddersWins;
  final int balloonPopBestScore;
  final int colorMatchBestScore;
  final int totalMiniGamesPlayed;
}

class GameStatsStore {
  GameStatsStore._();

  static final GameStatsStore instance = GameStatsStore._();

  static const _memoryBestMovesKey = 'stats_memory_best_moves';
  static const _numberGuessBestAttemptsKey = 'stats_number_guess_best_attempts';
  static const _rangePickerLargestRangeKey = 'stats_range_picker_largest_range';
  static const _headsOrTailsBestStreakKey = 'stats_heads_or_tails_best_streak';
  static const _rockPaperScissorsWinsKey = 'stats_rps_wins';
  static const _diceDuelWinsKey = 'stats_dice_wins';
  static const _higherLowerBestStreakKey = 'stats_higher_lower_best_streak';
  static const _quickTapBestScoreKey = 'stats_quick_tap_best_score';
  static const _snakeBestLengthKey = 'stats_snake_best_length';
  static const _sudokuSolvedBoardsKey = 'stats_sudoku_solved_boards';
  static const _cricketWinsKey = 'stats_cricket_wins';
  static const _snakesAndLaddersWinsKey = 'stats_snakes_and_ladders_wins';
  static const _balloonPopBestScoreKey = 'stats_balloon_pop_best_score';
  static const _colorMatchBestScoreKey = 'stats_color_match_best_score';
  static const _totalMiniGamesPlayedKey = 'stats_total_mini_games_played';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<GameStatsSnapshot> loadSnapshot() async {
    final prefs = await _prefs;
    return GameStatsSnapshot(
      memoryBestMoves: prefs.getInt(_memoryBestMovesKey) ?? 0,
      numberGuessBestAttempts: prefs.getInt(_numberGuessBestAttemptsKey) ?? 0,
      rangePickerLargestRange: prefs.getInt(_rangePickerLargestRangeKey) ?? 0,
      headsOrTailsBestStreak: prefs.getInt(_headsOrTailsBestStreakKey) ?? 0,
      rockPaperScissorsWins: prefs.getInt(_rockPaperScissorsWinsKey) ?? 0,
      diceDuelWins: prefs.getInt(_diceDuelWinsKey) ?? 0,
      higherLowerBestStreak: prefs.getInt(_higherLowerBestStreakKey) ?? 0,
      quickTapBestScore: prefs.getInt(_quickTapBestScoreKey) ?? 0,
      snakeBestLength: prefs.getInt(_snakeBestLengthKey) ?? 0,
      sudokuSolvedBoards: prefs.getInt(_sudokuSolvedBoardsKey) ?? 0,
      cricketWins: prefs.getInt(_cricketWinsKey) ?? 0,
      snakesAndLaddersWins: prefs.getInt(_snakesAndLaddersWinsKey) ?? 0,
      balloonPopBestScore: prefs.getInt(_balloonPopBestScoreKey) ?? 0,
      colorMatchBestScore: prefs.getInt(_colorMatchBestScoreKey) ?? 0,
      totalMiniGamesPlayed: prefs.getInt(_totalMiniGamesPlayedKey) ?? 0,
    );
  }

  Future<void> recordGameLaunch() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_totalMiniGamesPlayedKey) ?? 0;
    await prefs.setInt(_totalMiniGamesPlayedKey, current + 1);
  }

  Future<void> recordMemoryBest(int moves) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_memoryBestMovesKey) ?? 0;
    if (current == 0 || moves < current) {
      await prefs.setInt(_memoryBestMovesKey, moves);
    }
  }

  Future<void> recordNumberGuessBest(int attempts) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_numberGuessBestAttemptsKey) ?? 0;
    if (current == 0 || attempts < current) {
      await prefs.setInt(_numberGuessBestAttemptsKey, attempts);
    }
  }

  Future<void> recordRangePickerRange(int maxRange) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_rangePickerLargestRangeKey) ?? 0;
    if (maxRange > current) {
      await prefs.setInt(_rangePickerLargestRangeKey, maxRange);
    }
  }

  Future<void> recordHeadsOrTailsStreak(int streak) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_headsOrTailsBestStreakKey) ?? 0;
    if (streak > current) {
      await prefs.setInt(_headsOrTailsBestStreakKey, streak);
    }
  }

  Future<void> incrementRockPaperScissorsWins() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_rockPaperScissorsWinsKey) ?? 0;
    await prefs.setInt(_rockPaperScissorsWinsKey, current + 1);
  }

  Future<void> incrementDiceWins() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_diceDuelWinsKey) ?? 0;
    await prefs.setInt(_diceDuelWinsKey, current + 1);
  }

  Future<void> recordHigherLowerStreak(int streak) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_higherLowerBestStreakKey) ?? 0;
    if (streak > current) {
      await prefs.setInt(_higherLowerBestStreakKey, streak);
    }
  }

  Future<void> recordQuickTapBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_quickTapBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_quickTapBestScoreKey, score);
    }
  }

  Future<void> recordSnakeBestLength(int length) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_snakeBestLengthKey) ?? 0;
    if (length > current) {
      await prefs.setInt(_snakeBestLengthKey, length);
    }
  }

  Future<void> incrementSudokuSolvedBoards() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_sudokuSolvedBoardsKey) ?? 0;
    await prefs.setInt(_sudokuSolvedBoardsKey, current + 1);
  }

  Future<void> incrementCricketWins() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_cricketWinsKey) ?? 0;
    await prefs.setInt(_cricketWinsKey, current + 1);
  }

  Future<void> incrementSnakesAndLaddersWins() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_snakesAndLaddersWinsKey) ?? 0;
    await prefs.setInt(_snakesAndLaddersWinsKey, current + 1);
  }

  Future<void> recordBalloonPopBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_balloonPopBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_balloonPopBestScoreKey, score);
    }
  }

  Future<void> recordColorMatchBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_colorMatchBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_colorMatchBestScoreKey, score);
    }
  }
}

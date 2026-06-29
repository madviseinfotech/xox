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
    required this.ludoWins,
    required this.balloonPopBestScore,
    required this.colorMatchBestScore,
    required this.oddOneOutBestStreak,
    required this.lightGridBestLevel,
    required this.tapSequenceBestLevel,
    required this.turboTrafficBestScore,
    required this.bikeSprintBestDistance,
    required this.cycleDashBestDistance,
    required this.avatarRushBestScore,
    required this.nitroSprintBestTimeMs,
    required this.driftRunBestDistance,
    required this.parkingDashBestLevel,
    required this.overtakeRushBestScore,
    required this.brickBreakerBestScore,
    required this.candyMatchBestScore,
    required this.mathEquationLevel,
    required this.wordBlankLevel,
    required this.picturePuzzleLevel,
    required this.totalMiniGamesPlayed,
    required this.twenty48BestScore,
    required this.fuelRushBestLaps,
    required this.grandPrixRushBestLaps,
    required this.pokerBluffBestStreak,
    required this.turboOvertakeBestDistance,
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
  final int ludoWins;
  final int balloonPopBestScore;
  final int colorMatchBestScore;
  final int oddOneOutBestStreak;
  final int lightGridBestLevel;
  final int tapSequenceBestLevel;
  final int turboTrafficBestScore;
  final int bikeSprintBestDistance;
  final int cycleDashBestDistance;
  final int avatarRushBestScore;
  final int nitroSprintBestTimeMs;
  final int driftRunBestDistance;
  final int parkingDashBestLevel;
  final int overtakeRushBestScore;
  final int brickBreakerBestScore;
  final int candyMatchBestScore;
  final int mathEquationLevel;
  final int wordBlankLevel;
  final int picturePuzzleLevel;
  final int totalMiniGamesPlayed;
  final int twenty48BestScore;
  final int fuelRushBestLaps;
  final int grandPrixRushBestLaps;
  final int pokerBluffBestStreak;
  final int turboOvertakeBestDistance;
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
  static const _ludoWinsKey = 'stats_ludo_wins';
  static const _balloonPopBestScoreKey = 'stats_balloon_pop_best_score';
  static const _colorMatchBestScoreKey = 'stats_color_match_best_score';
  static const _oddOneOutBestStreakKey = 'stats_odd_one_out_best_streak';
  static const _lightGridBestLevelKey = 'stats_light_grid_best_level';
  static const _tapSequenceBestLevelKey = 'stats_tap_sequence_best_level';
  static const _turboTrafficBestScoreKey = 'stats_turbo_traffic_best_score';
  static const _bikeSprintBestDistanceKey = 'stats_bike_sprint_best_distance';
  static const _cycleDashBestDistanceKey = 'stats_cycle_dash_best_distance';
  static const _avatarRushBestScoreKey = 'stats_avatar_rush_best_score';
  static const _nitroSprintBestTimeMsKey = 'stats_nitro_sprint_best_time_ms';
  static const _driftRunBestDistanceKey = 'stats_drift_run_best_distance';
  static const _parkingDashBestLevelKey = 'stats_parking_dash_best_level';
  static const _overtakeRushBestScoreKey = 'stats_overtake_rush_best_score';
  static const _brickBreakerBestScoreKey = 'stats_brick_breaker_best_score';
  static const _candyMatchBestScoreKey = 'stats_candy_match_best_score';
  static const _mathEquationLevelKey = 'stats_math_equation_level';
  static const _wordBlankLevelKey = 'stats_word_blank_level';
  static const _picturePuzzleLevelKey = 'stats_picture_puzzle_level';
  static const _totalMiniGamesPlayedKey = 'stats_total_mini_games_played';
  static const _twenty48BestScoreKey = 'stats_2048_best_score';
  static const _fuelRushBestLapsKey = 'stats_fuel_rush_best_laps';
  static const _grandPrixRushBestLapsKey = 'stats_grand_prix_rush_best_laps';
  static const _pokerBluffBestStreakKey = 'stats_poker_bluff_best_streak';
  static const _turboOvertakeBestDistanceKey = 'stats_turbo_overtake_best_distance';
  static const _favoriteGamesKey = 'stats_favorite_games';

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
      ludoWins: prefs.getInt(_ludoWinsKey) ?? 0,
      balloonPopBestScore: prefs.getInt(_balloonPopBestScoreKey) ?? 0,
      colorMatchBestScore: prefs.getInt(_colorMatchBestScoreKey) ?? 0,
      oddOneOutBestStreak: prefs.getInt(_oddOneOutBestStreakKey) ?? 0,
      lightGridBestLevel: prefs.getInt(_lightGridBestLevelKey) ?? 0,
      tapSequenceBestLevel: prefs.getInt(_tapSequenceBestLevelKey) ?? 0,
      turboTrafficBestScore: prefs.getInt(_turboTrafficBestScoreKey) ?? 0,
      bikeSprintBestDistance: prefs.getInt(_bikeSprintBestDistanceKey) ?? 0,
      cycleDashBestDistance: prefs.getInt(_cycleDashBestDistanceKey) ?? 0,
      avatarRushBestScore: prefs.getInt(_avatarRushBestScoreKey) ?? 0,
      nitroSprintBestTimeMs: prefs.getInt(_nitroSprintBestTimeMsKey) ?? 0,
      driftRunBestDistance: prefs.getInt(_driftRunBestDistanceKey) ?? 0,
      parkingDashBestLevel: prefs.getInt(_parkingDashBestLevelKey) ?? 0,
      overtakeRushBestScore: prefs.getInt(_overtakeRushBestScoreKey) ?? 0,
      brickBreakerBestScore: prefs.getInt(_brickBreakerBestScoreKey) ?? 0,
      candyMatchBestScore: prefs.getInt(_candyMatchBestScoreKey) ?? 0,
      mathEquationLevel: prefs.getInt(_mathEquationLevelKey) ?? 1,
      wordBlankLevel: prefs.getInt(_wordBlankLevelKey) ?? 1,
      picturePuzzleLevel: prefs.getInt(_picturePuzzleLevelKey) ?? 1,
      totalMiniGamesPlayed: prefs.getInt(_totalMiniGamesPlayedKey) ?? 0,
      twenty48BestScore: prefs.getInt(_twenty48BestScoreKey) ?? 0,
      fuelRushBestLaps: prefs.getInt(_fuelRushBestLapsKey) ?? 0,
      grandPrixRushBestLaps: prefs.getInt(_grandPrixRushBestLapsKey) ?? 0,
      pokerBluffBestStreak: prefs.getInt(_pokerBluffBestStreakKey) ?? 0,
      turboOvertakeBestDistance: prefs.getInt(_turboOvertakeBestDistanceKey) ?? 0,
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

  Future<void> incrementLudoWins() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_ludoWinsKey) ?? 0;
    await prefs.setInt(_ludoWinsKey, current + 1);
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

  Future<void> recordOddOneOutBestStreak(int streak) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_oddOneOutBestStreakKey) ?? 0;
    if (streak > current) {
      await prefs.setInt(_oddOneOutBestStreakKey, streak);
    }
  }

  Future<void> recordLightGridBestLevel(int level) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_lightGridBestLevelKey) ?? 0;
    if (level > current) {
      await prefs.setInt(_lightGridBestLevelKey, level);
    }
  }

  Future<void> recordTapSequenceBestLevel(int level) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_tapSequenceBestLevelKey) ?? 0;
    if (level > current) {
      await prefs.setInt(_tapSequenceBestLevelKey, level);
    }
  }

  Future<void> recordTurboTrafficBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_turboTrafficBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_turboTrafficBestScoreKey, score);
    }
  }

  Future<void> recordBikeSprintBestDistance(int distance) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_bikeSprintBestDistanceKey) ?? 0;
    if (distance > current) {
      await prefs.setInt(_bikeSprintBestDistanceKey, distance);
    }
  }

  Future<void> recordCycleDashBestDistance(int distance) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_cycleDashBestDistanceKey) ?? 0;
    if (distance > current) {
      await prefs.setInt(_cycleDashBestDistanceKey, distance);
    }
  }

  Future<void> recordAvatarRushBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_avatarRushBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_avatarRushBestScoreKey, score);
    }
  }

  Future<void> recordNitroSprintBestTime(int timeMs) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_nitroSprintBestTimeMsKey) ?? 0;
    if (current == 0 || timeMs < current) {
      await prefs.setInt(_nitroSprintBestTimeMsKey, timeMs);
    }
  }

  Future<void> recordDriftRunBestDistance(int distance) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_driftRunBestDistanceKey) ?? 0;
    if (distance > current) {
      await prefs.setInt(_driftRunBestDistanceKey, distance);
    }
  }

  Future<void> recordParkingDashBestLevel(int level) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_parkingDashBestLevelKey) ?? 0;
    if (level > current) {
      await prefs.setInt(_parkingDashBestLevelKey, level);
    }
  }

  Future<void> recordOvertakeRushBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_overtakeRushBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_overtakeRushBestScoreKey, score);
    }
  }

  Future<void> recordBrickBreakerBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_brickBreakerBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_brickBreakerBestScoreKey, score);
    }
  }

  Future<void> recordCandyMatchBestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_candyMatchBestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_candyMatchBestScoreKey, score);
    }
  }

  Future<void> recordMathEquationLevel(int level) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_mathEquationLevelKey) ?? 1;
    if (level > current || level == 1) {
      await prefs.setInt(_mathEquationLevelKey, level);
    }
  }

  Future<void> recordWordBlankLevel(int level) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_wordBlankLevelKey) ?? 1;
    if (level > current || level == 1) {
      await prefs.setInt(_wordBlankLevelKey, level);
    }
  }

  Future<void> recordPicturePuzzleLevel(int level) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_picturePuzzleLevelKey) ?? 1;
    if (level > current || level == 1) {
      await prefs.setInt(_picturePuzzleLevelKey, level);
    }
  }

  Future<Set<String>> loadFavoriteGames() async {
    final prefs = await _prefs;
    return (prefs.getStringList(_favoriteGamesKey) ?? const <String>[]).toSet();
  }

  Future<void> recordTurboOvertakeBestDistance(int distance) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_turboOvertakeBestDistanceKey) ?? 0;
    if (distance > current) {
      await prefs.setInt(_turboOvertakeBestDistanceKey, distance);
    }
  }

  Future<void> recordPokerBluffBestStreak(int streak) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_pokerBluffBestStreakKey) ?? 0;
    if (streak > current) {
      await prefs.setInt(_pokerBluffBestStreakKey, streak);
    }
  }

  Future<void> recordGrandPrixRushBestLaps(int laps) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_grandPrixRushBestLapsKey) ?? 0;
    if (laps > current) {
      await prefs.setInt(_grandPrixRushBestLapsKey, laps);
    }
  }

  Future<void> recordFuelRushBestLaps(int laps) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_fuelRushBestLapsKey) ?? 0;
    if (laps > current) {
      await prefs.setInt(_fuelRushBestLapsKey, laps);
    }
  }

  Future<void> recordTwenty48BestScore(int score) async {
    final prefs = await _prefs;
    final current = prefs.getInt(_twenty48BestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_twenty48BestScoreKey, score);
    }
  }

  Future<void> toggleFavoriteGame(String title) async {
    final prefs = await _prefs;
    final favorites =
        (prefs.getStringList(_favoriteGamesKey) ?? const <String>[]).toSet();
    if (favorites.contains(title)) {
      favorites.remove(title);
    } else {
      favorites.add(title);
    }
    await prefs.setStringList(
      _favoriteGamesKey,
      favorites.toList(growable: false),
    );
  }
}

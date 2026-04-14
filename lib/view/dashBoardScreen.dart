// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xox_madvise/services/daily_notification_service.dart';
import 'package:xox_madvise/services/game_ad_service.dart';
import 'package:xox_madvise/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xox_madvise/utils/utility.dart';
import 'package:xox_madvise/view/choose_player_screen.dart';
import 'package:xox_madvise/view/games/dice_duel_screen.dart';
import 'package:xox_madvise/view/games/cricket_chase_screen.dart';
import 'package:xox_madvise/view/games/cup_shuffle_screen.dart';
import 'package:xox_madvise/view/games/drift_run_screen.dart';
import 'package:xox_madvise/view/games/game_stats_store.dart';
import 'package:xox_madvise/view/games/balloon_pop_screen.dart';
import 'package:xox_madvise/view/games/airport_control_screen.dart';
import 'package:xox_madvise/view/games/asteroid_shield_screen.dart';
import 'package:xox_madvise/view/games/apex_picker_screen.dart';
import 'package:xox_madvise/view/games/beat_burst_screen.dart';
import 'package:xox_madvise/view/games/bomb_diffuser_screen.dart';
import 'package:xox_madvise/view/games/brick_breaker_screen.dart';
import 'package:xox_madvise/view/games/balance_beam_screen.dart';
import 'package:xox_madvise/view/games/candy_match_screen.dart';
import 'package:xox_madvise/view/games/card_count_screen.dart';
import 'package:xox_madvise/view/games/card_games_pack.dart';
import 'package:xox_madvise/view/games/car_wash_sort_screen.dart';
import 'package:xox_madvise/view/games/car_racing_bonus_screens.dart';
import 'package:xox_madvise/view/games/chess_screen.dart';
import 'package:xox_madvise/view/games/circuit_racer_screen.dart';
import 'package:xox_madvise/view/games/color_match_screen.dart';
import 'package:xox_madvise/view/games/heads_or_tails_screen.dart';
import 'package:xox_madvise/view/games/higher_lower_screen.dart';
import 'package:xox_madvise/view/games/flash_count_screen.dart';
import 'package:xox_madvise/view/games/fuel_grade_pick_screen.dart';
import 'package:xox_madvise/view/games/garage_sort_screen.dart';
import 'package:xox_madvise/view/games/memory_match_screen.dart';
import 'package:xox_madvise/view/games/mini_maze_screen.dart';
import 'package:xox_madvise/view/games/math_equation_screen.dart';
import 'package:xox_madvise/view/games/mole_smash_screen.dart';
import 'package:xox_madvise/view/games/mountain_drive_screen.dart';
import 'package:xox_madvise/view/games/number_guess_screen.dart';
import 'package:xox_madvise/view/games/number_chain_screen.dart';
import 'package:xox_madvise/view/games/odd_one_out_screen.dart';
import 'package:xox_madvise/view/games/overtake_rush_screen.dart';
import 'package:xox_madvise/view/games/pair_finder_screen.dart';
import 'package:xox_madvise/view/games/parking_dash_screen.dart';
import 'package:xox_madvise/view/games/penalty_kick_screen.dart';
import 'package:xox_madvise/view/games/picture_puzzle_screen.dart';
import 'package:xox_madvise/view/games/ludo_screen.dart';
import 'package:xox_madvise/view/games/light_grid_screen.dart';
import 'package:xox_madvise/view/games/laser_loop_screen.dart';
import 'package:xox_madvise/view/games/quick_tap_screen.dart';
import 'package:xox_madvise/view/games/range_picker_screen.dart';
import 'package:xox_madvise/view/games/rock_paper_scissors_screen.dart';
import 'package:xox_madvise/view/games/racing_games_pack.dart';
import 'package:xox_madvise/view/games/safe_cracker_screen.dart';
import 'package:xox_madvise/view/games/snake_screen.dart';
import 'package:xox_madvise/view/games/snakes_and_ladders_screen.dart';
import 'package:xox_madvise/view/games/sonar_sweep_screen.dart';
import 'package:xox_madvise/view/games/clock_match_screen.dart';
import 'package:xox_madvise/view/games/pit_lane_planner_screen.dart';
import 'package:xox_madvise/view/games/speed_trap_screen.dart';
import 'package:xox_madvise/view/games/suit_streak_screen.dart';
import 'package:xox_madvise/view/games/shop_cashier_screen.dart';
import 'package:xox_madvise/view/games/sudoku_screen.dart';
import 'package:xox_madvise/view/games/symbol_memory_screen.dart';
import 'package:xox_madvise/view/games/shape_path_screen.dart';
import 'package:xox_madvise/view/games/tap_sequence_screen.dart';
import 'package:xox_madvise/view/games/target_hunt_screen.dart';
import 'package:xox_madvise/view/games/direction_dash_screen.dart';
import 'package:xox_madvise/view/games/desert_rally_screen.dart';
import 'package:xox_madvise/view/games/dashboard_doctor_screen.dart';
import 'package:xox_madvise/view/games/color_sweep_screen.dart';
import 'package:xox_madvise/view/games/treasure_tap_screen.dart';
import 'package:xox_madvise/view/games/lane_switch_screen.dart';
import 'package:xox_madvise/view/games/quick_sort_screen.dart';
import 'package:xox_madvise/view/games/qualifying_lap_screen.dart';
import 'package:xox_madvise/view/games/road_sign_match_screen.dart';
import 'package:xox_madvise/view/games/twenty48_screen.dart';
import 'package:xox_madvise/view/games/traffic_light_tap_screen.dart';
import 'package:xox_madvise/view/games/fuel_rush_screen.dart';
import 'package:xox_madvise/view/games/grand_prix_rush_screen.dart';
import 'package:xox_madvise/view/games/drag_duel_screen.dart';
import 'package:xox_madvise/view/games/poker_bluff_screen.dart';
import 'package:xox_madvise/view/games/turbo_overtake_screen.dart';
import 'package:xox_madvise/view/games/rhyme_time_screen.dart';
import 'package:xox_madvise/view/games/word_blank_screen.dart';
import 'package:xox_madvise/view/games/learning_games_pack.dart';
import 'package:xox_madvise/view/games/match_tactics_screen.dart';
import 'package:xox_madvise/view/games/nitro_sprint_screen.dart';
import 'package:xox_madvise/view/retention_prompts.dart';

import 'ad_helper.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  AudioPlayer? _musicPlayer;
  static const List<String> _categories = [
    'All',
    'Favorites',
    'Kids',
    'Learning',
    'Car',
    '2 Player',
    'Puzzle',
    'Cards',
    'Arcade',
    'Racing',
  ];

  BannerAd? _bannerAd;
  bool _isBannerReady = false;
  GameStatsSnapshot? _stats;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _musicEnabled = Utility.volume;
  Set<String> _favoriteTitles = const <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupDashboardMusic();
    _loadBanner();
    _loadStats();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppUpdate(context, showFeedback: false);
      Future<void>.delayed(const Duration(milliseconds: 900), () async {
        if (!mounted) return;
        await DailyNotificationService.registerAppLaunch();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    _musicPlayer?.dispose();
    _searchController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _musicEnabled) {
      _playDashboardMusic();
    }
  }

  bool _matchesCategory(_HubGame game, String category) {
    switch (category) {
      case 'Favorites':
        return _favoriteTitles.contains(game.title);
      case 'Kids':
        return game.badge == 'Kids' ||
            game.badge == 'Learning' ||
            game.title == 'Balloon Pop' ||
            game.title == 'Color Match';
      case 'Learning':
        return game.badge == 'Learning';
      case 'Car':
        return game.badge == 'Car';
      case '2 Player':
        return {
          'XOX Arena',
          'Rock Paper Scissors',
          'Dice Duel',
          'Cricket Chase',
          'Snakes & Ladders',
          'Ludo',
          'Drag Duel',
        }.contains(game.title);
      case 'Puzzle':
        return {
          'Memory Match',
          'Number Guess',
          'Sudoku Mini',
          'Higher or Lower',
          'Candy Match',
          'Chess',
          'Picture Puzzle',
          'Odd One Out',
          'Light Grid',
          'Tap Sequence',
          'Cup Shuffle',
          'Pair Finder',
          'Balance Beam',
          'Bomb Diffuser',
          'Shop Cashier',
          'Airport Control',
          '2048',
          'Sonar Sweep',
          'Laser Loop',
        }.contains(game.title);
      case 'Cards':
        return {
          'Higher or Lower',
          'Blackjack',
          'War Cards',
          'Card Count',
          'Suit Streak',
          'Poker Bluff',
        }.contains(game.title);
      case 'Arcade':
        return {
          'Quick Tap',
          'Beat Burst',
          'Snake',
          'Heads or Tails',
          'Range Picker',
          'Balloon Pop',
          'Brick Breaker',
          'Candy Match',
          'Turbo Traffic',
          'Nitro Sprint',
          'Drift Run',
          'Parking Dash',
          'Overtake Rush',
          'Highway Heat',
          'Police Escape',
          'Pit Stop Pro',
          'Checkpoint Dash',
          'Cone Slalom',
          'Slipstream Surge',
          'Race Strategist',
          'Qualifying Lap',
          'Mountain Drive',
          'Bike Sprint',
          'Cycle Dash',
          'Avatar Rush',
          'Penalty Kick',
          'Direction Dash',
          'Flash Count',
          'Target Hunt',
          'Treasure Tap',
          'Color Sweep',
          'Lane Switch',
          'Mini Maze',
          'Mole Smash',
          'Fuel Rush',
          'Desert Rally',
          'Asteroid Shield',
          'Traffic Light Tap',
        }.contains(game.title);
      case 'Racing':
        return game.badge == 'Racing';
      case 'All':
      default:
        return true;
    }
  }

  bool _matchesSearch(_HubGame game, String query) {
    if (query.isEmpty) return true;
    final value = query.toLowerCase();
    return game.title.toLowerCase().contains(value) ||
        game.subtitle.toLowerCase().contains(value) ||
        game.badge.toLowerCase().contains(value) ||
        game.spotlightLabel.toLowerCase().contains(value);
  }

  List<_HubGame> _games(GameStatsSnapshot stats) {
    final games = <_HubGame>[
      _HubGame(
        title: 'XOX Arena',
        subtitle: 'Classic tic tac toe with local multiplayer or AI.',
        badge: 'Featured',
        spotlightLabel: 'Featured',
        icon: Icons.grid_3x3_rounded,
        colors: const [Color(0xfff97316), Color(0xfffb7185)],
        imageAsset: 'assets/images/game_card_xox.png',
        statLine: 'Main game ready to play',
        buildPage: () => const ChoosePlayerScreen(),
      ),
      _HubGame(
        title: 'Rock Paper Scissors',
        subtitle: 'Fast duel against the computer with score tracking.',
        badge: 'Quick Play',
        spotlightLabel: 'Classic',
        icon: Icons.front_hand_rounded,
        colors: const [Color(0xff22c55e), Color(0xff14b8a6)],
        imageAsset: 'assets/images/game_card_rps.png',
        statLine: 'Total wins saved: ${stats.rockPaperScissorsWins}',
        buildPage: () => const RockPaperScissorsScreen(),
      ),
      _HubGame(
        title: 'Memory Match',
        subtitle: 'Flip cards, find pairs, and clear the board in fewer moves.',
        badge: 'Puzzle',
        spotlightLabel: 'Puzzle',
        icon: Icons.psychology_alt_rounded,
        colors: const [Color(0xff6366f1), Color(0xff8b5cf6)],
        imageAsset: 'assets/images/game_card_memory.png',
        statLine: stats.memoryBestMoves == 0
            ? 'No best score yet'
            : 'Best clear: ${stats.memoryBestMoves} moves',
        buildPage: () => const MemoryMatchScreen(),
      ),
      _HubGame(
        title: 'Math Equation',
        subtitle: 'Solve endless equations and keep climbing saved levels.',
        badge: 'Learning',
        spotlightLabel: 'Math',
        icon: Icons.calculate_rounded,
        colors: const [Color(0xffef4444), Color(0xfff97316)],
        artStyle: _GameArtStyle.mathEquation,
        statLine: 'Saved level: ${stats.mathEquationLevel}',
        buildPage: () => const MathEquationScreen(),
      ),
      _HubGame(
        title: 'Number Guess',
        subtitle: 'Read the hints and crack the secret number.',
        badge: 'Brain',
        spotlightLabel: 'Brain',
        icon: Icons.pin_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff3b82f6)],
        imageAsset: 'assets/images/game_card_number_guess.png',
        statLine: stats.numberGuessBestAttempts == 0
            ? 'No best run yet'
            : 'Best solve: ${stats.numberGuessBestAttempts} tries',
        buildPage: () => const NumberGuessScreen(),
      ),
      _HubGame(
        title: 'Bomb Diffuser',
        subtitle: 'Read the bomb clue, cut the right wire, and stay calm.',
        badge: 'Puzzle',
        spotlightLabel: 'Logic',
        icon: Icons.electrical_services_rounded,
        colors: const [Color(0xffef4444), Color(0xfff59e0b)],
        statLine: 'Fresh clue and wire set every round',
        buildPage: () => const BombDiffuserScreen(),
      ),
      _HubGame(
        title: 'Shop Cashier',
        subtitle: 'Bill the basket correctly and return the exact change.',
        badge: 'Puzzle',
        spotlightLabel: 'Shop',
        icon: Icons.point_of_sale_rounded,
        colors: const [Color(0xff0ea5e9), Color(0xff14b8a6)],
        statLine: 'Each customer brings a fresh basket and payment amount',
        buildPage: () => const ShopCashierScreen(),
      ),
      _HubGame(
        title: 'Dice Duel',
        subtitle: 'Roll the dice and race the CPU to the higher score.',
        badge: 'Luck',
        spotlightLabel: 'Luck',
        icon: Icons.casino_rounded,
        colors: const [Color(0xffa855f7), Color(0xffec4899)],
        imageAsset: 'assets/images/game_card_dice_duel.png',
        statLine: 'Total round wins saved: ${stats.diceDuelWins}',
        buildPage: () => const DiceDuelScreen(),
      ),
      _HubGame(
        title: 'Heads or Tails',
        subtitle: 'Call the coin flip and build a streak.',
        badge: 'Streak',
        spotlightLabel: 'Streak',
        icon: Icons.monetization_on_rounded,
        colors: const [Color(0xfff59e0b), Color(0xffef4444)],
        imageAsset: 'assets/images/game_card_heads_tails.png',
        statLine: 'Best streak: ${stats.headsOrTailsBestStreak}',
        buildPage: () => const HeadsOrTailsScreen(),
      ),
      _HubGame(
        title: 'Range Picker',
        subtitle: 'Pass 10, 100, or any max value and get a random pick.',
        badge: 'Utility Game',
        spotlightLabel: 'Utility',
        icon: Icons.auto_awesome_rounded,
        colors: const [Color(0xff14b8a6), Color(0xff06b6d4)],
        imageAsset: 'assets/images/game_card_range_picker.png',
        statLine: stats.rangePickerLargestRange == 0
            ? 'No range used yet'
            : 'Largest range used: ${stats.rangePickerLargestRange}',
        buildPage: () => const RangePickerScreen(),
      ),
      _HubGame(
        title: 'Higher or Lower',
        subtitle: 'Predict the next card and build a hot streak.',
        badge: 'Cards',
        spotlightLabel: 'New',
        icon: Icons.style_rounded,
        colors: const [Color(0xfff97316), Color(0xfffacc15)],
        artStyle: _GameArtStyle.higherLower,
        statLine: stats.higherLowerBestStreak == 0
            ? 'Best streak waiting'
            : 'Best streak: ${stats.higherLowerBestStreak}',
        buildPage: () => const HigherLowerScreen(),
      ),
      _HubGame(
        title: 'Blackjack',
        subtitle: 'Hit or stand and try to beat the dealer at 21.',
        badge: 'Cards',
        spotlightLabel: 'Casino',
        icon: Icons.style_rounded,
        colors: const [Color(0xff166534), Color(0xff14532d)],
        artStyle: _GameArtStyle.blackjack,
        statLine: 'Classic 21 card game',
        buildPage: () => const BlackjackScreen(),
      ),
      _HubGame(
        title: 'War Cards',
        subtitle: 'Flip one card each and win with the higher card.',
        badge: 'Cards',
        spotlightLabel: 'Battle',
        icon: Icons.auto_awesome_rounded,
        colors: const [Color(0xfff97316), Color(0xffef4444)],
        artStyle: _GameArtStyle.warCards,
        statLine: 'Fast head-to-head card game',
        buildPage: () => const WarCardsScreen(),
      ),
      _HubGame(
        title: 'Card Count',
        subtitle: 'Read the cards, add the values, and choose the right total.',
        badge: 'Cards',
        spotlightLabel: 'Count',
        icon: Icons.style_rounded,
        colors: const [Color(0xff166534), Color(0xff14532d)],
        statLine: 'More cards appear as rounds increase',
        buildPage: () => const CardCountScreen(),
      ),
      _HubGame(
        title: 'Garage Sort',
        subtitle:
            'Read each vehicle profile and park it in the right service bay.',
        badge: 'Car',
        spotlightLabel: 'Garage',
        icon: Icons.garage_rounded,
        colors: const [Color(0xff0ea5e9), Color(0xff22c55e)],
        statLine: 'Offline car sorting with quick rule-based rounds',
        buildPage: () => const GarageSortScreen(),
      ),
      _HubGame(
        title: 'Dashboard Doctor',
        subtitle:
            'Read the warning, pick the right repair, and keep the cars moving.',
        badge: 'Car',
        spotlightLabel: 'Repair',
        icon: Icons.car_repair_rounded,
        colors: const [Color(0xff0ea5e9), Color(0xff22c55e)],
        statLine: 'Car care decision game with fast garage rounds',
        buildPage: () => const DashboardDoctorScreen(),
      ),
      _HubGame(
        title: 'Car Wash Sort',
        subtitle: 'Pick the right wash lane based on each car condition.',
        badge: 'Car',
        spotlightLabel: 'Wash',
        icon: Icons.local_car_wash_rounded,
        colors: const [Color(0xff38bdf8), Color(0xff14b8a6)],
        statLine: 'Car wash sorting game with quick read-and-pick rounds',
        buildPage: () => const CarWashSortScreen(),
      ),
      _HubGame(
        title: 'Fuel Grade Pick',
        subtitle: 'Choose the correct fuel type for each car profile.',
        badge: 'Car',
        spotlightLabel: 'Fuel',
        icon: Icons.local_gas_station_rounded,
        colors: const [Color(0xfff59e0b), Color(0xffef4444)],
        statLine: 'Fuel selection game with simple garage-style rounds',
        buildPage: () => const FuelGradePickScreen(),
      ),
      _HubGame(
        title: 'Traffic Light Tap',
        subtitle: 'Wait for green, then react fast without jumping the start.',
        badge: 'Arcade',
        spotlightLabel: 'Reflex',
        icon: Icons.traffic_rounded,
        colors: const [Color(0xfff97316), Color(0xff22c55e)],
        statLine: 'Reaction-timing game built around clean race starts',
        buildPage: () => const TrafficLightTapScreen(),
      ),
      _HubGame(
        title: 'Suit Streak',
        subtitle:
            'Count the spread fast and pick the suit with the highest total.',
        badge: 'Cards',
        spotlightLabel: 'Suits',
        icon: Icons.style_rounded,
        colors: const [Color(0xff166534), Color(0xff14532d)],
        statLine: 'Offline card counting with quick read-and-pick rounds',
        buildPage: () => const SuitStreakScreen(),
      ),
      _HubGame(
        title: 'Quick Tap',
        subtitle: 'A short reflex sprint to see how many taps you can land.',
        badge: 'Reflex',
        spotlightLabel: 'Trending',
        icon: Icons.touch_app_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff34d399)],
        artStyle: _GameArtStyle.quickTap,
        statLine: stats.quickTapBestScore == 0
            ? 'No record set yet'
            : 'Best round: ${stats.quickTapBestScore} taps',
        buildPage: () => const QuickTapScreen(),
      ),
      _HubGame(
        title: 'Beat Burst',
        subtitle: 'Tap the glowing beat pad before the rhythm timer runs out.',
        badge: 'Arcade',
        spotlightLabel: 'Beat',
        icon: Icons.music_note_rounded,
        colors: const [Color(0xfff97316), Color(0xffef4444)],
        statLine: 'Pure offline reflex play with rising tempo',
        buildPage: () => const BeatBurstScreen(),
      ),
      _HubGame(
        title: 'Mole Smash',
        subtitle: 'Tap the popping mole before it disappears and avoid misses.',
        badge: 'Arcade',
        spotlightLabel: 'Reflex',
        icon: Icons.cruelty_free_rounded,
        colors: const [Color(0xff84cc16), Color(0xff22c55e)],
        statLine: 'Mole speeds up as your score climbs',
        buildPage: () => const MoleSmashScreen(),
      ),
      _HubGame(
        title: 'Snake',
        subtitle: 'Guide the snake, eat food, and beat your best length.',
        badge: 'Arcade',
        spotlightLabel: 'New',
        icon: Icons.route_rounded,
        colors: const [Color(0xff22c55e), Color(0xff84cc16)],
        artStyle: _GameArtStyle.snake,
        statLine:
            'Best length: ${stats.snakeBestLength == 0 ? 3 : stats.snakeBestLength}',
        buildPage: () => const SnakeScreen(),
      ),
      _HubGame(
        title: 'Sudoku Mini',
        subtitle: 'A fast 4x4 number puzzle built for tap controls.',
        badge: 'Logic',
        spotlightLabel: 'Brain',
        icon: Icons.grid_view_rounded,
        colors: const [Color(0xff6366f1), Color(0xff2563eb)],
        artStyle: _GameArtStyle.sudoku,
        statLine: 'Solved boards: ${stats.sudokuSolvedBoards}',
        buildPage: () => const SudokuScreen(),
      ),
      _HubGame(
        title: 'Cricket Chase',
        subtitle: 'Bat first, defend the total, and win the hand-cricket duel.',
        badge: 'Sports',
        spotlightLabel: 'Sports',
        icon: Icons.sports_cricket_rounded,
        colors: const [Color(0xff0f766e), Color(0xff22c55e)],
        artStyle: _GameArtStyle.cricket,
        statLine: 'Matches won: ${stats.cricketWins}',
        buildPage: () => const CricketChaseScreen(),
      ),
      _HubGame(
        title: 'Penalty Kick',
        subtitle: 'Stop the moving aim and score away from the keeper glove.',
        badge: 'Arcade',
        spotlightLabel: 'Goal',
        icon: Icons.sports_soccer_rounded,
        colors: const [Color(0xff22c55e), Color(0xff0ea5e9)],
        statLine: 'Quick timing-based soccer challenge',
        buildPage: () => const PenaltyKickScreen(),
      ),
      _HubGame(
        title: 'Snakes & Ladders',
        subtitle: 'Full 100-square race with ladders, snakes, and local turns.',
        badge: 'Board Race',
        spotlightLabel: 'Board',
        icon: Icons.stairs_rounded,
        colors: const [Color(0xff7c3aed), Color(0xffec4899)],
        artStyle: _GameArtStyle.snakesLadders,
        statLine: 'Races won: ${stats.snakesAndLaddersWins}',
        buildPage: () => const SnakesAndLaddersScreen(),
      ),
      _HubGame(
        title: 'Ludo',
        subtitle:
            'Roll a 6 to enter, race your token home, and beat the rival.',
        badge: 'Board Race',
        spotlightLabel: 'Ludo',
        icon: Icons.blur_circular_rounded,
        colors: const [Color(0xffef4444), Color(0xff2563eb)],
        artStyle: _GameArtStyle.ludo,
        statLine: 'Ludo wins: ${stats.ludoWins}',
        buildPage: () => const LudoScreen(),
      ),
      _HubGame(
        title: 'Turbo Traffic',
        subtitle:
            'Dodge lane traffic and hold your nerve as the road speeds up.',
        badge: 'Racing',
        spotlightLabel: 'Drive',
        icon: Icons.directions_car_filled_rounded,
        colors: const [Color(0xfffb7185), Color(0xfff97316)],
        artStyle: _GameArtStyle.turboTraffic,
        statLine: stats.turboTrafficBestScore == 0
            ? 'No clean runs yet'
            : 'Best dodges: ${stats.turboTrafficBestScore}',
        buildPage: () => const TurboTrafficScreen(),
      ),
      _HubGame(
        title: 'Nitro Sprint',
        subtitle: 'Nail the launch, shift on time, and hit nitro to win.',
        badge: 'Racing',
        spotlightLabel: 'Drag',
        icon: Icons.flash_on_rounded,
        colors: const [Color(0xfff97316), Color(0xffef4444)],
        statLine: stats.nitroSprintBestTimeMs == 0
            ? 'Best finish waiting'
            : 'Best finish: ${(stats.nitroSprintBestTimeMs / 1000).toStringAsFixed(2)}s',
        buildPage: () => const NitroSprintScreen(),
      ),
      _HubGame(
        title: 'Drift Run',
        subtitle:
            'Slide between barrier gates and survive as the road speeds up.',
        badge: 'Racing',
        spotlightLabel: 'Drift',
        icon: Icons.turn_sharp_left_rounded,
        colors: const [Color(0xfff97316), Color(0xff0ea5e9)],
        statLine: stats.driftRunBestDistance == 0
            ? 'No clean run yet'
            : 'Best distance: ${stats.driftRunBestDistance} m',
        buildPage: () => const DriftRunScreen(),
      ),
      _HubGame(
        title: 'Parking Dash',
        subtitle: 'Slip into the highlighted parking bay before time runs out.',
        badge: 'Racing',
        spotlightLabel: 'Park',
        icon: Icons.local_parking_rounded,
        colors: const [Color(0xff22c55e), Color(0xff0ea5e9)],
        statLine: stats.parkingDashBestLevel == 0
            ? 'No bay cleared yet'
            : 'Best round: ${stats.parkingDashBestLevel}',
        buildPage: () => const ParkingDashScreen(),
      ),
      _HubGame(
        title: 'Circuit Racer',
        subtitle: 'Brake for corners, hold the line, and race a real circuit.',
        badge: 'Racing',
        spotlightLabel: 'Track',
        icon: Icons.sports_motorsports_rounded,
        colors: const [Color(0xffef4444), Color(0xfff97316)],
        statLine: 'Track sections demand proper braking and steering input',
        buildPage: () => const CircuitRacerScreen(),
      ),
      _HubGame(
        title: 'Qualifying Lap',
        subtitle:
            'Push one full hot lap with DRS timing, braking zones, and sector targets.',
        badge: 'Racing',
        spotlightLabel: 'Quali',
        icon: Icons.timer_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff8b5cf6)],
        statLine:
            'One-lap time attack built to feel like a real qualifying run',
        buildPage: () => const QualifyingLapScreen(),
      ),
      _HubGame(
        title: 'Mountain Drive',
        subtitle:
            'Race through green trees, mountain roads, and scenic bends with a more real-road feel.',
        badge: 'Racing',
        spotlightLabel: 'Scenic',
        icon: Icons.landscape_rounded,
        colors: const [Color(0xff22c55e), Color(0xff0ea5e9)],
        statLine:
            'Mountain scenery, roadside trees, and a proper hill-road race vibe',
        buildPage: () => const MountainDriveScreen(),
      ),
      _HubGame(
        title: 'Overtake Rush',
        subtitle:
            'Burst past traffic, manage engine heat, and hunt the finish.',
        badge: 'Racing',
        spotlightLabel: 'Overtake',
        icon: Icons.rocket_launch_rounded,
        colors: const [Color(0xffef4444), Color(0xfff59e0b)],
        statLine: stats.overtakeRushBestScore == 0
            ? 'Street run waiting'
            : 'Best passes: ${stats.overtakeRushBestScore}',
        buildPage: () => const OvertakeRushScreen(),
      ),
      _HubGame(
        title: 'Highway Heat',
        subtitle: 'Dodge traffic at speed and stack risky near-miss runs.',
        badge: 'Racing',
        spotlightLabel: 'Highway',
        icon: Icons.route_rounded,
        colors: const [Color(0xffef4444), Color(0xfff97316)],
        statLine: 'Offline highway dodging with rising speed pressure',
        buildPage: () => const HighwayHeatScreen(),
      ),
      _HubGame(
        title: 'Police Escape',
        subtitle:
            'Break the chase, dodge roadblocks, and lose the wanted level.',
        badge: 'Racing',
        spotlightLabel: 'Chase',
        icon: Icons.local_police_rounded,
        colors: const [Color(0xff2563eb), Color(0xff0ea5e9)],
        statLine: 'Pursuit-style driving challenge with roadblock pressure',
        buildPage: () => const PoliceEscapeScreen(),
      ),
      _HubGame(
        title: 'Pit Stop Pro',
        subtitle: 'Memorize the crew order and service the car under pressure.',
        badge: 'Racing',
        spotlightLabel: 'Pit',
        icon: Icons.build_circle_rounded,
        colors: const [Color(0xff22c55e), Color(0xff0ea5e9)],
        statLine: 'Race-team memory challenge built around pit stop calls',
        buildPage: () => const PitStopProScreen(),
      ),
      _HubGame(
        title: 'Checkpoint Dash',
        subtitle: 'Cross each speed gate inside the target racing window.',
        badge: 'Racing',
        spotlightLabel: 'Gate',
        icon: Icons.speed_rounded,
        colors: const [Color(0xfff59e0b), Color(0xffef4444)],
        statLine: 'Throttle-and-brake timing challenge across 5 checkpoints',
        buildPage: () => const CheckpointDashScreen(),
      ),
      _HubGame(
        title: 'Cone Slalom',
        subtitle:
            'Flick the car through cone walls and survive the fast sections.',
        badge: 'Racing',
        spotlightLabel: 'Slalom',
        icon: Icons.turn_right_rounded,
        colors: const [Color(0xfff59e0b), Color(0xfffb7185)],
        statLine: 'Precision lane-switch challenge inspired by training drills',
        buildPage: () => const ConeSlalomScreen(),
      ),
      _HubGame(
        title: 'Slipstream Surge',
        subtitle:
            'Draft behind the rival, pull out late, and time each overtake.',
        badge: 'Racing',
        spotlightLabel: 'Draft',
        icon: Icons.air_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff8b5cf6)],
        statLine: 'Tactical overtaking game built around slipstream timing',
        buildPage: () => const SlipstreamSurgeScreen(),
      ),
      _HubGame(
        title: 'Race Strategist',
        subtitle:
            'Manage pit wall decisions, tire wear, fuel, and weather lap by lap.',
        badge: 'Racing',
        spotlightLabel: 'Strategy',
        icon: Icons.support_agent_rounded,
        colors: const [Color(0xff14b8a6), Color(0xff0ea5e9)],
        statLine: 'A different kind of car-race game focused on race calls',
        buildPage: () => const RaceStrategistScreen(),
      ),
      _HubGame(
        title: 'Airport Control',
        subtitle: 'Give runway priority to the right flight under pressure.',
        badge: 'Puzzle',
        spotlightLabel: 'Tower',
        icon: Icons.local_airport_rounded,
        colors: const [Color(0xff1d4ed8), Color(0xff0ea5e9)],
        statLine: 'Fuel, landing status, and passengers change every round',
        buildPage: () => const AirportControlScreen(),
      ),
      _HubGame(
        title: 'Bike Sprint',
        subtitle: 'Hit the boost zone and chain perfect pedal bursts.',
        badge: 'Racing',
        spotlightLabel: 'Bike',
        icon: Icons.two_wheeler_rounded,
        colors: const [Color(0xff38bdf8), Color(0xff2563eb)],
        artStyle: _GameArtStyle.bikeSprint,
        statLine: stats.bikeSprintBestDistance == 0
            ? 'Sprint record waiting'
            : 'Best distance: ${stats.bikeSprintBestDistance} m',
        buildPage: () => const BikeSprintScreen(),
      ),
      _HubGame(
        title: 'Cycle Dash',
        subtitle:
            'Manage energy across checkpoints and save boosts for the finish.',
        badge: 'Racing',
        spotlightLabel: 'Cycle',
        icon: Icons.pedal_bike_rounded,
        colors: const [Color(0xff22c55e), Color(0xff84cc16)],
        artStyle: _GameArtStyle.cycleDash,
        statLine: stats.cycleDashBestDistance == 0
            ? 'No stage cleared yet'
            : 'Best stage: ${stats.cycleDashBestDistance} m',
        buildPage: () => const CycleDashScreen(),
      ),
      _HubGame(
        title: 'Avatar Rush',
        subtitle: 'Make the right move to keep your runner alive.',
        badge: 'Racing',
        spotlightLabel: 'Runner',
        icon: Icons.directions_run_rounded,
        colors: const [Color(0xff8b5cf6), Color(0xffec4899)],
        artStyle: _GameArtStyle.avatarRush,
        statLine: stats.avatarRushBestScore == 0
            ? 'No runner streak yet'
            : 'Best dodges: ${stats.avatarRushBestScore}',
        buildPage: () => const AvatarRushScreen(),
      ),
      _HubGame(
        title: 'Brick Breaker',
        subtitle: 'Bounce the ball, move the paddle, and clear every brick.',
        badge: 'Arcade',
        spotlightLabel: 'Classic',
        icon: Icons.sports_esports_rounded,
        colors: const [Color(0xff38bdf8), Color(0xff8b5cf6)],
        artStyle: _GameArtStyle.brickBreaker,
        statLine: stats.brickBreakerBestScore == 0
            ? 'No wall cleared yet'
            : 'Best score: ${stats.brickBreakerBestScore}',
        buildPage: () => const BrickBreakerScreen(),
      ),
      _HubGame(
        title: 'Candy Match',
        subtitle:
            'Drag candies into place, crush combos, and chase score goals.',
        badge: 'Puzzle',
        spotlightLabel: 'Sweet',
        icon: Icons.cake_rounded,
        colors: const [Color(0xfffb7185), Color(0xffa855f7)],
        artStyle: _GameArtStyle.candyMatch,
        statLine: stats.candyMatchBestScore == 0
            ? 'No sweet streak yet'
            : 'Best score: ${stats.candyMatchBestScore}',
        buildPage: () => const CandyMatchScreen(),
      ),
      _HubGame(
        title: 'Picture Puzzle',
        subtitle: 'Swap shuffled tiles to rebuild a fresh random picture.',
        badge: 'Puzzle',
        spotlightLabel: 'Touch',
        icon: Icons.grid_on_rounded,
        colors: const [Color(0xff22c55e), Color(0xff38bdf8)],
        artStyle: _GameArtStyle.picturePuzzle,
        statLine: 'Saved level: ${stats.picturePuzzleLevel}',
        buildPage: () => const PicturePuzzleScreen(),
      ),
      _HubGame(
        title: 'Chess',
        subtitle:
            'Play a full two-player chess board with real piece movement.',
        badge: 'Strategy',
        spotlightLabel: 'Board',
        icon: Icons.grid_4x4_rounded,
        colors: const [Color(0xffd4a373), Color(0xff7f5539)],
        artStyle: _GameArtStyle.chess,
        statLine: 'Local two-player classic',
        buildPage: () => const ChessScreen(),
      ),
      _HubGame(
        title: 'Balloon Pop',
        subtitle:
            'Pop bright balloons in a fast round made for little players.',
        badge: 'Kids',
        spotlightLabel: 'Fun',
        icon: Icons.celebration_rounded,
        colors: const [Color(0xfffb7185), Color(0xfff59e0b)],
        artStyle: _GameArtStyle.balloonPop,
        statLine: stats.balloonPopBestScore == 0
            ? 'No best score yet'
            : 'Best pops: ${stats.balloonPopBestScore}',
        buildPage: () => const BalloonPopScreen(),
      ),
      _HubGame(
        title: 'Color Match',
        subtitle:
            'Pick the matching color card in a simple kid-friendly round.',
        badge: 'Kids',
        spotlightLabel: 'Learn',
        icon: Icons.palette_rounded,
        colors: const [Color(0xff22c55e), Color(0xff38bdf8)],
        artStyle: _GameArtStyle.colorMatch,
        statLine: stats.colorMatchBestScore == 0
            ? 'No streak yet'
            : 'Best streak: ${stats.colorMatchBestScore}',
        buildPage: () => const ColorMatchScreen(),
      ),
      _HubGame(
        title: 'Odd One Out',
        subtitle: 'Spot the different tile before the board gets bigger.',
        badge: 'Puzzle',
        spotlightLabel: 'Focus',
        icon: Icons.visibility_rounded,
        colors: const [Color(0xfff59e0b), Color(0xffef4444)],
        statLine: stats.oddOneOutBestStreak == 0
            ? 'No streak yet'
            : 'Best streak: ${stats.oddOneOutBestStreak}',
        buildPage: () => const OddOneOutScreen(),
      ),
      _HubGame(
        title: 'Light Grid',
        subtitle: 'Tap tiles to switch every light off on the board.',
        badge: 'Puzzle',
        spotlightLabel: 'Logic',
        icon: Icons.lightbulb_rounded,
        colors: const [Color(0xff38bdf8), Color(0xff6366f1)],
        statLine: stats.lightGridBestLevel == 0
            ? 'No board solved yet'
            : 'Best level: ${stats.lightGridBestLevel}',
        buildPage: () => const LightGridScreen(),
      ),
      _HubGame(
        title: 'Tap Sequence',
        subtitle: 'Tap the numbers in order while each level adds more tiles.',
        badge: 'Puzzle',
        spotlightLabel: 'Speed',
        icon: Icons.filter_9_plus_rounded,
        colors: const [Color(0xff22c55e), Color(0xff0ea5e9)],
        statLine: stats.tapSequenceBestLevel == 0
            ? 'No level cleared yet'
            : 'Best level: ${stats.tapSequenceBestLevel}',
        buildPage: () => const TapSequenceScreen(),
      ),
      _HubGame(
        title: 'Alphabet Adventure',
        subtitle: 'Letters, sounds, and easy alphabet practice.',
        badge: 'Learning',
        spotlightLabel: 'ABC',
        icon: Icons.abc_rounded,
        colors: const [Color(0xff38bdf8), Color(0xff0ea5e9)],
        statLine: 'Letter practice game',
        buildPage: () => const AlphabetAdventureScreen(),
      ),
      _HubGame(
        title: 'Counting Fun',
        subtitle: 'Count groups and choose the right number.',
        badge: 'Learning',
        spotlightLabel: 'Count',
        icon: Icons.looks_5_rounded,
        colors: const [Color(0xfff59e0b), Color(0xfff97316)],
        statLine: 'Number sense for kids',
        buildPage: () => const CountingFunScreen(),
      ),
      _HubGame(
        title: 'Shape Match',
        subtitle: 'Learn circles, squares, triangles, and more.',
        badge: 'Learning',
        spotlightLabel: 'Shapes',
        icon: Icons.category_rounded,
        colors: const [Color(0xff8b5cf6), Color(0xff6366f1)],
        statLine: 'Shape recognition game',
        buildPage: () => const ShapeMatchScreen(),
      ),
      _HubGame(
        title: 'Animal Match',
        subtitle: 'Match easy animal clues and names.',
        badge: 'Learning',
        spotlightLabel: 'Animals',
        icon: Icons.pets_rounded,
        colors: const [Color(0xff22c55e), Color(0xff16a34a)],
        statLine: 'Animal learning fun',
        buildPage: () => const AnimalMatchScreen(),
      ),
      _HubGame(
        title: 'Math Sprint',
        subtitle: 'Quick sums and simple number puzzles.',
        badge: 'Learning',
        spotlightLabel: 'Math',
        icon: Icons.calculate_rounded,
        colors: const [Color(0xffef4444), Color(0xfff97316)],
        statLine: 'Brain game for numbers',
        buildPage: () => const MathSprintScreen(),
      ),
      _HubGame(
        title: 'Word Builder',
        subtitle: 'Choose missing letters to finish words.',
        badge: 'Learning',
        spotlightLabel: 'Words',
        icon: Icons.spellcheck_rounded,
        colors: const [Color(0xff14b8a6), Color(0xff06b6d4)],
        statLine: 'Build simple words',
        buildPage: () => const WordBuilderScreen(),
      ),
      _HubGame(
        title: 'Word Blank',
        subtitle:
            'Fill the blank, celebrate the word, and learn what it means.',
        badge: 'Learning',
        spotlightLabel: 'Words',
        icon: Icons.spellcheck_rounded,
        colors: const [Color(0xff14b8a6), Color(0xff06b6d4)],
        statLine: 'Saved level: ${stats.wordBlankLevel}',
        buildPage: () => const WordBlankScreen(),
      ),
      _HubGame(
        title: 'Road Sign Match',
        subtitle:
            'Match traffic signs with their meanings and learn road safety.',
        badge: 'Learning',
        spotlightLabel: 'Signs',
        icon: Icons.add_road_rounded,
        colors: const [Color(0xff0ea5e9), Color(0xff8b5cf6)],
        statLine: 'Learning game focused on simple road-sign meanings',
        buildPage: () => const RoadSignMatchScreen(),
      ),
      _HubGame(
        title: 'Pattern Play',
        subtitle: 'Find the next item in repeating patterns.',
        badge: 'Learning',
        spotlightLabel: 'Pattern',
        icon: Icons.repeat_rounded,
        colors: const [Color(0xfff97316), Color(0xfffb7185)],
        statLine: 'Brain pattern practice',
        buildPage: () => const PatternPlayScreen(),
      ),
      _HubGame(
        title: 'Opposite Day',
        subtitle: 'Pick the opposite word and learn meanings.',
        badge: 'Learning',
        spotlightLabel: 'Words',
        icon: Icons.compare_arrows_rounded,
        colors: const [Color(0xff6366f1), Color(0xff38bdf8)],
        statLine: 'Vocabulary builder',
        buildPage: () => const OppositeDayScreen(),
      ),
      _HubGame(
        title: 'Emoji Count',
        subtitle: 'Count emoji groups in playful rounds.',
        badge: 'Learning',
        spotlightLabel: 'Count',
        icon: Icons.tag_faces_rounded,
        colors: const [Color(0xffec4899), Color(0xfff59e0b)],
        statLine: 'Counting with emoji',
        buildPage: () => const EmojiCountScreen(),
      ),
      _HubGame(
        title: 'Sight Word Sprint',
        subtitle: 'Practice reading common sight words.',
        badge: 'Learning',
        spotlightLabel: 'Read',
        icon: Icons.menu_book_rounded,
        colors: const [Color(0xff22c55e), Color(0xff10b981)],
        statLine: 'Reading practice game',
        buildPage: () => const SightWordSprintScreen(),
      ),
      _HubGame(
        title: 'Clock Match',
        subtitle: 'Read the time clue and choose the matching digital clock.',
        badge: 'Learning',
        spotlightLabel: 'Time',
        icon: Icons.schedule_rounded,
        colors: const [Color(0xff8b5cf6), Color(0xff6366f1)],
        statLine: 'Offline time-reading practice for quick rounds',
        buildPage: () => const ClockMatchScreen(),
      ),
      _HubGame(
        title: 'Rhyme Time',
        subtitle: 'Pick the word that rhymes with the prompt word.',
        badge: 'Learning',
        spotlightLabel: 'Sound',
        icon: Icons.music_note_rounded,
        colors: const [Color(0xff14b8a6), Color(0xff06b6d4)],
        statLine: 'New rhyme words shuffle every round',
        buildPage: () => const RhymeTimeScreen(),
      ),
      _HubGame(
        title: 'Match Tactics',
        subtitle: 'Choose the smartest tactic for the live scoreline.',
        badge: 'Sports',
        spotlightLabel: 'Coach',
        icon: Icons.sports_soccer_rounded,
        colors: const [Color(0xff0f766e), Color(0xff22c55e)],
        statLine: 'Attack, balance, or defend based on the match state',
        buildPage: () => const MatchTacticsScreen(),
      ),
      _HubGame(
        title: 'Target Hunt',
        subtitle: 'Spot every matching number before you run out of lives.',
        badge: 'Arcade',
        spotlightLabel: 'Focus',
        icon: Icons.gps_fixed_rounded,
        colors: const [Color(0xfff97316), Color(0xffef4444)],
        statLine: 'Fresh target board every round',
        buildPage: () => const TargetHuntScreen(),
      ),
      _HubGame(
        title: 'Cup Shuffle',
        subtitle:
            'Track the hidden ball through quick shuffles and guess right.',
        badge: 'Puzzle',
        spotlightLabel: 'Focus',
        icon: Icons.sports_bar_rounded,
        colors: const [Color(0xff8b5cf6), Color(0xffec4899)],
        statLine: 'Shuffle count increases each round',
        buildPage: () => const CupShuffleScreen(),
      ),
      _HubGame(
        title: 'Treasure Tap',
        subtitle: 'Open mystery tiles, grab treasure, and avoid hidden bombs.',
        badge: 'Arcade',
        spotlightLabel: 'Lucky',
        icon: Icons.diamond_rounded,
        colors: const [Color(0xfff59e0b), Color(0xfff97316)],
        statLine: 'Mystery board changes every round',
        buildPage: () => const TreasureTapScreen(),
      ),
      _HubGame(
        title: 'Sonar Sweep',
        subtitle:
            'Probe a hidden signal, read the clues, and lock the target before it escapes.',
        badge: 'Puzzle',
        spotlightLabel: 'Sonar',
        icon: Icons.radar_rounded,
        colors: const [Color(0xff0ea5e9), Color(0xff14b8a6)],
        statLine: 'Deduction-based grid hunt with limited probes each round',
        buildPage: () => const SonarSweepScreen(),
      ),
      _HubGame(
        title: 'Safe Cracker',
        subtitle: 'Guess the hidden code with exact and misplaced digit hints.',
        badge: 'Puzzle',
        spotlightLabel: 'Code',
        icon: Icons.lock_open_rounded,
        colors: const [Color(0xff0ea5e9), Color(0xff2563eb)],
        statLine: 'Fresh code every round',
        buildPage: () => const SafeCrackerScreen(),
      ),
      _HubGame(
        title: 'Color Sweep',
        subtitle: 'Tap only the target color and avoid wasting your chances.',
        badge: 'Arcade',
        spotlightLabel: 'Color',
        icon: Icons.format_color_fill_rounded,
        colors: const [Color(0xff14b8a6), Color(0xff06b6d4)],
        statLine: 'Target color changes every round',
        buildPage: () => const ColorSweepScreen(),
      ),
      _HubGame(
        title: 'Symbol Memory',
        subtitle: 'Study the symbol pattern and tap back the same order.',
        badge: 'Puzzle',
        spotlightLabel: 'Memory',
        icon: Icons.psychology_rounded,
        colors: const [Color(0xff8b5cf6), Color(0xff6366f1)],
        statLine: 'Pattern grows as rounds increase',
        buildPage: () => const SymbolMemoryScreen(),
      ),
      _HubGame(
        title: 'Lane Switch',
        subtitle: 'Choose the safe lane in each row and keep moving forward.',
        badge: 'Arcade',
        spotlightLabel: 'Run',
        icon: Icons.swap_horiz_rounded,
        colors: const [Color(0xff22c55e), Color(0xff16a34a)],
        statLine: 'Safe lanes change every round',
        buildPage: () => const LaneSwitchScreen(),
      ),
      _HubGame(
        title: 'Number Chain',
        subtitle: 'Use the right step values to land exactly on the target.',
        badge: 'Puzzle',
        spotlightLabel: 'Math',
        icon: Icons.functions_rounded,
        colors: const [Color(0xfff97316), Color(0xfffb7185)],
        statLine: 'Target and steps refresh every round',
        buildPage: () => const NumberChainScreen(),
      ),
      _HubGame(
        title: 'Shape Path',
        subtitle: 'Follow the shown shape route in the correct order.',
        badge: 'Puzzle',
        spotlightLabel: 'Path',
        icon: Icons.route_rounded,
        colors: const [Color(0xff22c55e), Color(0xff10b981)],
        statLine: 'Shape route gets longer each round',
        buildPage: () => const ShapePathScreen(),
      ),
      _HubGame(
        title: 'Quick Sort',
        subtitle: 'Pick each number from lowest to highest without mistakes.',
        badge: 'Puzzle',
        spotlightLabel: 'Sort',
        icon: Icons.swap_vert_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff3b82f6)],
        statLine: 'Bigger sets appear every round',
        buildPage: () => const QuickSortScreen(),
      ),
      _HubGame(
        title: 'Laser Loop',
        subtitle: 'Rotate mirror tiles and route the beam to the target.',
        badge: 'Puzzle',
        spotlightLabel: 'Laser',
        icon: Icons.bolt_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff3b82f6)],
        statLine: 'Compact offline mirror puzzle with quick resets',
        buildPage: () => const LaserLoopScreen(),
      ),
      _HubGame(
        title: 'Pair Finder',
        subtitle: 'Pick two tiles that add up to the target sum.',
        badge: 'Puzzle',
        spotlightLabel: 'Pairs',
        icon: Icons.exposure_plus_2_rounded,
        colors: const [Color(0xfff97316), Color(0xffef4444)],
        statLine: 'Target sum changes every round',
        buildPage: () => const PairFinderScreen(),
      ),
      _HubGame(
        title: 'Asteroid Shield',
        subtitle:
            'Rotate the defense ring and block incoming asteroids from every side.',
        badge: 'Arcade',
        spotlightLabel: 'Shield',
        icon: Icons.shield_moon_rounded,
        colors: const [Color(0xff8b5cf6), Color(0xffec4899)],
        statLine: 'Real-time orbital defense with increasing wave speed',
        buildPage: () => const AsteroidShieldScreen(),
      ),
      _HubGame(
        title: 'Pit Lane Planner',
        subtitle:
            'Make the correct pit strategy call from fuel, tire, and weather data.',
        badge: 'Racing',
        spotlightLabel: 'Strategy',
        icon: Icons.build_circle_rounded,
        colors: const [Color(0xffef4444), Color(0xfff97316)],
        statLine: 'Offline racing strategy instead of steering-based action',
        buildPage: () => const PitLanePlannerScreen(),
      ),
      _HubGame(
        title: 'Direction Dash',
        subtitle: 'Follow the direction rule and tap the correct arrow.',
        badge: 'Arcade',
        spotlightLabel: 'Arrows',
        icon: Icons.explore_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff3b82f6)],
        statLine: 'Same and opposite rules keep switching',
        buildPage: () => const DirectionDashScreen(),
      ),
      _HubGame(
        title: 'Flash Count',
        subtitle: 'Count the quick flash and remember the exact number shown.',
        badge: 'Arcade',
        spotlightLabel: 'Count',
        icon: Icons.flash_on_rounded,
        colors: const [Color(0xff8b5cf6), Color(0xffec4899)],
        statLine: 'Flash count grows as rounds increase',
        buildPage: () => const FlashCountScreen(),
      ),
      _HubGame(
        title: 'Balance Beam',
        subtitle: 'Stack weights carefully and hit the exact target total.',
        badge: 'Puzzle',
        spotlightLabel: 'Balance',
        icon: Icons.balance_rounded,
        colors: const [Color(0xff22c55e), Color(0xff16a34a)],
        statLine: 'Exact target only, overshoots reset the beam',
        buildPage: () => const BalanceBeamScreen(),
      ),
      _HubGame(
        title: 'Mini Maze',
        subtitle:
            'Move through the maze, dodge walls, and reach the goal tile.',
        badge: 'Arcade',
        spotlightLabel: 'Maze',
        icon: Icons.grid_goldenratio_rounded,
        colors: const [Color(0xfff59e0b), Color(0xfff97316)],
        statLine: 'A new maze layout appears every round',
        buildPage: () => const MiniMazeScreen(),
      ),
      _HubGame(
        title: 'Speed Trap',
        subtitle:
            'Brake at the right moment and stop inside the safe speed zone.',
        badge: 'Racing',
        spotlightLabel: 'Car',
        icon: Icons.speed_rounded,
        colors: const [Color(0xfffb7185), Color(0xfff97316)],
        statLine: 'Safe speed zone gets tighter each round',
        buildPage: () => const SpeedTrapScreen(),
      ),
      _HubGame(
        title: '2048',
        subtitle: 'Swipe to merge tiles and reach the 2048 tile.',
        badge: 'Puzzle',
        spotlightLabel: 'Merge',
        icon: Icons.grid_4x4_rounded,
        colors: const [Color(0xff06b6d4), Color(0xff8b5cf6)],
        statLine: stats.twenty48BestScore == 0
            ? 'No best score yet'
            : 'Best score: ${stats.twenty48BestScore}',
        buildPage: () => const Twenty48Screen(),
      ),
      _HubGame(
        title: 'Fuel Rush',
        subtitle:
            'Race 5 laps, manage your fuel, and pit stop at the right moment.',
        badge: 'Racing',
        spotlightLabel: 'Fuel',
        icon: Icons.local_gas_station_rounded,
        colors: const [Color(0xffef4444), Color(0xfff59e0b)],
        statLine: stats.fuelRushBestLaps == 0
            ? 'No race finished yet'
            : 'Best finish: ${stats.fuelRushBestLaps} laps',
        buildPage: () => const FuelRushScreen(),
      ),
      _HubGame(
        title: 'Desert Rally',
        subtitle:
            'Hold the road through dusty bends, dodge rocks, and survive the rally heat.',
        badge: 'Racing',
        spotlightLabel: 'Rally',
        icon: Icons.offline_bolt_rounded,
        colors: const [Color(0xfff97316), Color(0xfffacc15)],
        statLine: 'Desert track challenge with drifting road and boost pickups',
        buildPage: () => const DesertRallyScreen(),
      ),
      _HubGame(
        title: 'Grand Prix Rush',
        subtitle:
            'Race 5 laps on a real circuit, dodge rivals, and manage tire wear.',
        badge: 'Racing',
        spotlightLabel: 'GP',
        icon: Icons.emoji_events_rounded,
        colors: const [Color(0xffef4444), Color(0xfff97316)],
        statLine: stats.grandPrixRushBestLaps == 0
            ? 'No race finished yet'
            : 'Best finish: ${stats.grandPrixRushBestLaps} laps',
        buildPage: () => const GrandPrixRushScreen(),
      ),
      _HubGame(
        title: 'Apex Picker',
        subtitle: 'Read the corner and choose the best racing move.',
        badge: 'Racing',
        spotlightLabel: 'Apex',
        icon: Icons.turn_sharp_right_rounded,
        colors: const [Color(0xffef4444), Color(0xfff59e0b)],
        statLine: 'Racing line decision game built around corner judgement',
        buildPage: () => const ApexPickerScreen(),
      ),
      _HubGame(
        title: 'Drag Duel',
        subtitle: '2 players on the same screen. Hold your side to race first.',
        badge: 'Racing',
        spotlightLabel: '2P',
        icon: Icons.directions_car_filled_rounded,
        colors: const [Color(0xffef4444), Color(0xff3b82f6)],
        statLine: 'Local 2-player drag race. No internet needed.',
        buildPage: () => const DragDuelScreen(),
      ),
      _HubGame(
        title: 'Poker Bluff',
        subtitle: 'Get a 5-card hand and beat the CPU with a stronger rank.',
        badge: 'Cards',
        spotlightLabel: 'Poker',
        icon: Icons.style_rounded,
        colors: const [Color(0xff166534), Color(0xff14532d)],
        statLine: stats.pokerBluffBestStreak == 0
            ? 'No streak yet'
            : 'Best streak: ${stats.pokerBluffBestStreak}',
        buildPage: () => const PokerBluffScreen(),
      ),
      _HubGame(
        title: 'Turbo Overtake',
        subtitle:
            'Dodge traffic, rack up overtakes, and blast nitro to survive.',
        badge: 'Racing',
        spotlightLabel: 'Nitro',
        icon: Icons.rocket_launch_rounded,
        colors: const [Color(0xfff97316), Color(0xffef4444)],
        statLine: stats.turboOvertakeBestDistance == 0
            ? 'No run yet'
            : 'Best: ${stats.turboOvertakeBestDistance}m',
        buildPage: () => const TurboOvertakeScreen(),
      ),
    ];
    final seenTitles = <String>{};
    for (final game in games) {
      if (!seenTitles.add(game.title)) {
        throw StateError('Duplicate game title found: ${game.title}');
      }
    }
    return games;
  }

  Future<void> _loadStats() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _stats = snapshot;
    });
  }

  Future<void> _loadFavorites() async {
    final favorites = await GameStatsStore.instance.loadFavoriteGames();
    if (!mounted) return;
    setState(() {
      _favoriteTitles = favorites;
    });
  }

  Future<void> _toggleFavorite(_HubGame game) async {
    await _playClickSound();
    await GameStatsStore.instance.toggleFavoriteGame(game.title);
    if (!mounted) return;
    setState(() {
      if (_favoriteTitles.contains(game.title)) {
        _favoriteTitles = {..._favoriteTitles}..remove(game.title);
      } else {
        _favoriteTitles = {..._favoriteTitles, game.title};
      }
    });
  }

  int _popularityRank(_HubGame game) {
    const ranks = <String, int>{
      'Ludo': 100,
      'XOX Arena': 99,
      'Snakes & Ladders': 97,
      'Candy Match': 96,
      'Brick Breaker': 95,
      'Turbo Traffic': 94,
      'Nitro Sprint': 93,
      'Drift Run': 92,
      'Parking Dash': 91,
      'Overtake Rush': 90,
      'Highway Heat': 89,
      'Police Escape': 88,
      'Pit Stop Pro': 87,
      'Checkpoint Dash': 86,
      'Cone Slalom': 85,
      'Slipstream Surge': 84,
      'Race Strategist': 83,
      'Qualifying Lap': 82,
      'Mountain Drive': 81,
      'Snake': 93,
      'Chess': 92,
      'Memory Match': 91,
      'Sudoku Mini': 90,
      'Rock Paper Scissors': 89,
      'Blackjack': 88,
      'War Cards': 87,
      'Suit Streak': 86,
      'Cricket Chase': 86,
      'Bike Sprint': 85,
      'Picture Puzzle': 84,
      'Math Equation': 83,
      'Word Blank': 82,
      'Balloon Pop': 81,
      'Color Match': 80,
      'Odd One Out': 79,
      'Light Grid': 78,
      'Garage Sort': 78,
      'Tap Sequence': 77,
      'Target Hunt': 76,
      'Treasure Tap': 75,
      'Beat Burst': 74,
      'Safe Cracker': 74,
      'Color Sweep': 73,
      'Symbol Memory': 72,
      'Clock Match': 72,
      'Lane Switch': 71,
      'Number Chain': 70,
      'Shape Path': 69,
      'Laser Loop': 69,
      'Quick Sort': 68,
      'Penalty Kick': 67,
      'Cup Shuffle': 66,
      'Pair Finder': 65,
      'Pit Lane Planner': 65,
      'Direction Dash': 64,
      'Flash Count': 63,
      'Balance Beam': 62,
      'Mini Maze': 61,
      'Card Count': 60,
      'Rhyme Time': 59,
      'Match Tactics': 58,
      'Speed Trap': 57,
      'Mole Smash': 56,
      'Bomb Diffuser': 55,
      'Shop Cashier': 54,
      'Airport Control': 53,
      'Sonar Sweep': 67,
      'Asteroid Shield': 74,
      'Circuit Racer': 98,
      'Fuel Rush': 80,
      'Desert Rally': 79,
      'Grand Prix Rush': 96,
      'Drag Duel': 88,
      'Poker Bluff': 85,
      'Turbo Overtake': 94,
    };
    return ranks[game.title] ?? 10;
  }

  Future<void> _setupDashboardMusic() async {
    final player = AudioPlayer();
    _musicPlayer = player;
    try {
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.28);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_musicEnabled) return;
        _playDashboardMusic();
      });
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || !_musicEnabled) return;
        _playDashboardMusic();
      });
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _playDashboardMusic() async {
    final player = _musicPlayer;
    if (player == null || !_musicEnabled) return;

    try {
      await player.stop();
      await player.setVolume(0.28);
      await player.setSource(AssetSource('music/bg.mp3'));
      await player.resume();
    } catch (e) {
      debugPrint('Dashboard bg.mp3 failed, falling back: $e');
      try {
        await player.stop();
        await player.setSource(AssetSource('music/begin.mp3'));
        await player.resume();
      } catch (fallbackError) {
        debugPrint('Dashboard fallback music failed: $fallbackError');
      }
    }
  }

  Future<void> _playClickSound() async {
    if (!Utility.volume) return;

    try {
      await _player.play(AssetSource('music/Click.mp3'));
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _loadBanner() async {
    if (!AdHelper.shouldShowBannerAds) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final width = MediaQuery.of(context).size.width.truncate();
      final adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      final ad = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        size: adaptiveSize ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _bannerAd = ad as BannerAd;
            debugPrint('Dashboard banner loaded successfully.');
            setState(() => _isBannerReady = true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'Dashboard banner failed: ${error.code} ${error.message}',
            );
            ad.dispose();
            setState(() {
              _bannerAd = null;
              _isBannerReady = false;
            });
            Future<void>.delayed(const Duration(seconds: 8), () {
              if (!mounted || _isBannerReady || _bannerAd != null) return;
              _loadBanner();
            });
          },
        ),
      );

      setState(() => _bannerAd = ad);
      ad.load();
    });
  }

  Future<void> _openGame(_HubGame game) async {
    await _playClickSound();
    await _musicPlayer?.stop();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    await GameStatsStore.instance.recordGameLaunch();
    await Get.to(game.buildPage);
    if (!mounted) return;
    setState(() {
      _musicEnabled = Utility.volume;
    });
    if (_musicEnabled) {
      try {
        await _playDashboardMusic();
      } catch (e) {
        debugPrint('Audio error: $e');
      }
    }
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    final viewBottomInset = mediaQuery.viewPadding.bottom;
    final gestureBottomInset = mediaQuery.systemGestureInsets.bottom;
    final safeBottomInset = math.max(
      bottomInset,
      math.max(viewBottomInset, gestureBottomInset),
    );
    final showBanner = _isBannerReady && _bannerAd != null;
    final bannerHeight = _bannerAd?.size.height.toDouble() ?? 50.0;
    final dashboardBottomPadding =
        18.0 + safeBottomInset + (showBanner ? bannerHeight + 12 : 0.0);
    final stats = _stats;
    final allGames = _games(
      stats ??
          const GameStatsSnapshot(
            memoryBestMoves: 0,
            numberGuessBestAttempts: 0,
            rangePickerLargestRange: 0,
            headsOrTailsBestStreak: 0,
            rockPaperScissorsWins: 0,
            diceDuelWins: 0,
            higherLowerBestStreak: 0,
            quickTapBestScore: 0,
            snakeBestLength: 0,
            sudokuSolvedBoards: 0,
            cricketWins: 0,
            snakesAndLaddersWins: 0,
            ludoWins: 0,
            balloonPopBestScore: 0,
            colorMatchBestScore: 0,
            oddOneOutBestStreak: 0,
            lightGridBestLevel: 0,
            tapSequenceBestLevel: 0,
            turboTrafficBestScore: 0,
            bikeSprintBestDistance: 0,
            cycleDashBestDistance: 0,
            avatarRushBestScore: 0,
            nitroSprintBestTimeMs: 0,
            driftRunBestDistance: 0,
            parkingDashBestLevel: 0,
            overtakeRushBestScore: 0,
            brickBreakerBestScore: 0,
            candyMatchBestScore: 0,
            mathEquationLevel: 1,
            wordBlankLevel: 1,
            picturePuzzleLevel: 1,
            totalMiniGamesPlayed: 0,
            twenty48BestScore: 0,
            fuelRushBestLaps: 0,
            grandPrixRushBestLaps: 0,
            pokerBluffBestStreak: 0,
            turboOvertakeBestDistance: 0,
          ),
    );
    final games =
        allGames
            .where((game) => _matchesCategory(game, _selectedCategory))
            .where((game) => _matchesSearch(game, _searchQuery))
            .toList()
          ..sort((a, b) {
            final aFavorite = _favoriteTitles.contains(a.title) ? 1 : 0;
            final bFavorite = _favoriteTitles.contains(b.title) ? 1 : 0;
            if (aFavorite != bFavorite) {
              return bFavorite.compareTo(aFavorite);
            }
            final popularity = _popularityRank(b).compareTo(_popularityRank(a));
            if (popularity != 0) return popularity;
            return a.title.compareTo(b.title);
          });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await showExitAppPrompt(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xff071018),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xff06111b),
                      Color(0xff0a1622),
                      Color(0xff08111b),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -120,
              left: -80,
              child: _glowOrb(
                const Color(0xff10b981).withValues(alpha: 0.14),
                220,
              ),
            ),
            Positioned(
              top: 110,
              right: -80,
              child: _glowOrb(
                const Color(0xff22d3ee).withValues(alpha: 0.1),
                210,
              ),
            ),
            Positioned(
              bottom: 160,
              left: -40,
              child: _glowOrb(
                const Color(0xff84cc16).withValues(alpha: 0.08),
                150,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _EntranceReveal(
                              delay: const Duration(milliseconds: 40),
                              child: _buildHeader(),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          // SliverToBoxAdapter(
                          //   child: _EntranceReveal(
                          //     delay: const Duration(milliseconds: 120),
                          //     child: _buildFeaturedCard(stats, games.length),
                          //   ),
                          // ),
                          // const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          // SliverToBoxAdapter(
                          //   child: _EntranceReveal(
                          //     delay: const Duration(milliseconds: 180),
                          //     child: _buildStatRail(stats, games.length),
                          //   ),
                          // ),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          SliverToBoxAdapter(
                            child: _EntranceReveal(
                              delay: const Duration(milliseconds: 220),
                              child: _buildSearchField(),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          SliverToBoxAdapter(
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'All games',
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                ),
                                Text(
                                  '${games.length}/${allGames.length}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          SliverToBoxAdapter(child: _buildCategoryTabs()),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          SliverToBoxAdapter(
                            child: _buildAnimatedGameGrid(games),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverToBoxAdapter(
                            child: _EntranceReveal(
                              delay: const Duration(milliseconds: 320),
                              child: _buildProgressSection(
                                stats ??
                                    const GameStatsSnapshot(
                                      memoryBestMoves: 0,
                                      numberGuessBestAttempts: 0,
                                      rangePickerLargestRange: 0,
                                      headsOrTailsBestStreak: 0,
                                      rockPaperScissorsWins: 0,
                                      diceDuelWins: 0,
                                      higherLowerBestStreak: 0,
                                      quickTapBestScore: 0,
                                      snakeBestLength: 0,
                                      sudokuSolvedBoards: 0,
                                      cricketWins: 0,
                                      snakesAndLaddersWins: 0,
                                      ludoWins: 0,
                                      balloonPopBestScore: 0,
                                      colorMatchBestScore: 0,
                                      oddOneOutBestStreak: 0,
                                      lightGridBestLevel: 0,
                                      tapSequenceBestLevel: 0,
                                      turboTrafficBestScore: 0,
                                      bikeSprintBestDistance: 0,
                                      cycleDashBestDistance: 0,
                                      avatarRushBestScore: 0,
                                      nitroSprintBestTimeMs: 0,
                                      driftRunBestDistance: 0,
                                      parkingDashBestLevel: 0,
                                      overtakeRushBestScore: 0,
                                      brickBreakerBestScore: 0,
                                      candyMatchBestScore: 0,
                                      mathEquationLevel: 1,
                                      wordBlankLevel: 1,
                                      picturePuzzleLevel: 1,
                                      totalMiniGamesPlayed: 0,
                                      twenty48BestScore: 0,
                                      fuelRushBestLaps: 0,
                                      grandPrixRushBestLaps: 0,
                                      pokerBluffBestStreak: 0,
                                      turboOvertakeBestDistance: 0,
                                    ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverToBoxAdapter(
                            child: _EntranceReveal(
                              delay: const Duration(milliseconds: 360),
                              child: _buildBadgeShowcase(
                                stats ??
                                    const GameStatsSnapshot(
                                      memoryBestMoves: 0,
                                      numberGuessBestAttempts: 0,
                                      rangePickerLargestRange: 0,
                                      headsOrTailsBestStreak: 0,
                                      rockPaperScissorsWins: 0,
                                      diceDuelWins: 0,
                                      higherLowerBestStreak: 0,
                                      quickTapBestScore: 0,
                                      snakeBestLength: 0,
                                      sudokuSolvedBoards: 0,
                                      cricketWins: 0,
                                      snakesAndLaddersWins: 0,
                                      ludoWins: 0,
                                      balloonPopBestScore: 0,
                                      colorMatchBestScore: 0,
                                      oddOneOutBestStreak: 0,
                                      lightGridBestLevel: 0,
                                      tapSequenceBestLevel: 0,
                                      turboTrafficBestScore: 0,
                                      bikeSprintBestDistance: 0,
                                      cycleDashBestDistance: 0,
                                      avatarRushBestScore: 0,
                                      nitroSprintBestTimeMs: 0,
                                      driftRunBestDistance: 0,
                                      parkingDashBestLevel: 0,
                                      overtakeRushBestScore: 0,
                                      brickBreakerBestScore: 0,
                                      candyMatchBestScore: 0,
                                      mathEquationLevel: 1,
                                      wordBlankLevel: 1,
                                      picturePuzzleLevel: 1,
                                      totalMiniGamesPlayed: 0,
                                      twenty48BestScore: 0,
                                      fuelRushBestLaps: 0,
                                      grandPrixRushBestLaps: 0,
                                      pokerBluffBestStreak: 0,
                                      turboOvertakeBestDistance: 0,
                                    ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverToBoxAdapter(
                            child: _EntranceReveal(
                              delay: const Duration(milliseconds: 420),
                              child: _buildActionStrip(),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: dashboardBottomPadding),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showBanner)
              Positioned(
                left: 0,
                right: 0,
                bottom: safeBottomInset,
                child: Container(
                  color: const Color(0xff111827),
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Center(
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XOX Arcade',
                style: AppTextStyles.display.copyWith(
                  letterSpacing: -1,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Jump into quick games without digging through a long home screen.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            setState(() {
              _musicEnabled = !_musicEnabled;
              Utility.volume = _musicEnabled;
            });
            if (_musicEnabled) {
              await _playClickSound();
              try {
                await _playDashboardMusic();
              } catch (e) {
                debugPrint('Audio error: $e');
              }
            } else {
              await _musicPlayer?.stop();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              _musicEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildFeaturedCard(GameStatsSnapshot? stats, int gameCount) {
    final totalPlayed = stats?.totalMiniGamesPlayed ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0f2d3a), Color(0xff164e63)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0ea5a4).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: _HeroAmbientPattern()),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'All your games in one place',
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 19),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalPlayed == 0
                              ? 'Tap any card and start playing. Progress saves automatically.'
                              : '$totalPlayed game launches saved on this device.',
                          style: AppTextStyles.body.copyWith(
                            color: const Color(0xffd7f5f0),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _FeatureChip(label: 'Quick'),
                            _FeatureChip(label: 'Kids'),
                            _FeatureChip(label: '2P'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeroMetric(label: 'Games', value: '$gameCount'),
                      const SizedBox(height: 8),
                      _HeroMetric(
                        label: 'Saved',
                        value: totalPlayed == 0 ? 'Ready' : 'On',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStatRail(GameStatsSnapshot? stats, int gameCount) {
    final snapshot = stats;
    final bestSkillRun = [
      snapshot?.headsOrTailsBestStreak ?? 0,
      snapshot?.higherLowerBestStreak ?? 0,
      snapshot?.quickTapBestScore ?? 0,
    ].reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _InfoPill(label: 'Games', value: '$gameCount'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoPill(
            label: 'Launches',
            value: '${snapshot?.totalMiniGamesPlayed ?? 0}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoPill(
            label: 'Top streak',
            value: bestSkillRun == 0 ? '--' : bestSkillRun.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(GameStatsSnapshot stats) {
    final achievements = _buildAchievements(stats);
    final unlocked = achievements.where((item) => item.unlocked).length;
    final completion = achievements.isEmpty
        ? 0.0
        : unlocked / achievements.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff0d1a27).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _AchievementRing(progress: completion),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Progress & achievements',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked == 0
                      ? 'Start a few games to unlock your first badge.'
                      : '$unlocked of ${achievements.length} badges unlocked.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(completion * 100).round()}%',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeShowcase(GameStatsSnapshot stats) {
    final achievements = _buildAchievements(stats);
    final unlocked = achievements.where((item) => item.unlocked).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xff0b1623).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xfffacc15).withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: Color(0xfffde68a),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Badges', style: AppTextStyles.sectionTitle),
              ),
              Text(
                '$unlocked/${achievements.length} unlocked',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xfffcd34d),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Collect them as you play.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: 172,
                child: _buildBadgeTile(achievements[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          return InkWell(
            onTap: () {
              if (selected) return;
              setState(() {
                _selectedCategory = category;
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff22d3ee), Color(0xff22c55e)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xff0d1826),
                          const Color(0xff111c2c).withValues(alpha: 0.96),
                        ],
                      ),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0xff22c55e).withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: selected ? 18 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                category,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.ink : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        style: const TextStyle(color: Colors.white),
        cursorColor: const Color(0xff67e8f9),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search games, moods, or categories',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff22d3ee).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.search_rounded, color: Color(0xff67e8f9)),
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedGameGrid(List<_HubGame> games) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1280
            ? 7
            : width > 1080
            ? 6
            : width > 860
            ? 5
            : width > 620
            ? 4
            : 4;
        final mainAxisExtent = width > 860 ? 148.0 : 138.0;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: GridView.builder(
            key: ValueKey<String>('$_selectedCategory|$_searchQuery'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: games.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 18,
              crossAxisSpacing: 12,
              mainAxisExtent: mainAxisExtent,
            ),
            itemBuilder: (context, index) => _EntranceReveal(
              delay: Duration(milliseconds: 340 + (index * 14)),
              child: _buildGameCard(games[index]),
            ),
          ),
        );
      },
    );
  }

  List<_Achievement> _buildAchievements(GameStatsSnapshot stats) {
    return [
      _Achievement(
        title: 'Arcade Explorer',
        description: 'Launch 10 mini-games',
        unlocked: stats.totalMiniGamesPlayed >= 10,
        progressLabel: '${stats.totalMiniGamesPlayed}/10',
        icon: Icons.explore_rounded,
      ),
      _Achievement(
        title: 'Quick Fingers',
        description: 'Score 30 taps in Quick Tap',
        unlocked: stats.quickTapBestScore >= 30,
        progressLabel: '${stats.quickTapBestScore}/30',
        icon: Icons.bolt_rounded,
      ),
      _Achievement(
        title: 'Lucky Streak',
        description: 'Reach a 5-win coin streak',
        unlocked: stats.headsOrTailsBestStreak >= 5,
        progressLabel: '${stats.headsOrTailsBestStreak}/5',
        icon: Icons.workspace_premium_rounded,
      ),
      _Achievement(
        title: 'Card Shark',
        description: 'Reach a 6-win Higher or Lower streak',
        unlocked: stats.higherLowerBestStreak >= 6,
        progressLabel: '${stats.higherLowerBestStreak}/6',
        icon: Icons.style_rounded,
      ),
      _Achievement(
        title: 'Sharp Memory',
        description: 'Clear Memory Match in 16 moves or less',
        unlocked: stats.memoryBestMoves != 0 && stats.memoryBestMoves <= 16,
        progressLabel: stats.memoryBestMoves == 0
            ? '--/16'
            : '${stats.memoryBestMoves}/16',
        icon: Icons.psychology_alt_rounded,
      ),
      _Achievement(
        title: 'Number Whisperer',
        description: 'Solve Number Guess in 4 tries or less',
        unlocked:
            stats.numberGuessBestAttempts != 0 &&
            stats.numberGuessBestAttempts <= 4,
        progressLabel: stats.numberGuessBestAttempts == 0
            ? '--/4'
            : '${stats.numberGuessBestAttempts}/4',
        icon: Icons.pin_rounded,
      ),
      _Achievement(
        title: 'Street Survivor',
        description: 'Dodge 12 cars in Turbo Traffic',
        unlocked: stats.turboTrafficBestScore >= 12,
        progressLabel: '${stats.turboTrafficBestScore}/12',
        icon: Icons.local_fire_department_rounded,
      ),
      _Achievement(
        title: 'Sprint Specialist',
        description: 'Reach 220 m in Bike Sprint',
        unlocked: stats.bikeSprintBestDistance >= 220,
        progressLabel: '${stats.bikeSprintBestDistance}/220',
        icon: Icons.two_wheeler_rounded,
      ),
      _Achievement(
        title: 'Stage Tactician',
        description: 'Reach 170 m in Cycle Dash',
        unlocked: stats.cycleDashBestDistance >= 170,
        progressLabel: '${stats.cycleDashBestDistance}/170',
        icon: Icons.pedal_bike_rounded,
      ),
      _Achievement(
        title: 'Rush Reflex',
        description: 'Survive 10 obstacles in Avatar Rush',
        unlocked: stats.avatarRushBestScore >= 10,
        progressLabel: '${stats.avatarRushBestScore}/10',
        icon: Icons.directions_run_rounded,
      ),
    ];
  }

  Widget _buildBadgeTile(_Achievement achievement) {
    final accent = achievement.unlocked
        ? const Color(0xfffacc15)
        : const Color(0xff64748b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: achievement.unlocked
              ? [const Color(0xff3b2f05), const Color(0xff5b4610)]
              : [const Color(0xff111827), const Color(0xff1e293b)],
        ),
        border: Border.all(
          color: accent.withValues(alpha: achievement.unlocked ? 0.42 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: achievement.unlocked ? 0.16 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _BadgeMedallion(
            icon: achievement.icon,
            accent: accent,
            unlocked: achievement.unlocked,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 1),
                Text(
                  achievement.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.unlocked ? 'Unlocked' : achievement.progressLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: achievement.unlocked
                        ? const Color(0xfffde68a)
                        : AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(_HubGame game) {
    final isFavorite = _favoriteTitles.contains(game.title);
    return _InteractiveCard(
      borderRadius: BorderRadius.circular(26),
      shadowColor: game.colors.last.withValues(alpha: 0.18),
      onTap: () => _openGame(game),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: game.colors.last.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: _GameArt(
                        colors: game.colors,
                        icon: game.icon,
                        imageAsset: game.imageAsset,
                        artStyle: game.artStyle,
                        height: 74,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        game.badge,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleFavorite(game),
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? const Color(0xfffb7185)
                                : Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  game.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionStrip() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.ios_share_rounded,
            title: 'Share',
            subtitle: 'Invite',
            onTap: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      "Let's have fun with XOX https://play.google.com/store/apps/details?id=com.xox.madvise",
                  subject: "Let's Play!!",
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionCard(
            icon: Icons.system_update_alt_rounded,
            title: 'Update',
            subtitle: 'Check',
            onTap: () => checkAppUpdate(context, showFeedback: true),
          ),
        ),
      ],
    );
  }

  Widget _glowOrb(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 60, spreadRadius: 12)],
      ),
    );
  }
}

class _HubGame {
  const _HubGame({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.spotlightLabel,
    required this.icon,
    required this.colors,
    required this.statLine,
    required this.buildPage,
    this.imageAsset,
    this.artStyle = _GameArtStyle.standard,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String spotlightLabel;
  final IconData icon;
  final List<Color> colors;
  final String? imageAsset;
  final _GameArtStyle artStyle;
  final String statLine;
  final Widget Function() buildPage;
}

enum _GameArtStyle {
  standard,
  quickTap,
  higherLower,
  snake,
  sudoku,
  cricket,
  snakesLadders,
  ludo,
  balloonPop,
  colorMatch,
  brickBreaker,
  candyMatch,
  picturePuzzle,
  mathEquation,
  blackjack,
  warCards,
  chess,
  turboTraffic,
  bikeSprint,
  cycleDash,
  avatarRush,
}

class _GameArt extends StatelessWidget {
  const _GameArt({
    required this.colors,
    required this.icon,
    required this.imageAsset,
    required this.artStyle,
    this.height = 68,
    this.width = 84,
  });

  final List<Color> colors;
  final IconData icon;
  final String? imageAsset;
  final _GameArtStyle artStyle;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          _ArtShimmer(
            borderRadius: BorderRadius.circular(24),
            child: imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(imageAsset!, fit: BoxFit.cover),
                  )
                : _FallbackGameArt(
                    artStyle: artStyle,
                    colors: colors,
                    icon: icon,
                    compact: false,
                  ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Icon(
              icon,
              size: 36,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 8,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackGameArt extends StatelessWidget {
  const _FallbackGameArt({
    required this.artStyle,
    required this.colors,
    required this.icon,
    this.compact = false,
  });

  final _GameArtStyle artStyle;
  final List<Color> colors;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    switch (artStyle) {
      case _GameArtStyle.quickTap:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.25),
                  radius: 0.9,
                  colors: [
                    Colors.white.withValues(alpha: 0.24),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                height: compact ? 42 : 58,
                width: compact ? 42 : 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffccfbf1),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.touch_app_rounded,
                    color: Color(0xff0f766e),
                    size: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 10 : 16,
              right: compact ? 10 : 16,
              bottom: compact ? 12 : 16,
              child: Container(
                height: compact ? 8 : 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [Color(0xff67e8f9), Color(0xff34d399)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case _GameArtStyle.higherLower:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 12 : 18,
              top: compact ? 12 : 16,
              child: _MiniCardToken(
                label: 'K',
                angle: -0.14,
                color: const Color(0xfff97316),
                compact: compact,
              ),
            ),
            Positioned(
              right: compact ? 12 : 16,
              bottom: compact ? 10 : 14,
              child: _MiniCardToken(
                label: '3',
                angle: 0.12,
                color: const Color(0xfffacc15),
                compact: compact,
              ),
            ),
            Center(
              child: Icon(
                Icons.swap_vert_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: compact ? 28 : 36,
              ),
            ),
          ],
        );
      case _GameArtStyle.snake:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 10 : 14,
              right: compact ? 10 : 14,
              top: compact ? 24 : 30,
              child: Container(
                height: compact ? 12 : 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xffbef264),
                ),
              ),
            ),
            Positioned(
              right: compact ? 12 : 18,
              top: compact ? 18 : 22,
              child: Container(
                height: compact ? 18 : 22,
                width: compact ? 18 : 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffecfccb),
                ),
                child: const Center(
                  child: Icon(Icons.circle, size: 5, color: Color(0xff365314)),
                ),
              ),
            ),
            Positioned(
              left: compact ? 14 : 20,
              bottom: compact ? 14 : 18,
              child: Container(
                height: compact ? 10 : 14,
                width: compact ? 10 : 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffef4444),
                ),
              ),
            ),
          ],
        );
      case _GameArtStyle.sudoku:
        return Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: GridView.count(
            crossAxisCount: 2,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: const [
              _MiniGridTile(label: '1'),
              _MiniGridTile(label: '4'),
              _MiniGridTile(label: '2'),
              _MiniGridTile(label: '3'),
            ],
          ),
        );
      case _GameArtStyle.cricket:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 18 : 22,
              bottom: compact ? 16 : 20,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  height: compact ? 38 : 48,
                  width: compact ? 8 : 10,
                  decoration: BoxDecoration(
                    color: const Color(0xfffde68a),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Positioned(
              right: compact ? 16 : 18,
              top: compact ? 16 : 18,
              child: Container(
                height: compact ? 16 : 20,
                width: compact ? 16 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xfff97316),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xfff97316).withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: compact ? 20 : 24,
              bottom: compact ? 14 : 18,
              child: Column(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    height: compact ? 14 : 18,
                    width: 3,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        );
      case _GameArtStyle.snakesLadders:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 18 : 22,
              top: compact ? 14 : 18,
              child: Transform.rotate(
                angle: -0.4,
                child: Column(
                  children: [
                    Container(
                      height: compact ? 34 : 42,
                      width: 3,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: compact ? 34 : 42,
                      width: 3,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: compact ? 18 : 22,
              top: compact ? 22 : 28,
              child: Transform.rotate(
                angle: -0.4,
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Container(
                        width: compact ? 24 : 30,
                        height: 3,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: compact ? 14 : 18,
              bottom: compact ? 16 : 18,
              child: Text('🐍', style: TextStyle(fontSize: compact ? 24 : 32)),
            ),
          ],
        );
      case _GameArtStyle.ludo:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 14 : 18,
              top: compact ? 12 : 16,
              child: Container(
                height: compact ? 20 : 24,
                width: compact ? 20 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffef4444),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            Positioned(
              right: compact ? 14 : 18,
              bottom: compact ? 12 : 16,
              child: Container(
                height: compact ? 20 : 24,
                width: compact ? 20 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2563eb),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            Center(
              child: Container(
                height: compact ? 28 : 34,
                width: compact ? 28 : 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  child: Text(
                    '6',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 22 : 26,
              right: compact ? 22 : 26,
              top: compact ? 30 : 36,
              child: Container(
                height: 3,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            Positioned(
              top: compact ? 20 : 24,
              bottom: compact ? 20 : 24,
              left: compact ? 40 : 46,
              child: Container(
                width: 3,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        );
      case _GameArtStyle.balloonPop:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 14 : 18,
              top: compact ? 18 : 20,
              child: _MiniBalloon(
                color: const Color(0xffff8fab),
                compact: compact,
              ),
            ),
            Positioned(
              right: compact ? 16 : 20,
              top: compact ? 26 : 30,
              child: _MiniBalloon(
                color: const Color(0xfffbbf24),
                compact: compact,
              ),
            ),
            Positioned(
              left: compact ? 28 : 36,
              bottom: compact ? 12 : 16,
              child: _MiniBalloon(
                color: const Color(0xff60a5fa),
                compact: compact,
              ),
            ),
          ],
        );
      case _GameArtStyle.colorMatch:
        return Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xff22c55e),
                  ),
                  child: const Center(
                    child: Text(
                      'Green',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Expanded(child: _MiniColorDot(color: Color(0xffef4444))),
                  SizedBox(width: 6),
                  Expanded(child: _MiniColorDot(color: Color(0xff22c55e))),
                  SizedBox(width: 6),
                  Expanded(child: _MiniColorDot(color: Color(0xff3b82f6))),
                ],
              ),
            ],
          ),
        );
      case _GameArtStyle.brickBreaker:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 10 : 12,
              right: compact ? 10 : 12,
              top: compact ? 12 : 14,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    [
                          const Color(0xfffb7185),
                          const Color(0xfff59e0b),
                          const Color(0xff22c55e),
                          const Color(0xff38bdf8),
                          const Color(0xffa78bfa),
                          const Color(0xfff97316),
                        ]
                        .map((color) {
                          return Container(
                            height: compact ? 8 : 10,
                            width: compact ? 16 : 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: color,
                            ),
                          );
                        })
                        .toList(growable: false),
              ),
            ),
            Positioned(
              left: compact ? 18 : 22,
              right: compact ? 18 : 22,
              bottom: compact ? 12 : 14,
              child: Container(
                height: compact ? 8 : 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xff67e8f9),
                ),
              ),
            ),
            Positioned(
              right: compact ? 16 : 22,
              bottom: compact ? 26 : 30,
              child: Container(
                height: compact ? 10 : 12,
                width: compact ? 10 : 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      case _GameArtStyle.candyMatch:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 12 : 14,
              top: compact ? 12 : 14,
              child: _MiniCandy(
                color: const Color(0xfffb7185),
                compact: compact,
              ),
            ),
            Positioned(
              right: compact ? 12 : 14,
              top: compact ? 20 : 24,
              child: _MiniCandy(
                color: const Color(0xffa855f7),
                compact: compact,
              ),
            ),
            Positioned(
              left: compact ? 26 : 32,
              bottom: compact ? 12 : 14,
              child: _MiniCandy(
                color: const Color(0xfff59e0b),
                compact: compact,
              ),
            ),
          ],
        );
      case _GameArtStyle.picturePuzzle:
        return Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: GridView.count(
            crossAxisCount: 2,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            children: const [
              _MiniPuzzleTile(color: Color(0xff38bdf8), label: 'A'),
              _MiniPuzzleTile(color: Color(0xff22c55e), label: 'D'),
              _MiniPuzzleTile(color: Color(0xfffacc15), label: 'C'),
              _MiniPuzzleTile(color: Color(0xff0f172a), label: 'B'),
            ],
          ),
        );
      case _GameArtStyle.mathEquation:
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                '8 + 6',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              right: compact ? 12 : 16,
              bottom: compact ? 12 : 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: Text(
                  '= ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      case _GameArtStyle.blackjack:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 14 : 18,
              top: compact ? 12 : 16,
              child: _MiniCardToken(
                label: 'A',
                angle: -0.12,
                color: const Color(0xff166534),
                compact: compact,
              ),
            ),
            Positioned(
              right: compact ? 12 : 16,
              bottom: compact ? 12 : 14,
              child: _MiniCardToken(
                label: 'K',
                angle: 0.14,
                color: const Color(0xffdc2626),
                compact: compact,
              ),
            ),
          ],
        );
      case _GameArtStyle.warCards:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 12 : 16,
              top: compact ? 16 : 18,
              child: _MiniCardToken(
                label: 'Q',
                angle: -0.16,
                color: const Color(0xfff97316),
                compact: compact,
              ),
            ),
            Positioned(
              right: compact ? 12 : 16,
              top: compact ? 20 : 24,
              child: _MiniCardToken(
                label: 'A',
                angle: 0.16,
                color: const Color(0xffef4444),
                compact: compact,
              ),
            ),
            Center(
              child: Icon(
                Icons.flash_on_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: compact ? 24 : 30,
              ),
            ),
          ],
        );
      case _GameArtStyle.chess:
        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                children: const [
                  _MiniGridTile(label: '♔'),
                  _MiniGridTile(label: '♞'),
                  _MiniGridTile(label: '♟'),
                  _MiniGridTile(label: '♕'),
                ],
              ),
            ),
          ],
        );
      case _GameArtStyle.turboTraffic:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 18 : 22,
                  vertical: compact ? 8 : 10,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Expanded(
                        child: Center(
                          child: Container(
                            height: 8,
                            width: 3,
                            color: Colors.white.withValues(alpha: 0.32),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 14 : 16,
              top: compact ? 12 : 14,
              child: Icon(
                Icons.local_shipping_rounded,
                color: Colors.white.withValues(alpha: 0.84),
                size: compact ? 20 : 24,
              ),
            ),
            Positioned(
              right: compact ? 18 : 20,
              bottom: compact ? 10 : 12,
              child: Icon(
                Icons.directions_car_filled_rounded,
                color: const Color(0xffe0f2fe),
                size: compact ? 28 : 34,
              ),
            ),
          ],
        );
      case _GameArtStyle.bikeSprint:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 12 : 16,
              right: compact ? 12 : 16,
              bottom: compact ? 12 : 14,
              child: Container(
                height: compact ? 10 : 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                child: Align(
                  alignment: const Alignment(0.12, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.28,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xff22c55e).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.two_wheeler_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: compact ? 32 : 40,
              ),
            ),
            Positioned(
              left: compact ? 30 : 36,
              top: compact ? 8 : 10,
              child: Container(
                height: compact ? 22 : 28,
                width: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xfff8fafc),
                ),
              ),
            ),
          ],
        );
      case _GameArtStyle.cycleDash:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 10 : 14,
              right: compact ? 10 : 14,
              top: compact ? 14 : 18,
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: compact ? 16 : 20,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: index < 3
                            ? const Color(0xffd9f99d)
                            : Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 24 : 28,
              bottom: compact ? 10 : 12,
              child: Icon(
                Icons.pedal_bike_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: compact ? 28 : 34,
              ),
            ),
            Positioned(
              right: compact ? 12 : 16,
              bottom: compact ? 12 : 14,
              child: Icon(
                Icons.bolt_rounded,
                color: const Color(0xfffef08a),
                size: compact ? 18 : 22,
              ),
            ),
          ],
        );
      case _GameArtStyle.avatarRush:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? 12 : 16,
              bottom: compact ? 10 : 14,
              child: Icon(
                Icons.directions_run_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: compact ? 30 : 38,
              ),
            ),
            Positioned(
              right: compact ? 12 : 16,
              bottom: compact ? 10 : 14,
              child: Container(
                height: compact ? 24 : 30,
                width: compact ? 18 : 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            Positioned(
              right: compact ? 22 : 28,
              top: compact ? 12 : 16,
              child: Container(
                height: compact ? 10 : 12,
                width: compact ? 34 : 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xfff9a8d4).withValues(alpha: 0.88),
                ),
              ),
            ),
          ],
        );
      case _GameArtStyle.standard:
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: compact ? 26 : 34,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        );
    }
  }
}

class _MiniBalloon extends StatelessWidget {
  const _MiniBalloon({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: compact ? 22 : 28,
          width: compact ? 18 : 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Container(
          height: compact ? 12 : 16,
          width: 2,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}

class _MiniPuzzleTile extends StatelessWidget {
  const _MiniPuzzleTile({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.9),
            Color.lerp(color, Colors.white, 0.2)!,
          ],
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _MiniColorDot extends StatelessWidget {
  const _MiniColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _MiniCandy extends StatelessWidget {
  const _MiniCandy({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.35,
      child: Container(
        height: compact ? 18 : 22,
        width: compact ? 18 : 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: compact ? 4 : 5,
              height: compact ? 8 : 10,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            Container(
              width: compact ? 4 : 5,
              height: compact ? 8 : 10,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCardToken extends StatelessWidget {
  const _MiniCardToken({
    required this.label,
    required this.angle,
    required this.color,
    required this.compact,
  });

  final String label;
  final double angle;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        height: compact ? 36 : 48,
        width: compact ? 26 : 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniGridTile extends StatelessWidget {
  const _MiniGridTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff0d1826).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement({
    required this.title,
    required this.description,
    required this.unlocked,
    required this.progressLabel,
    required this.icon,
  });

  final String title;
  final String description;
  final bool unlocked;
  final String progressLabel;
  final IconData icon;
}

class _BadgeMedallion extends StatefulWidget {
  const _BadgeMedallion({
    required this.icon,
    required this.accent,
    required this.unlocked,
  });

  final IconData icon;
  final Color accent;
  final bool unlocked;

  @override
  State<_BadgeMedallion> createState() => _BadgeMedallionState();
}

class _BadgeMedallionState extends State<_BadgeMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.unlocked) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _BadgeMedallion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unlocked && !oldWidget.unlocked) {
      _controller.repeat(reverse: true);
    } else if (!widget.unlocked && oldWidget.unlocked) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.unlocked) {
      return _buildBody(0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _buildBody(_controller.value),
    );
  }

  Widget _buildBody(double value) {
    final glow = 0.14 + (value * 0.12);
    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.accent.withValues(alpha: widget.unlocked ? 0.18 : 0.12),
        border: Border.all(
          color: widget.accent.withValues(alpha: widget.unlocked ? 0.5 : 0.18),
        ),
        boxShadow: widget.unlocked
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: glow),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        widget.icon,
        color: widget.unlocked ? const Color(0xfffff3b0) : Colors.white70,
        size: 15,
      ),
    );
  }
}

class _AchievementRing extends StatelessWidget {
  const _AchievementRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return SizedBox(
      height: 48,
      width: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(Color(0xfffacc15)),
          ),
          Center(
            child: Text(
              '$percent%',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveCard extends StatefulWidget {
  const _InteractiveCard({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    required this.shadowColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Color shadowColor;

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final active = _pressed || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: active && !reducedMotion ? 0.986 : 1,
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0,
            active && !reducedMotion ? 2 : 0,
            0,
          ),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(
                  alpha: active ? 0.14 : 0.08,
                ),
                blurRadius: active ? 14 : 24,
                offset: Offset(0, active ? 8 : 14),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius,
            onHighlightChanged: (value) {
              setState(() => _pressed = value);
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ArtShimmer extends StatefulWidget {
  const _ArtShimmer({required this.child, required this.borderRadius});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<_ArtShimmer> createState() => _ArtShimmerState();
}

class _ArtShimmerState extends State<_ArtShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (reducedMotion) {
      return ClipRRect(borderRadius: widget.borderRadius, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = (_controller.value * 1.8) - 0.9;
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child!,
              IgnorePointer(
                child: Transform.translate(
                  offset: Offset(slide * 80, 0),
                  child: Container(
                    width: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _HeroAmbientPattern extends StatefulWidget {
  const _HeroAmbientPattern();

  @override
  State<_HeroAmbientPattern> createState() => _HeroAmbientPatternState();
}

class _HeroAmbientPatternState extends State<_HeroAmbientPattern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (reducedMotion) {
      return CustomPaint(painter: _HeroPatternPainter(progress: 0.18));
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _HeroPatternPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  const _HeroPatternPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);

    final horizontalOffset = math.sin(progress * math.pi * 2) * 18;
    final verticalOffset = math.cos(progress * math.pi * 2) * 14;

    for (double x = -size.height; x < size.width + size.height; x += 36) {
      canvas.drawLine(
        Offset(x + horizontalOffset, 0),
        Offset(x - size.height + horizontalOffset, size.height),
        gridPaint,
      );
    }

    for (double y = -size.width; y < size.height + size.width; y += 44) {
      canvas.drawLine(
        Offset(0, y + verticalOffset),
        Offset(size.width, y - size.width + verticalOffset),
        gridPaint,
      );
    }

    final orbPaintA = Paint()
      ..color = const Color(0xfff8fafc).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    final orbPaintB = Paint()
      ..color = const Color(0xff67e8f9).withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 52);
    final orbPaintC = Paint()
      ..color = const Color(0xfff9a8d4).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 44);

    final phase = progress * math.pi * 2;
    canvas.drawCircle(
      Offset(
        size.width * 0.82 + math.sin(phase) * 16,
        size.height * 0.18 + math.cos(phase) * 10,
      ),
      68,
      orbPaintA,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.18 + math.cos(phase * 0.85) * 12,
        size.height * 0.76 + math.sin(phase * 0.9) * 12,
      ),
      82,
      orbPaintB,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.64 + math.cos(phase * 1.2) * 10,
        size.height * 0.52 + math.sin(phase * 1.1) * 10,
      ),
      56,
      orbPaintC,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _EntranceReveal extends StatefulWidget {
  const _EntranceReveal({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<_EntranceReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (!mounted) return;
        setState(() {
          _visible = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final visible = reducedMotion ? true : _visible;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.08),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xff0d1826).withValues(alpha: 0.92),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> getCurrentAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version.replaceAll('.', '');
}

Future<void> checkAppUpdate(
  BuildContext context, {
  bool showFeedback = false,
}) async {
  final currentVersion = await getCurrentAppVersion();
  if (!context.mounted) return;

  try {
    final versionSnapshot = await FirebaseFirestore.instance
        .collection('app_version')
        .doc('version_info')
        .get();

    final version = versionSnapshot.data();
    if (version == null) {
      if (showFeedback && context.mounted) {
        _showUpdateSnackBar(context, 'Could not check for updates right now.');
      }
      return;
    }

    final latestVersion = int.parse(
      version['current_version'].toString().replaceAll('.', ''),
    );

    if (latestVersion > int.parse(currentVersion)) {
      if (!context.mounted) return;
      showUpdateDialog(context);
      return;
    }

    if (showFeedback && context.mounted) {
      _showUpdateSnackBar(context, 'App is up to date.');
    }
  } catch (e) {
    debugPrint('Update check failed: $e');
    if (showFeedback && context.mounted) {
      _showUpdateSnackBar(context, 'Could not check for updates right now.');
    }
  }
}

void _showUpdateSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

Future<void> showUpdateDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Update Available'),
        content: const Text(
          'A new version of the app is available. Please update to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _launchUrl(
                'https://play.google.com/store/apps/details?id=com.xox.madvise',
              );
            },
            child: const Text('Update now'),
          ),
        ],
      );
    },
  );
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

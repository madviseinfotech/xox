// // ignore_for_file: prefer_const_constructors
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:just_audio/just_audio.dart';
// import '../utils/utility.dart';
// import 'enter_player_screen.dart';
//
// class ChoosePlayerScreen extends StatefulWidget {
//   const ChoosePlayerScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ChoosePlayerScreen> createState() => _ChoosePlayerScreenState();
// }
//
// class _ChoosePlayerScreenState extends State<ChoosePlayerScreen> {
//   TextEditingController player1Controller = TextEditingController();
//   TextEditingController player2Controller = TextEditingController();
//   String select = "computer";
//
//   @override
//   Widget build(BuildContext context) {
//     final player = AudioPlayer();
//     // Create a player
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           ///Bg image
//           Container(
//             height: Get.height,
//             width: Get.width,
//             decoration: BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/images/enterPlayerBg.png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//
//           ///details
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   SizedBox(height: 40),
//
//                   ///back & top Text
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       GestureDetector(
//                         onTap: () async {
//                           Get.back();
//                           if (Utility.volume == true) {
//                             Uri uri = Uri.parse(
//                               "asset:///assets/music/Click.mp3",
//                             );
//                             await player.setUrl(uri.toString());
//                             player.play();
//                           }
//                         },
//                         child: CircleAvatar(
//                           radius: 20,
//                           backgroundColor: Color(0xff32167D),
//                           child: Icon(
//                             Icons.arrow_back_outlined,
//                             size: 30,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: Column(
//                           children: const [
//                             Text(
//                               'Choose one',
//                               style: TextStyle(
//                                 color: Color(0xff37E9BB),
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 30,
//                               ),
//                             ),
//                             SizedBox(height: 10),
//                             Text(
//                               'Unleash Your Competitive Spirit in Multiplayer Battles!',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(width: 20),
//                     ],
//                   ),
//                   SizedBox(height: Get.width / 4),
//
//                   ///player1
//                   InkWell(
//                     onTap: () {
//                       setState(() {
//                         select = "computer";
//                       });
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(40),
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment(0.8, 1),
//                           colors: <Color>[
//                             select == "computer"
//                                 ? Color(0xffE06340)
//                                 : Color(0xff32167D),
//                             select == "computer"
//                                 ? Color(0xffFFAD6B)
//                                 : Color(0xff32167D),
//                           ], // Gradient from https://learnui.design/tools/gradient-generator.html
//                           tileMode: TileMode.mirror,
//                         ),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: SizedBox(
//                           height: Get.height * 0.065,
//                           width: Get.width,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               border: select == "computer"
//                                   ? Border.all(color: Colors.white, width: 1)
//                                   : null,
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 "With Computer",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: Get.height * 0.03),
//
//                   ///player2
//                   InkWell(
//                     onTap: () {
//                       setState(() {
//                         select = "player";
//                       });
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(40),
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment(0.8, 1),
//                           colors: <Color>[
//                             select == "player"
//                                 ? Color(0xffFE439E)
//                                 : Color(0xff32167D),
//                             select == "player"
//                                 ? Color(0xffFF55BF)
//                                 : Color(0xff32167D),
//                           ], // Gradient from https://learnui.design/tools/gradient-generator.html
//                           tileMode: TileMode.mirror,
//                         ),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: SizedBox(
//                           height: Get.height * 0.065,
//                           width: Get.width,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               border: select == "player"
//                                   ? Border.all(color: Colors.white, width: 1)
//                                   : null,
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 "With Player",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: Get.width / 2),
//                   InkWell(
//                     onTap: () async {
//                       if (Utility.volume == true) {
//                         Uri uri = Uri.parse("asset:///assets/music/start.mp3");
//                         await player.setUrl(uri.toString());
//                         player.play();
//                       }
//                       if (select == "computer") {
//                         Get.to(() => EnterPlayerScreen(playWithComputer: true));
//                       } else {
//                         Get.to(
//                           () => EnterPlayerScreen(playWithComputer: false),
//                         );
//                       }
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(40),
//                         gradient: const LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment(0.8, 1),
//                           colors: <Color>[
//                             Color(0xff159F9C),
//                             Color(0xff2AD2B4),
//                           ], // Gradient from https://learnui.design/tools/gradient-generator.html
//                           tileMode: TileMode.mirror,
//                         ),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: SizedBox(
//                           height: Get.height * 0.060,
//                           width: Get.width,
//                           child: Center(
//                             child: Text(
//                               "Next",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/utility.dart';
import 'enter_player_screen.dart';
import 'ad_helper.dart'; // must return LIVE banner unit id

class ChoosePlayerScreen extends StatefulWidget {
  const ChoosePlayerScreen({super.key});

  @override
  State<ChoosePlayerScreen> createState() => _ChoosePlayerScreenState();
}

class _ChoosePlayerScreenState extends State<ChoosePlayerScreen> {
  final TextEditingController player1Controller = TextEditingController();
  final TextEditingController player2Controller = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  String select = "computer";

  // Banner ad (LIVE)
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _player.dispose();
    player1Controller.dispose();
    player2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final width = MediaQuery.of(context).size.width.truncate();
      final adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      final adSize = adaptiveSize ?? AdSize.banner;
      final ad = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId, // LIVE banner id
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _bannerAd = ad as BannerAd;
            setState(() => _isBannerReady = true);
            debugPrint(
              'Banner loaded: ${_bannerAd!.adUnitId} '
              'size=${_bannerAd!.size.width}x${_bannerAd!.size.height}',
            );
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed: ${error.code} ${error.message}');
            ad.dispose();
            setState(() {
              _bannerAd = null;
              _isBannerReady = false;
            });
          },
        ),
      );

      setState(() => _bannerAd = ad); // `_bannerAd` no longer null
      ad.load();
    });
  }

  Future<void> _clickSound() async {
    if (Utility.volume) {
      final uri = Uri.parse("asset:///assets/music/Click.mp3");
      await _player.setUrl(uri.toString());
      _player.play();
    }
  }

  Future<void> _startSound() async {
    if (Utility.volume) {
      final uri = Uri.parse("asset:///assets/music/start.mp3");
      await _player.setUrl(uri.toString());
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    print("---_bannerAd-----${_bannerAd}");
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/enterPlayerBg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 40),

                  // Back + Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Get.back();
                          await _clickSound();
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xff32167D),
                          child: const Icon(
                            Icons.arrow_back_outlined,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: const [
                            Text(
                              'Choose one',
                              style: TextStyle(
                                color: Color(0xff37E9BB),
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Unleash Your Competitive Spirit in Multiplayer Battles!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                    ],
                  ),

                  SizedBox(height: Get.width / 4),

                  // With Computer
                  InkWell(
                    onTap: () => setState(() => select = "computer"),
                    child: _gradientButton(
                      text: "With Computer",
                      active: select == "computer",
                      activeColors: const [
                        Color(0xffE06340),
                        Color(0xffFFAD6B),
                      ],
                    ),
                  ),

                  SizedBox(height: Get.height * 0.03),

                  // With Player
                  InkWell(
                    onTap: () => setState(() => select = "player"),
                    child: _gradientButton(
                      text: "With Player",
                      active: select == "player",
                      activeColors: const [
                        Color(0xffFE439E),
                        Color(0xffFF55BF),
                      ],
                    ),
                  ),

                  SizedBox(height: Get.width / 2),

                  // Next
                  InkWell(
                    onTap: () async {
                      await _startSound();
                      if (select == "computer") {
                        Get.to(
                          () => const EnterPlayerScreen(playWithComputer: true),
                        );
                      } else {
                        Get.to(
                          () =>
                              const EnterPlayerScreen(playWithComputer: false),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment(0.8, 1),
                          colors: [Color(0xff159F9C), Color(0xff2AD2B4)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: Get.height * 0.060,
                          width: Get.width,
                          child: const Center(
                            child: Text(
                              "Next",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Spacer so "Next" doesn't get covered by overlay banner
                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),

          // Bottom banner overlay (LIVE)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: SizedBox(
              height: (_bannerAd?.size.height.toDouble() ?? 50),
              child: Center(
                child: (_isBannerReady && _bannerAd != null)
                    ? SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required bool active,
    required List<Color> activeColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.8, 1),
          colors: active
              ? activeColors
              : const [Color(0xff32167D), Color(0xff32167D)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: Get.height * 0.065,
          width: Get.width,
          child: Container(
            decoration: BoxDecoration(
              border: active ? Border.all(color: Colors.white, width: 1) : null,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

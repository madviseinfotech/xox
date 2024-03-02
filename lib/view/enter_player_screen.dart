// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xo/view/gameScreen.dart';
import 'package:xo/view/service.dart';
import '../utils/utility.dart';
import 'ad_helper.dart';

class EnterPlayerScreen extends StatefulWidget {
  final bool playWithComputer;
  const EnterPlayerScreen({Key? key, this.playWithComputer = false})
      : super(key: key);

  @override
  State<EnterPlayerScreen> createState() => _EnterPlayerScreenState();
}

class _EnterPlayerScreenState extends State<EnterPlayerScreen> {
  TextEditingController player1Controller = TextEditingController();
  TextEditingController player2Controller = TextEditingController();
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    // TODO: Dispose a BannerAd object
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
    print("Connection Status: ${_connectionStatus.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayer(); // Create a player

    return Scaffold(
        body: Stack(
      children: [
        ///Bg image
        Container(
          height: Get.height,
          width: Get.width,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/enterPlayerBg.png'),
                fit: BoxFit.cover),
          ),
        ),

        ///details
        Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                ),

                ///back & top Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        Get.back();
                        if (Utility.volume == true) {
                          Uri uri =
                              Uri.parse("asset:///assets/music/Click.mp3");
                          await player.setUrl(uri.toString());
                          player.play();
                        }
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xff32167D),
                        child: Icon(Icons.arrow_back_outlined,
                            size: 30, color: Colors.white),
                      ),
                    ),
                    Column(
                      children: const [
                        Text(
                          'Enter Player',
                          style: TextStyle(
                              color: Color(0xff37E9BB),
                              fontWeight: FontWeight.bold,
                              fontSize: 30),
                        ),
                        Text(
                          'Name',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 20,
                    )
                  ],
                ),
                SizedBox(
                  height: Get.width / 4,
                ),

                ///player1
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xff32167D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Text(
                          '1',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: Get.width * 0.03,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(0.8, 1),
                            colors: <Color>[
                              Color(0xffE06340),
                              Color(0xffFFAD6B),
                            ], // Gradient from https://learnui.design/tools/gradient-generator.html
                            tileMode: TileMode.mirror,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: Get.height * 0.065,
                            width: Get.width,
                            child: TextFormField(
                              controller: player1Controller,
                              inputFormatters: [
                                NoLeadingSpaceFormatter(),
                                LengthLimitingTextInputFormatter(10)
                              ],
                              readOnly: widget.playWithComputer,
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                              decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1)),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1)),
                                  prefix: SizedBox(
                                    width: 10,
                                  ),
                                  hintText: widget.playWithComputer
                                      ? 'Computer'
                                      : 'Player 1',
                                  hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                  labelStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: Get.height * 0.03,
                ),

                ///player2
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xff32167D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Text(
                          '2',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: Get.width * 0.03,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(0.8, 1),
                            colors: <Color>[
                              Color(0xffFE439E),
                              Color(0xffFF55BF),
                            ], // Gradient from https://learnui.design/tools/gradient-generator.html
                            tileMode: TileMode.mirror,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: Get.height * 0.065,
                            width: Get.width,
                            child: TextFormField(
                              controller: player2Controller,
                              inputFormatters: [
                                NoLeadingSpaceFormatter(),
                                LengthLimitingTextInputFormatter(10)
                              ],
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                              decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1)),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1)),
                                  prefix: SizedBox(
                                    width: 10,
                                  ),
                                  hintText: widget.playWithComputer
                                      ? 'You'
                                      : 'Player 2',
                                  hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                  labelStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: Get.width / 4,
                ),
                InkWell(
                  onTap: () async {
                    if (Utility.volume == true) {
                      Uri uri = Uri.parse("asset:///assets/music/start.mp3");
                      await player.setUrl(uri.toString());
                      player.play();
                    }

                    FocusManager.instance.primaryFocus?.unfocus();
                    Get.to(() => GameScreen(
                          playWithComputer: widget.playWithComputer,
                          player1: player1Controller.text.isEmpty
                              ? widget.playWithComputer
                                  ? "Computer"
                                  : "Player 1"
                              : player1Controller.text,
                          player2: player2Controller.text.isEmpty
                              ? widget.playWithComputer
                                  ? 'You'
                                  : 'Player 2'
                              : player2Controller.text,
                        ));
                  },
                  child: Image.asset(
                    'assets/images/playButton.png',
                    height: Get.height * 0.15,
                  ),
                ),
                const Text(
                  'Are you up for the challenge?',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 14),
                ),
                SizedBox(
                  height: 5,
                ),
                const Text(
                  "Let's Play!",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

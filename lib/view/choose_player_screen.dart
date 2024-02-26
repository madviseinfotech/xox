// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xo/view/gameScreen.dart';
import 'package:xo/view/service.dart';

import '../utils/utility.dart';
import 'enter_player_screen.dart';

class ChoosePlayerScreen extends StatefulWidget {
  const ChoosePlayerScreen({Key? key}) : super(key: key);

  @override
  State<ChoosePlayerScreen> createState() => _ChoosePlayerScreenState();
}

class _ChoosePlayerScreenState extends State<ChoosePlayerScreen> {
  TextEditingController player1Controller = TextEditingController();
  TextEditingController player2Controller = TextEditingController();
  String select = "computer";

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayer();
    // Create a player

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
                    Expanded(
                      child: Column(
                        children: const [
                          Text(
                            'Choose one',
                            style: TextStyle(
                                color: Color(0xff37E9BB),
                                fontWeight: FontWeight.bold,
                                fontSize: 30),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Unleash Your Competitive Spirit in Multiplayer Battles!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                          ),
                        ],
                      ),
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
                InkWell(
                  onTap: () {
                    setState(() {
                      select = "computer";
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment(0.8, 1),
                        colors: <Color>[
                          select == "computer"
                              ? Color(0xffE06340)
                              : Color(0xff32167D),
                          select == "computer"
                              ? Color(0xffFFAD6B)
                              : Color(0xff32167D),
                        ], // Gradient from https://learnui.design/tools/gradient-generator.html
                        tileMode: TileMode.mirror,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: Get.height * 0.065,
                        width: Get.width,
                        child: Container(
                          decoration: BoxDecoration(
                              border: select == "computer"
                                  ? Border.all(color: Colors.white, width: 1)
                                  : null,
                              borderRadius: BorderRadius.circular(30)),
                          child: Center(
                              child: Text(
                            "With Computer",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: Get.height * 0.03,
                ),

                ///player2

                InkWell(
                  onTap: () {
                    setState(() {
                      select = "player";
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment(0.8, 1),
                        colors: <Color>[
                          select == "player"
                              ? Color(0xffFE439E)
                              : Color(0xff32167D),
                          select == "player"
                              ? Color(0xffFF55BF)
                              : Color(0xff32167D),
                        ], // Gradient from https://learnui.design/tools/gradient-generator.html
                        tileMode: TileMode.mirror,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: Get.height * 0.065,
                        width: Get.width,
                        child: Container(
                          decoration: BoxDecoration(
                              border: select == "player"
                                  ? Border.all(color: Colors.white, width: 1)
                                  : null,
                              borderRadius: BorderRadius.circular(30)),
                          child: Center(
                              child: Text(
                            "With Player",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: Get.width / 2,
                ),
                InkWell(
                  onTap: () async {
                    if (Utility.volume == true) {
                      Uri uri = Uri.parse("asset:///assets/music/start.mp3");
                      await player.setUrl(uri.toString());
                      player.play();
                    }
                    if (select == "computer") {
                      Get.to(() => EnterPlayerScreen(
                            playWithComputer: true,
                          ));
                    } else {
                      Get.to(() => EnterPlayerScreen(
                            playWithComputer: false,
                          ));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment(0.8, 1),
                        colors: <Color>[
                          Color(0xff159F9C),
                          Color(0xff2AD2B4),
                        ], // Gradient from https://learnui.design/tools/gradient-generator.html
                        tileMode: TileMode.mirror,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: Get.height * 0.060,
                        width: Get.width,
                        child: Center(
                            child: Text(
                          "Next",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

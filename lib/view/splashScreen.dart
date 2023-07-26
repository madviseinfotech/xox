import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dashBoardScreen.dart';
import 'enter_player_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: 'assets/images/board.png',
      nextScreen: DashBoardScreen(),
      backgroundColor: Color(0xff1F1147),
      duration: 3000,
      splashIconSize: Get.height * 0.2,
      animationDuration: Duration(seconds: 2),
      splashTransition: SplashTransition.rotationTransition,
    );
    // return Scaffold(
    //   body: Stack(
    //     children: [
    //       Image.asset(
    //         'assets/images/splashBg.png',
    //         height: Get.height,
    //         width: Get.width,
    //         fit: BoxFit.cover,
    //       ),
    //       Positioned(
    //         top: Get.height * 0.1,
    //         child: SizedBox(
    //           width: Get.width,
    //           child: Center(
    //             child: Image.asset(
    //               'assets/images/xox.png',
    //               height: Get.height * 0.1,
    //             ),
    //           ),
    //         ),
    //       ),
    //       Positioned(
    //         top: Get.height / 2 - 40,
    //         child: SizedBox(
    //           width: Get.width,
    //           child: Center(
    //             child: Image.asset(
    //               'assets/images/board.png',
    //               height: Get.height * 0.2,
    //             ),
    //           ),
    //         ),
    //       )
    //     ],
    //   ),
    // );
  }
}

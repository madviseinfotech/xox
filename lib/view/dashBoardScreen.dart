import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xox_madvise/utils/utility.dart';

import 'choose_player_screen.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({Key? key}) : super(key: key);

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  @override
  void initState() {
    checkAppUpdate(context);
    initData();
    // TODO: implement initState
    super.initState();
  }

  initData() async {
    if (Utility.volume == true) {
      Uri uri = Uri.parse("asset:///assets/music/start.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }
  }

  final player = AudioPlayer(); // Create a player
  @override
  void dispose() {
    // TODO: implement dispose
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/splash.jpg',
            height: Get.height,
            width: Get.width,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: Get.width * 0.14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/xox.png',
                  fit: BoxFit.cover,
                  height: Get.width / 5,
                ),
                SizedBox(height: Get.width / 8),
                Image.asset(
                  'assets/images/board.png',
                  fit: BoxFit.cover,
                  height: Get.width / 2.5,
                ),
                SizedBox(height: Get.width / 8),
                SizedBox(
                  width: Get.width,
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'XOX Mania: Unleash the Challenge!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: Get.width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Get.width * 0.08,
                      vertical: Get.width * 0.1,
                    ),
                    child: InkWell(
                      onTap: () async {
                        if (Utility.volume == true) {
                          Uri uri = Uri.parse(
                            "asset:///assets/music/begin.mp3",
                          );
                          await player.setUrl(uri.toString());
                          player.play();
                        }

                        Get.to(() => const ChoosePlayerScreen());
                      },
                      child: Image.asset(
                        'assets/images/startButton.png',
                        // height: Get.height * 0.05,
                        width: Get.width,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
          // Positioned(
          //   bottom: Get.width / 9,
          //   child: SizedBox(
          //     width: Get.width,
          //     child: Padding(
          //       padding: EdgeInsets.symmetric(
          //         horizontal: Get.width * 0.08,
          //       ),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           SizedBox(
          //             // width: Get.width,
          //             height: Get.width * 0.15,
          //             child: InkWell(
          //               onTap: () {
          //                 Share.share(
          //                     "let's have fun with XOX https://play.google.com/store/apps/details?id=com.xox.madvise",
          //                     subject: "Let's Play!!");
          //               },
          //               child: Image.asset(
          //                 'assets/images/share.png',
          //                 // height: Get.height * 0.05,
          //                 // width: Get.width,
          //                 fit: BoxFit.cover,
          //               ),
          //             ),
          //           ),
          //           SizedBox(
          //             // width: Get.width,
          //             height: Get.width * 0.15,
          //             child: InkWell(
          //               onTap: () async {
          //                 if (Utility.volume == false) {
          //                   Uri uri =
          //                       Uri.parse("asset:///assets/music/Click.mp3");
          //                   await player.setUrl(uri.toString());
          //                   player.play();
          //                 }
          //
          //                 setState(() {
          //                   Utility.volume = !Utility.volume;
          //                 });
          //               },
          //               child: Image.asset(
          //                 Utility.volume
          //                     ? 'assets/images/soundButton.png'
          //                     : 'assets/images/unmute.png',
          //                 // height: Get.height * 0.05,
          //                 // width: Get.width,
          //                 fit: BoxFit.cover,
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      bottomNavigationBar: Container(
        width: Get.width,
        color: Color(0xff1F1147),
        child: Padding(
          padding: EdgeInsets.only(
            left: Get.width * 0.08,
            right: Get.width * 0.08,
            bottom: Get.width * 0.08,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                // width: Get.width,
                height: Get.width * 0.15,
                child: InkWell(
                  onTap: () {
                    Share.share(
                      "let's have fun with XOX https://play.google.com/store/apps/details?id=com.xox.madvise",
                      subject: "Let's Play!!",
                    );
                  },
                  child: Image.asset(
                    'assets/images/share.png',
                    // height: Get.height * 0.05,
                    // width: Get.width,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                // width: Get.width,
                height: Get.width * 0.15,
                child: InkWell(
                  onTap: () async {
                    if (Utility.volume == false) {
                      Uri uri = Uri.parse("asset:///assets/music/Click.mp3");
                      await player.setUrl(uri.toString());
                      player.play();
                    }

                    setState(() {
                      Utility.volume = !Utility.volume;
                    });
                  },
                  child: Image.asset(
                    Utility.volume
                        ? 'assets/images/soundButton.png'
                        : 'assets/images/unmute.png',
                    // height: Get.height * 0.05,
                    // width: Get.width,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String> getCurrentAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version.replaceAll('.', '');
}

Future<void> checkAppUpdate(BuildContext context) async {
  String currentVersion = await getCurrentAppVersion();
  print("currentVersion == ${currentVersion}");

  // Replace 'app_version' with your actual collection name
  try {
    DocumentSnapshot versionSnapshot = await FirebaseFirestore.instance
        .collection('app_version')
        .doc('version_info')
        .get();

    Map<String, dynamic> version =
        versionSnapshot.data() as Map<String, dynamic>;
    int latestVersion = int.parse(
      version['current_version'].toString().replaceAll('.', ''),
    );

    print("latestVersion === ${latestVersion}");

    // if (currentVersion != latestVersion) {
    if (latestVersion > int.parse(currentVersion)) {
      showUpdateDialog(context);
      // Show the update dialog here
    }
  } catch (e) {
    print("ERROR ==> $e");
  }
}

Future<void> showUpdateDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // Prevent dismissing the dialog on tap outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Update Available'),
        content: Text(
          'A new version of the app is available. Please update to the latest version to continue.',
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Update Now'),
            onPressed: () {
              _launchUrl(
                "https://play.google.com/store/apps/details?id=com.xox.madvise",
              );
            },
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

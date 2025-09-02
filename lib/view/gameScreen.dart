// // ignore_for_file: prefer_const_constructors
//
// import 'dart:async';
// import 'dart:developer' as logg;
// import 'dart:math';
//
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:just_audio/just_audio.dart';
//
// import '../utils/utility.dart';
// import 'ad_helper.dart';
//
// class GameScreen extends StatefulWidget {
//   final String? player1;
//   final String? player2;
//   final bool playWithComputer;
//   const GameScreen({
//     super.key,
//     this.player1,
//     this.player2,
//     this.playWithComputer = false,
//   });
//
//   @override
//   _GameScreenState createState() => _GameScreenState();
// }
//
// class _GameScreenState extends State<GameScreen> {
//   // final adIntUnitId = 'ca-app-pub-3940256099942544/1033173712'; test
//   final adIntUnitId = 'ca-app-pub-1815279805478806/1864352912';
//   InterstitialAd? _interstitialAd;
//   ConnectivityResult _connectionStatus = ConnectivityResult.none;
//   final Connectivity _connectivity = Connectivity();
//   late StreamSubscription<ConnectivityResult> _connectivitySubscription;
//   BannerAd? _ad;
//   final player = AudioPlayer(); // Create a player
//   // declarations
//   bool oTurn = true;
//   bool ignoreBoard = false;
//   // 1st player is O
//   List<String> displayElement = ['', '', '', '', '', '', '', '', ''];
//   List<int> winnerElement = [];
//   int oScore = 0;
//   int xScore = 0;
//   int filledBoxes = 0;
//
//   @override
//   void initState() {
//     initConnectivity();
//     getConnectivity();
//     // TODO: Load a banner ad
//     BannerAd(
//       adUnitId: AdHelper.bannerAdUnitId,
//       size: AdSize.banner,
//       request: AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           setState(() {
//             _ad = ad as BannerAd;
//             print("-----INIT ADD--$_ad");
//           });
//         },
//         onAdFailedToLoad: (ad, error) {
//           // Releases an ad resource when it fails to load
//           ad.dispose();
//           // print('Ad load failed (code=${error.code} message=${error.message})');
//         },
//       ),
//     ).load();
//     print("-----INIT ADD--$_ad");
//     loadInterstitialAd();
//     // TODO: implement initState
//
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     _ad?.dispose();
//     _connectivitySubscription.cancel();
//     _interstitialAd?.dispose();
//     player.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         // print('_connectionStatus--${_connectionStatus.toString()}');
//         if (_connectionStatus.toString() != "ConnectivityResult.none") {
//           // print('here is');
//           await _interstitialAd!.show().then((value) => Get.back());
//
//           if (Utility.volume == true) {
//             Uri uri = Uri.parse("asset:///assets/music/Click.mp3");
//             await player.setUrl(uri.toString());
//             player.play();
//           }
//         } else {
//           Get.back();
//           if (Utility.volume == true) {
//             Uri uri = Uri.parse("asset:///assets/music/Click.mp3");
//             await player.setUrl(uri.toString());
//             player.play();
//           }
//         }
//         return true;
//       },
//       child: Scaffold(
//         body: Stack(
//           children: [
//             ///bg image
//             Container(
//               height: Get.height,
//               width: Get.width,
//               decoration: BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage('assets/images/enterPlayerBg.png'),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 SizedBox(height: 20),
//                 Text(_ad.toString(), style: TextStyle(color: Colors.white)),
//                 if (_ad != null)
//                   Align(
//                     alignment: Alignment.center,
//                     child: Container(
//                       width: _ad!.size.width.toDouble(),
//                       height: 72.0,
//                       alignment: Alignment.center,
//                       child: AdWidget(ad: _ad!),
//                     ),
//                   ),
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: GestureDetector(
//                     onTap: () async {
//                       // print(
//                       //     '_connectionStatus--${_connectionStatus.toString()}');
//                       if (_connectionStatus.toString() !=
//                           "ConnectivityResult.none") {
//                         // print('here is');
//                         await _interstitialAd!.show().then(
//                           (value) => Get.back(),
//                         );
//
//                         if (Utility.volume == true) {
//                           Uri uri = Uri.parse(
//                             "asset:///assets/music/Click.mp3",
//                           );
//                           await player.setUrl(uri.toString());
//                           player.play();
//                         }
//                       } else {
//                         Get.back();
//                         if (Utility.volume == true) {
//                           Uri uri = Uri.parse(
//                             "asset:///assets/music/Click.mp3",
//                           );
//                           await player.setUrl(uri.toString());
//                           player.play();
//                         }
//                       }
//                     },
//                     child: CircleAvatar(
//                       radius: 20,
//                       backgroundColor: Color(0xff32167D),
//                       child: Icon(
//                         Icons.arrow_back_outlined,
//                         size: 30,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//                 playerDetails(),
//                 gamingBoard(),
//                 bottomBar(),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Padding bottomBar() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 30),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           InkWell(
//             onTap: () {
//               bool allEmpty = displayElement.every(
//                 (element) => element.isEmpty,
//               );
//               // print("winnerElement == $winnerElement");
//               if (!allEmpty) {
//                 _clearBoard();
//               }
//             },
//             child: Image.asset(
//               'assets/images/undoButton.png',
//               height: Get.height * 0.08,
//             ),
//           ),
//           InkWell(
//             onTap: () {
//               bool allEmpty = displayElement.every(
//                 (element) => element.isEmpty,
//               );
//               if (!allEmpty) {
//                 _clearScoreBoard();
//               }
//             },
//             child: Image.asset(
//               'assets/images/restartButton.png',
//               height: Get.height * 0.08,
//             ),
//           ),
//           InkWell(
//             onTap: () async {
//               if (Utility.volume == false) {
//                 Uri uri = Uri.parse("asset:///assets/music/Click.mp3");
//                 await player.setUrl(uri.toString());
//                 player.play();
//               }
//
//               setState(() {
//                 Utility.volume = !Utility.volume;
//               });
//             },
//             child: Image.asset(
//               Utility.volume
//                   ? 'assets/images/soundButton.png'
//                   : 'assets/images/unmute.png',
//               height: Get.height * 0.08,
//               // width: Get.width,
//               fit: BoxFit.cover,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget gamingBoard() {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//         child: GridView.builder(
//           physics: NeverScrollableScrollPhysics(),
//           itemCount: 9,
//           shrinkWrap: true,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3,
//             childAspectRatio: 1.15,
//           ),
//           itemBuilder: (BuildContext context, int index) {
//             return GestureDetector(
//               onTap: () {
//                 if (ignoreBoard == false) {
//                   if (displayElement[index].isEmpty) {
//                     _tapped(index);
//                   }
//                 }
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Color(0xff2C136F),
//                   borderRadius: BorderRadius.circular(10),
//                   boxShadow: [
//                     BoxShadow(
//                       blurRadius: 5,
//                       color: Colors.white.withOpacity(0.3),
//                       offset: Offset(0, 0),
//                     ),
//                   ],
//                   border: Border.all(
//                     color: winnerElement.contains(index)
//                         ? Color(0xffF7E96D)
//                         : Colors.white,
//                     width: 2,
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     displayElement[index],
//                     style: TextStyle(
//                       color: winnerElement.contains(index)
//                           ? Color(0xffF7E96D)
//                           : displayElement[index] == 'X'
//                           ? Color(0xff37E9BB)
//                           : Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: winnerElement.contains(index) ? 70 : 60,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Row playerDetails() {
//     return Row(
//       children: [
//         ///player 1
//         Expanded(
//           flex: 1,
//           child: SizedBox(
//             height: Get.width * 0.21,
//             child: Stack(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 12),
//                   child: Container(
//                     height: Get.width * 0.18,
//                     width: Get.width,
//                     decoration: BoxDecoration(
//                       color: Color(0xff5837B1),
//                       borderRadius: BorderRadius.only(
//                         topRight: Radius.circular(30),
//                         bottomRight: Radius.circular(30),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 12),
//                   child: Container(
//                     width: Get.width,
//                     height: Get.width * 0.15,
//                     decoration: BoxDecoration(
//                       color: Color(0xff2C136F),
//                       borderRadius: BorderRadius.only(
//                         topRight: Radius.circular(30),
//                         bottomRight: Radius.circular(30),
//                       ),
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 10),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               widget.player1!,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 width: 3,
//                                 color: oTurn == true
//                                     ? Colors.transparent
//                                     : Colors.red,
//                               ),
//                             ),
//                             child: Image.asset(
//                               'assets/images/player1.png',
//                               height: oTurn == true
//                                   ? Get.height * 0.04
//                                   : Get.height * 0.05,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   left: 20,
//                   bottom: 0,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(3),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Image.asset('assets/images/star.png', height: 15),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 10),
//                             child: Text(
//                               xScore.toString(),
//                               style: TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 10,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: 0,
//                   right: Get.width / 4,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: const [
//                       Text(
//                         'X',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 10),
//           child: Center(
//             child: Image.asset(
//               'assets/images/vs.png',
//               height: Get.height * 0.06,
//             ),
//           ),
//         ),
//
//         ///player 2
//         Expanded(
//           flex: 1,
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 12),
//                 child: Container(
//                   height: Get.width * 0.18,
//                   width: Get.width,
//                   decoration: BoxDecoration(
//                     color: Color(0xff5837B1),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       bottomLeft: Radius.circular(30),
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(top: 12),
//                 child: Container(
//                   width: Get.width,
//                   height: Get.width * 0.15,
//                   decoration: BoxDecoration(
//                     color: Color(0xff2C136F),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       bottomLeft: Radius.circular(30),
//                     ),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 10),
//                     child: Row(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               width: 3,
//                               color: oTurn == false
//                                   ? Colors.transparent
//                                   : Colors.red,
//                             ),
//                           ),
//                           child: Image.asset(
//                             'assets/images/player2.png',
//                             height: oTurn == false
//                                 ? Get.height * 0.04
//                                 : Get.height * 0.045,
//                           ),
//                         ),
//                         SizedBox(width: 10),
//                         Expanded(
//                           child: Align(
//                             alignment: Alignment.centerRight,
//                             child: Text(
//                               widget.player2!,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: 20,
//                 bottom: 0,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(3),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Image.asset('assets/images/star.png', height: 15),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           child: Text(
//                             oScore.toString(),
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: 0,
//                 left: Get.width / 4,
//                 child: const Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'O',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   // filling the boxes when tapped with X
//   // or O respectively and then checking the winner function
//   _tapped(int index) async {
//     // print("_tapped No==$index");
//     setState(() {
//       if (oTurn && displayElement[index] == '') {
//         displayElement[index] = 'O';
//         filledBoxes++;
//
//         if (widget.playWithComputer == true) {
//           setState(() {
//             ignoreBoard = true;
//           });
//           Future.delayed(Duration(seconds: 2), () {
//             //if (ignoreBoard == false) {
//             randomNumberGenerate();
//             //}
//           });
//         }
//       } else if (!oTurn && displayElement[index] == '') {
//         displayElement[index] = 'X';
//         filledBoxes++;
//       }
//       oTurn = !oTurn;
//       _checkWinner();
//     });
//   }
//
//   Future<void> _checkWinner() async {
//     if (Utility.volume == true) {
//       Uri uri = Uri.parse("asset:///assets/music/Click.mp3");
//       await player.setUrl(uri.toString());
//       player.play();
//     }
//     // Checking rows
//     if (displayElement[0] == displayElement[1] &&
//         displayElement[0] == displayElement[2] &&
//         displayElement[0] != '') {
//       winnerElement.clear();
//       winnerElement.add(0);
//       winnerElement.add(1);
//       winnerElement.add(2);
//       setState(() {
//         ignoreBoard = true;
//       });
//       if (displayElement[0] == 'O') {
//         oScore++;
//       } else if (displayElement[0] == 'X') {
//         xScore++;
//       }
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//         await _showWinDialog(displayElement[0]);
//         _clearBoard();
//       });
//     } else if (displayElement[3] == displayElement[4] &&
//         displayElement[3] == displayElement[5] &&
//         displayElement[3] != '') {
//       winnerElement.add(3);
//       winnerElement.add(4);
//       winnerElement.add(5);
//
//       if (displayElement[3] == 'O') {
//         oScore++;
//       } else if (displayElement[3] == 'X') {
//         xScore++;
//       }
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//         await _showWinDialog(displayElement[3]);
//         _clearBoard();
//       });
//     } else if (displayElement[6] == displayElement[7] &&
//         displayElement[6] == displayElement[8] &&
//         displayElement[6] != '') {
//       winnerElement.add(6);
//       winnerElement.add(7);
//       winnerElement.add(8);
//       setState(() {
//         ignoreBoard = true;
//       });
//       if (displayElement[6] == 'O') {
//         oScore++;
//       } else if (displayElement[6] == 'X') {
//         xScore++;
//       }
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//
//         await _showWinDialog(displayElement[6]);
//         _clearBoard();
//       });
//     }
//     // Checking Column
//     else if (displayElement[0] == displayElement[3] &&
//         displayElement[0] == displayElement[6] &&
//         displayElement[0] != '') {
//       winnerElement.add(0);
//       winnerElement.add(3);
//       winnerElement.add(6);
//
//       setState(() {
//         ignoreBoard = true;
//       });
//       if (displayElement[0] == 'O') {
//         oScore++;
//       } else if (displayElement[0] == 'X') {
//         xScore++;
//       }
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//
//         await _showWinDialog(displayElement[0]);
//         _clearBoard();
//       });
//     } else if (displayElement[1] == displayElement[4] &&
//         displayElement[1] == displayElement[7] &&
//         displayElement[1] != '') {
//       winnerElement.add(1);
//       winnerElement.add(4);
//       winnerElement.add(7);
//       if (displayElement[1] == 'O') {
//         oScore++;
//       } else if (displayElement[1] == 'X') {
//         xScore++;
//       }
//       setState(() {
//         ignoreBoard = true;
//       });
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//
//         await _showWinDialog(displayElement[1]);
//         _clearBoard();
//       });
//     } else if (displayElement[2] == displayElement[5] &&
//         displayElement[2] == displayElement[8] &&
//         displayElement[2] != '') {
//       winnerElement.add(2);
//       winnerElement.add(5);
//       winnerElement.add(8);
//       setState(() {
//         ignoreBoard = true;
//       });
//       if (displayElement[2] == 'O') {
//         oScore++;
//       } else if (displayElement[2] == 'X') {
//         xScore++;
//       }
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//
//         await _showWinDialog(displayElement[2]);
//         _clearBoard();
//       });
//     }
//     // Checking Diagonal
//     else if (displayElement[0] == displayElement[4] &&
//         displayElement[0] == displayElement[8] &&
//         displayElement[0] != '') {
//       winnerElement.add(0);
//       winnerElement.add(4);
//       winnerElement.add(8);
//       setState(() {
//         ignoreBoard = true;
//       });
//       if (displayElement[0] == 'O') {
//         oScore++;
//       } else if (displayElement[0] == 'X') {
//         xScore++;
//       }
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//         _clearBoard();
//         await _showWinDialog(displayElement[0]);
//       });
//     } else if (displayElement[2] == displayElement[4] &&
//         displayElement[2] == displayElement[6] &&
//         displayElement[2] != '') {
//       winnerElement.add(2);
//       winnerElement.add(4);
//       winnerElement.add(6);
//       setState(() {
//         ignoreBoard = true;
//       });
//       if (displayElement[2] == 'O') {
//         oScore++;
//       } else if (displayElement[2] == 'X') {
//         xScore++;
//       }
//       if (Utility.volume == true) {
//         Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
//         await player.setUrl(uri.toString());
//         player.play();
//       }
//       Future.delayed(Duration(seconds: 1), () async {
//         setState(() {
//           ignoreBoard = false;
//         });
//
//         await _showWinDialog(displayElement[2]);
//         _clearBoard();
//       });
//     } else if (filledBoxes == 9) {
//       winnerElement.clear();
//       setState(() {
//         ignoreBoard = true;
//       });
//       //   drawDialog();
//       //
//       Future.delayed(Duration(seconds: 1), () {
//         setState(() {
//           ignoreBoard = false;
//         });
//         _clearBoard();
//       });
//       //
//       // if (Utility.volume == true) {
//       //   Uri uri = Uri.parse("asset:///assets/music/loose.mp3");
//       //   await player.setUrl(uri.toString());
//       //   player.play();
//       // }
//     }
//   }
//
//   _showWinDialog(String winner) {
//     setState(() {
//       ignoreBoard = true;
//     });
//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (BuildContext context) {
//         // return AlertDialog(
//         //   title: Text("\" " + winner + " \" is Winner!!!"),
//         //   actions: [
//         //     ElevatedButton(
//         //       child: Text("Play Again"),
//         //       onPressed: () {
//         //         _clearBoard();
//         //         Navigator.of(context).pop();
//         //       },
//         //     )
//         //   ],
//         // );
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: Stack(
//             children: [
//               Container(
//                 height: Get.height * 0.3,
//                 decoration: BoxDecoration(
//                   color: Colors.transparent,
//                   image: DecorationImage(
//                     image: AssetImage('assets/images/winnerDialog.png'),
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     '${winner.toUpperCase() == 'X' ? widget.player1.toString().toUpperCase() : widget.player2.toString().toUpperCase()} WON MATCH!!',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 left: 0,
//                 child: SizedBox(
//                   width: Get.width,
//                   child: Center(
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(30),
//                       onTap: () async {
//                         _clearBoard();
//                         setState(() {
//                           ignoreBoard = false;
//                         });
//                         Navigator.of(context).pop();
//
//                         // final snackBar = SnackBar(
//                         //   backgroundColor: Color(0xff5837B1),
//                         //   duration: Duration(seconds: 3),
//                         //   content: Text(
//                         //     "${winner.toUpperCase() == 'X' ? widget.player2 : widget.player1} it's your turn now!!",
//                         //     style: TextStyle(
//                         //         color: Colors.white,
//                         //         fontWeight: FontWeight.bold,
//                         //         fontSize: 18),
//                         //   ),
//                         // );
//                         // ScaffoldMessenger.of(context).showSnackBar(snackBar);
//
//                         // Find the ScaffoldMessenger in the widget tree
//                         // and use it to show a SnackBar.
//
//                         // if (oTurn == false) {
//                         //   if (widget.isComputer == true) {
//                         //     Future.delayed(Duration(seconds: 2), () {
//                         //       if (ignoreBoard == false) {
//                         //         randomNumberGenerate();
//                         //       }
//                         //     });
//                         //   }
//                         // }
//                       },
//                       child: Image.asset(
//                         'assets/images/cancelButton.png',
//                         height: Get.height * 0.12,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   void drawDialog() {
//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 height: Get.height,
//                 width: Get.width,
//                 decoration: BoxDecoration(
//                   color: Colors.transparent,
//                   image: DecorationImage(
//                     image: AssetImage('assets/images/winnerDialog.png'),
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     'Match Draw',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                 ),
//               ),
//               InkWell(
//                 onTap: () {
//                   _clearBoard();
//                   Navigator.of(context).pop();
//                 },
//                 child: Image.asset(
//                   'assets/images/cancelButton.png',
//                   height: 120,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   _clearBoard() async {
//     setState(() {
//       ignoreBoard = false;
//     });
//     winnerElement.clear();
//     if (Utility.volume == true) {
//       Uri uri = Uri.parse("asset:///assets/music/undo.mp3");
//       await player.setUrl(uri.toString());
//       player.play();
//     }
//
//     setState(() {
//       for (int i = 0; i < 9; i++) {
//         displayElement[i] = '';
//       }
//       oTurn = true;
//     });
//
//     filledBoxes = 0;
//   }
//
//   void _clearScoreBoard() async {
//     winnerElement.clear();
//
//     final snackBar = SnackBar(
//       backgroundColor: Color(0xff5837B1),
//       duration: Duration(seconds: 3),
//       content: Text(
//         "Restart your Game now!!",
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 18,
//         ),
//       ),
//     );
//
//     // Find the ScaffoldMessenger in the widget tree
//     // and use it to show a SnackBar.
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     if (Utility.volume == true) {
//       Uri uri = Uri.parse("asset:///assets/music/refresh.mp3");
//       await player.setUrl(uri.toString());
//       player.play();
//     }
//
//     setState(() {
//       xScore = 0;
//       oScore = 0;
//       for (int i = 0; i < 9; i++) {
//         displayElement[i] = '';
//       }
//     });
//     filledBoxes = 0;
//   }
//
//   // Start listening (call this in initState or wherever you were calling getConnectivity)
//   void getConnectivity() {
//     // onConnectivityChanged now emits List<ConnectivityResult>;
//     // map it back to a single value to keep your existing flow unchanged.
//     _connectivitySubscription = _connectivity.onConnectivityChanged
//         .map(
//           (results) =>
//               results.isNotEmpty ? results.first : ConnectivityResult.none,
//         )
//         .listen(_updateConnectionStatus);
//   }
//
//   // Initial check (updated for List<ConnectivityResult>)
//   Future<void> initConnectivity() async {
//     try {
//       final results = await _connectivity.checkConnectivity();
//       final result = results.isNotEmpty
//           ? results.first
//           : ConnectivityResult.none;
//
//       if (!mounted) return;
//       await _updateConnectionStatus(result);
//     } on PlatformException catch (e) {
//       // log your error if you want
//       // log('Couldn\'t check connectivity status', error: e);
//     }
//   }
//
//   // getConnectivity() async {
//   //   _connectivitySubscription =
//   //       _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
//   // }
//   //
//   // Future<void> initConnectivity() async {
//   //   late ConnectivityResult result;
//   //   // Platform messages may fail, so we use a try/catch PlatformException.
//   //   try {
//   //     result = await _connectivity.checkConnectivity();
//   //   } on PlatformException catch (e) {
//   //     // logg.log('Couldn\'t check connectivity status', error: e);
//   //     return;
//   //   }
//   //
//   //   // If the widget was removed from the tree while the asynchronous platform
//   //   // message was in flight, we want to discard the reply rather than calling
//   //   // setState to update our non-existent appearance.
//   //   if (!mounted) {
//   //     return Future.value(null);
//   //   }
//   //
//   //   return _updateConnectionStatus(result);
//   // }
//
//   Future<void> _updateConnectionStatus(ConnectivityResult result) async {
//     setState(() {
//       _connectionStatus = result;
//     });
//     // print("Connection Status: ${_connectionStatus.toString()}");
//   }
//
//   void loadInterstitialAd() {
//     InterstitialAd.load(
//       adUnitId: adIntUnitId,
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         // Called when an ad is successfully received.
//         onAdLoaded: (ad) {
//           // debugPrint('$ad loaded.');
//           // Keep a reference to the ad so you can show it later.
//           _interstitialAd = ad;
//         },
//         // Called when an ad request failed.
//         onAdFailedToLoad: (LoadAdError error) {
//           // debugPrint('InterstitialAd failed to load: $error');
//         },
//       ),
//     );
//   }
//
//   randomNumberGenerate() {
//     Random random = Random();
//     int randomNumber = 0;
//     randomNumber = random.nextInt(9);
//     // print('randomNumber=====$randomNumber');
//     if (displayElement[randomNumber] == '' && oTurn == false) {
//       _tapped(randomNumber);
//     } else {
//       randomNumberGenerate();
//     }
//     ignoreBoard = false;
//     setState(() {});
//   }
// }
// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/utility.dart';
import 'ad_helper.dart';

class GameScreen extends StatefulWidget {
  final String? player1;
  final String? player2;
  final bool playWithComputer;
  const GameScreen({
    super.key,
    this.player1,
    this.player2,
    this.playWithComputer = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // ---------------- Ads ----------------
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  InterstitialAd? _interstitialAd;
  final String _interstitialUnitId = 'ca-app-pub-1815279805478806/1864352912';

  // ---------------- Connectivity ----------------
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // ---------------- Audio ----------------
  final player = AudioPlayer();

  // ---------------- Game State ----------------
  bool oTurn = true; // O plays first
  bool ignoreBoard = false;
  final List<String> displayElement = List.filled(9, '');
  final List<int> winnerElement = [];
  int oScore = 0;
  int xScore = 0;
  int filledBoxes = 0;

  // --------------- Lifecycle ---------------
  @override
  void initState() {
    super.initState();

    // Connectivity
    _initConnectivity();
    _listenConnectivity();

    // Ads
    _loadBanner();
    _loadInterstitial();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _connectivitySubscription.cancel();
    player.dispose();
    super.dispose();
  }

  // --------------- Build ---------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackWithAd,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              height: Get.height,
              width: Get.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/enterPlayerBg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 20),
                // Banner (render only when ready)
                if (_isBannerReady && _bannerAd != null)
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                // Back btn
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _onBackPress,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xff32167D),
                      child: Icon(
                        Icons.arrow_back_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _playerDetails(),
                _gamingBoard(),
                _bottomBar(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------- Widgets ---------------
  Padding _bottomBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () {
              final allEmpty = displayElement.every((e) => e.isEmpty);
              if (!allEmpty) _clearBoard();
            },
            child: Image.asset(
              'assets/images/undoButton.png',
              height: Get.height * 0.08,
            ),
          ),
          InkWell(
            onTap: () {
              final allEmpty = displayElement.every((e) => e.isEmpty);
              if (!allEmpty) _clearScoreBoard();
            },
            child: Image.asset(
              'assets/images/restartButton.png',
              height: Get.height * 0.08,
            ),
          ),
          InkWell(
            onTap: () async {
              if (!Utility.volume) {
                final uri = Uri.parse("asset:///assets/music/Click.mp3");
                await player.setUrl(uri.toString());
                player.play();
              }
              setState(() => Utility.volume = !Utility.volume);
            },
            child: Image.asset(
              Utility.volume
                  ? 'assets/images/soundButton.png'
                  : 'assets/images/unmute.png',
              height: Get.height * 0.08,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gamingBoard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemCount: 9,
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final isWinnerCell = winnerElement.contains(index);
            final value = displayElement[index];
            return GestureDetector(
              onTap: () {
                if (!ignoreBoard && value.isEmpty) _tapped(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xff2C136F),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 5,
                      color: Colors.white.withOpacity(0.3),
                      offset: Offset(0, 0),
                    ),
                  ],
                  border: Border.all(
                    color: isWinnerCell ? Color(0xffF7E96D) : Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isWinnerCell
                          ? Color(0xffF7E96D)
                          : value == 'X'
                          ? Color(0xff37E9BB)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isWinnerCell ? 70 : 60,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Row _playerDetails() {
    return Row(
      children: [
        // Player 1 (X)
        Expanded(
          child: SizedBox(
            height: Get.width * 0.21,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: Get.width * 0.18,
                    decoration: BoxDecoration(
                      color: Color(0xff5837B1),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: Get.width * 0.15,
                    decoration: BoxDecoration(
                      color: Color(0xff2C136F),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.player1 ?? 'Player 1',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 3,
                                color: oTurn ? Colors.transparent : Colors.red,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/player1.png',
                              height: oTurn
                                  ? Get.height * 0.04
                                  : Get.height * 0.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/star.png', height: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              xScore.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: Get.width / 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'X',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            child: Image.asset(
              'assets/images/vs.png',
              height: Get.height * 0.06,
            ),
          ),
        ),

        // Player 2 (O)
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  height: Get.width * 0.18,
                  decoration: BoxDecoration(
                    color: Color(0xff5837B1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  height: Get.width * 0.15,
                  decoration: BoxDecoration(
                    color: Color(0xff2C136F),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 3,
                              color: !oTurn ? Colors.transparent : Colors.red,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/player2.png',
                            height: !oTurn
                                ? Get.height * 0.04
                                : Get.height * 0.045,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              widget.player2 ?? 'Player 2',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/star.png', height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            oScore.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: Get.width / 4,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'O',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------- Game Logic ---------------
  Future<void> _tapped(int index) async {
    setState(() {
      if (oTurn && displayElement[index].isEmpty) {
        displayElement[index] = 'O';
        filledBoxes++;
        if (widget.playWithComputer) {
          ignoreBoard = true;
          Future.delayed(Duration(seconds: 2), () => _botMove());
        }
      } else if (!oTurn && displayElement[index].isEmpty) {
        displayElement[index] = 'X';
        filledBoxes++;
      }
      oTurn = !oTurn;
    });
    await _checkWinner();
  }

  Future<void> _checkWinner() async {
    if (Utility.volume) {
      final uri = Uri.parse("asset:///assets/music/Click.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }

    // Winning lines
    final wins = <List<int>>[
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final line in wins) {
      final a = line[0], b = line[1], c = line[2];
      final v = displayElement[a];
      if (v.isNotEmpty && v == displayElement[b] && v == displayElement[c]) {
        winnerElement
          ..clear()
          ..addAll(line);
        setState(() => ignoreBoard = true);
        if (v == 'O') {
          oScore++;
        } else {
          xScore++;
        }
        if (Utility.volume) {
          final uri = Uri.parse("asset:///assets/music/winner.mp3");
          await player.setUrl(uri.toString());
          player.play();
        }
        Future.delayed(Duration(seconds: 1), () async {
          setState(() => ignoreBoard = false);
          await _showWinDialog(v);
          _clearBoard();
        });
        return;
      }
    }

    // Draw
    if (filledBoxes == 9) {
      winnerElement.clear();
      setState(() => ignoreBoard = true);
      Future.delayed(Duration(seconds: 1), () {
        setState(() => ignoreBoard = false);
        _clearBoard();
      });
    }
  }

  Future<void> _showWinCloseBanner() async {
    // If no internet, skip quickly.
    if (_connectionStatus == ConnectivityResult.none) return;

    // Build an anchored adaptive banner (better fill than fixed 320x50)
    final width = MediaQuery.of(context).size.width.truncate();
    final adaptive =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    final adSize = adaptive ?? AdSize.banner;

    BannerAd? sheetBanner;
    bool loaded = false;

    sheetBanner = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId, // use Google's test unit id in debug
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          loaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          sheetBanner = null;
        },
      ),
    )..load();

    // Show a modal bottom sheet OVER the win dialog (blocks taps behind it)
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true, // <-- important: show above the dialog
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54, // dim background
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        // StatefulBuilder so we can redraw when the ad finishes loading
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            if (!loaded && sheetBanner != null) {
              // Poll a bit until the ad loads; cheap & effective
              Future.delayed(const Duration(milliseconds: 100), () {
                if (ctx.mounted) setStateSheet(() {});
              });
            }
            final h = (sheetBanner?.size.height.toDouble() ?? 50);
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.only(bottom: bottomInset + 8),
                // Keep it transparent so your background is visible
                color: Colors.transparent,
                height: h + bottomInset + 8,
                child: Center(
                  child: (loaded && sheetBanner != null)
                      ? SizedBox(
                          width: sheetBanner!.size.width.toDouble(),
                          height: sheetBanner!.size.height.toDouble(),
                          child: AdWidget(ad: sheetBanner!),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );

    // Clean up after the sheet is dismissed
    sheetBanner?.dispose();
  }

  Future<void> _showWinDialog(String winner) async {
    setState(() => ignoreBoard = true);
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                height: Get.height * 0.3,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    image: AssetImage('assets/images/winnerDialog.png'),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${winner.toUpperCase() == "X" ? (widget.player1 ?? "PLAYER 1") : (widget.player2 ?? "PLAYER 2")} WON MATCH!!'
                        .toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: SizedBox(
                  width: Get.width,
                  child: Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () async {
                        await _showWinCloseBanner();
                        _clearBoard();
                        setState(() => ignoreBoard = false);
                        Navigator.of(context).pop();
                      },
                      child: Image.asset(
                        'assets/images/cancelButton.png',
                        height: Get.height * 0.12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearBoard() async {
    setState(() => ignoreBoard = false);
    winnerElement.clear();
    if (Utility.volume) {
      final uri = Uri.parse("asset:///assets/music/undo.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }
    for (int i = 0; i < 9; i++) {
      displayElement[i] = '';
    }
    oTurn = true;
    filledBoxes = 0;
    setState(() {});
  }

  void _clearScoreBoard() async {
    winnerElement.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color(0xff5837B1),
        duration: Duration(seconds: 3),
        content: Text(
          "Restart your Game now!!",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
    if (Utility.volume) {
      final uri = Uri.parse("asset:///assets/music/refresh.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }
    xScore = 0;
    oScore = 0;
    for (int i = 0; i < 9; i++) {
      displayElement[i] = '';
    }
    filledBoxes = 0;
    setState(() {});
  }

  // Simple non-recursive random move for bot
  void _botMove() {
    if (!mounted) return;
    if (!widget.playWithComputer) return;
    if (!oTurn) {
      // it's X's turn (bot)
      final empty = <int>[];
      for (int i = 0; i < 9; i++) {
        if (displayElement[i].isEmpty) empty.add(i);
      }
      if (empty.isNotEmpty) {
        final idx = empty[Random().nextInt(empty.length)];
        _tapped(idx);
      }
    }
    ignoreBoard = false;
    setState(() {});
  }

  // --------------- Connectivity ---------------
  void _listenConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .map(
          (results) =>
              results.isNotEmpty ? results.first : ConnectivityResult.none,
        )
        .listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      if (!mounted) return;
      await _updateConnectionStatus(result);
    } on PlatformException {
      // ignore
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() => _connectionStatus = result);
  }

  // --------------- Ads ---------------
  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isBannerReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isBannerReady = false;
          });
        },
      ),
    )..load();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd?.setImmersiveMode(true);
          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  _loadInterstitial(); // preload next
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _interstitialAd = null;
                  _loadInterstitial();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          // You could retry after some delay if needed.
        },
      ),
    );
  }

  Future<bool> _handleBackWithAd() async {
    await _maybeShowInterstitialThen(() async {
      await _playClickIfEnabled();
      if (Get.isOverlaysOpen) Get.back(); // just in case a dialog/sheet is open
      if (Get.key.currentState?.canPop() ?? false) Get.back();
    });
    return false; // we handle popping ourselves
  }

  void _onBackPress() async {
    await _maybeShowInterstitialThen(() async {
      await _playClickIfEnabled();
      if (Get.isOverlaysOpen) Get.back();
      if (Get.key.currentState?.canPop() ?? false) Get.back();
    });
  }

  Future<void> _maybeShowInterstitialThen(Future<void> Function() next) async {
    final hasNet = _connectionStatus != ConnectivityResult.none;
    final ad = _interstitialAd;

    if (hasNet && ad != null) {
      var continued = false;
      Future<void> safeNext() async {
        if (continued) return;
        continued = true;
        await next();
      }

      // Wire callbacks BEFORE show()
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) async {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitial(); // preload next one
          await safeNext(); // continue (go back) AFTER dismiss
        },
        onAdFailedToShowFullScreenContent: (ad, error) async {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitial();
          await safeNext(); // continue even if showing failed
        },
      );

      ad.setImmersiveMode(true);
      ad.show(); // DO NOT await
      // Optional: fail-safe in case callback never fires (rare)
      Future.delayed(const Duration(seconds: 10), safeNext);
    } else {
      await next(); // no ad → just continue
    }
  }

  Future<void> _playClickIfEnabled() async {
    if (Utility.volume) {
      final uri = Uri.parse("asset:///assets/music/Click.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }
  }
}

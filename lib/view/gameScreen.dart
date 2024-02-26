// ignore_for_file: prefer_const_constructors

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/utility.dart';

class GameScreen extends StatefulWidget {
  final String? player1;
  final String? player2;
  final bool playWithComputer;
  const GameScreen(
      {super.key, this.player1, this.player2, this.playWithComputer = false});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final player = AudioPlayer(); // Create a player
  @override
  void dispose() {
    // TODO: implement dispose
    player.dispose();
    super.dispose();
  }

// declarations
  bool oTurn = true;
  bool ignoreBoard = false;
// 1st player is O
  List<String> displayElement = ['', '', '', '', '', '', '', '', ''];
  List<int> winnerElement = [];
  int oScore = 0;
  int xScore = 0;
  int filledBoxes = 0;

  randomNumberGenerate() {
    Random random = Random();
    int randomNumber = 0;
    randomNumber = random.nextInt(9);
    print('randomNumber=====$randomNumber');
    if (displayElement[randomNumber] == '' && oTurn == false) {
      _tapped(randomNumber);
    } else {
      randomNumberGenerate();
    }
    ignoreBoard = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ///bg image
          Container(
            height: Get.height,
            width: Get.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/enterPlayerBg.png'),
                  fit: BoxFit.cover),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 40,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () async {
                    Get.back();
                    if (Utility.volume == true) {
                      Uri uri = Uri.parse("asset:///assets/music/Click.mp3");
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
              ),
              playerDetails(),
              gamingBoard(),
              bottomBar(),
            ],
          ),
        ],
      ),
    );
  }

  Padding bottomBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () {
              bool allEmpty =
                  displayElement.every((element) => element.isEmpty);
              print("winnerElement == $winnerElement");
              if (!allEmpty) {
                _clearBoard();
              }
            },
            child: Image.asset(
              'assets/images/undoButton.png',
              height: Get.height * 0.08,
            ),
          ),
          InkWell(
            onTap: () {
              bool allEmpty =
                  displayElement.every((element) => element.isEmpty);
              if (!allEmpty) {
                _clearScoreBoard();
              }
            },
            child: Image.asset(
              'assets/images/restartButton.png',
              height: Get.height * 0.08,
            ),
          ),
          InkWell(
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
              height: Get.height * 0.08,
              // width: Get.width,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget gamingBoard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: 9,
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1.15),
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  if (ignoreBoard == false) {
                    if (displayElement[index].isEmpty) {
                      _tapped(index);
                    }
                  }
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
                        )
                      ],
                      border: Border.all(
                          color: winnerElement.contains(index)
                              ? Color(0xffF7E96D)
                              : Colors.white,
                          width: 2)),
                  child: Center(
                    child: Text(
                      displayElement[index],
                      style: TextStyle(
                          color: winnerElement.contains(index)
                              ? Color(0xffF7E96D)
                              : displayElement[index] == 'X'
                                  ? Color(0xff37E9BB)
                                  : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: winnerElement.contains(index) ? 80 : 60),
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }

  Row playerDetails() {
    return Row(
      children: [
        ///player 1
        Expanded(
          flex: 1,
          child: SizedBox(
            height: Get.width * 0.21,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: Get.width * 0.18,
                    width: Get.width,
                    decoration: BoxDecoration(
                        color: Color(0xff5837B1),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomRight: Radius.circular(30))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: Get.width,
                    height: Get.width * 0.15,
                    decoration: BoxDecoration(
                        color: Color(0xff2C136F),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomRight: Radius.circular(30))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(widget.player1!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    width: 3,
                                    color: oTurn == true
                                        ? Colors.transparent
                                        : Colors.red)),
                            child: Image.asset(
                              'assets/images/player1.png',
                              height: oTurn == true
                                  ? Get.height * 0.04
                                  : Get.height * 0.05,
                            ),
                          )
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
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset(
                          'assets/images/star.png',
                          height: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(xScore.toString(),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: Get.width / 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('X',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
          ),
          child: Center(
            child:
                Image.asset('assets/images/vs.png', height: Get.height * 0.06),
          ),
        ),

        ///player 2
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  height: Get.width * 0.18,
                  width: Get.width,
                  decoration: BoxDecoration(
                      color: Color(0xff5837B1),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomLeft: Radius.circular(30))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: Get.width,
                  height: Get.width * 0.15,
                  decoration: BoxDecoration(
                      color: Color(0xff2C136F),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomLeft: Radius.circular(30))),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  width: 3,
                                  color: oTurn == false
                                      ? Colors.transparent
                                      : Colors.red)),
                          child: Image.asset(
                            'assets/images/player2.png',
                            height: oTurn == false
                                ? Get.height * 0.04
                                : Get.height * 0.045,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(widget.player2!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
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
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset(
                        'assets/images/star.png',
                        height: 15,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(oScore.toString(),
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                    ]),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: Get.width / 4,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('O',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// filling the boxes when tapped with X
// or O respectively and then checking the winner function
  _tapped(int index) async {
    print("_tapped No==$index");
    setState(() {
      if (oTurn && displayElement[index] == '') {
        displayElement[index] = 'O';
        filledBoxes++;

        if (widget.playWithComputer == true) {
          setState(() {
            ignoreBoard = true;
          });
          Future.delayed(Duration(seconds: 2), () {
            //if (ignoreBoard == false) {
            randomNumberGenerate();
            //}
          });
        }
      } else if (!oTurn && displayElement[index] == '') {
        displayElement[index] = 'X';
        filledBoxes++;
      }
      oTurn = !oTurn;
      _checkWinner();
    });
  }

  Future<void> _checkWinner() async {
    if (Utility.volume == true) {
      Uri uri = Uri.parse("asset:///assets/music/Click.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }
    // Checking rows
    if (displayElement[0] == displayElement[1] &&
        displayElement[0] == displayElement[2] &&
        displayElement[0] != '') {
      winnerElement.clear();
      winnerElement.add(0);
      winnerElement.add(1);
      winnerElement.add(2);
      setState(() {
        ignoreBoard = true;
      });
      if (displayElement[0] == 'O') {
        oScore++;
      } else if (displayElement[0] == 'X') {
        xScore++;
      }
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(
        Duration(seconds: 1),
        () async {
          setState(() {
            ignoreBoard = false;
          });
          await _showWinDialog(displayElement[0]);
          _clearBoard();
        },
      );
    } else if (displayElement[3] == displayElement[4] &&
        displayElement[3] == displayElement[5] &&
        displayElement[3] != '') {
      winnerElement.add(3);
      winnerElement.add(4);
      winnerElement.add(5);

      if (displayElement[3] == 'O') {
        oScore++;
      } else if (displayElement[3] == 'X') {
        xScore++;
      }
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(
        Duration(seconds: 1),
        () async {
          setState(() {
            ignoreBoard = false;
          });
          await _showWinDialog(displayElement[3]);
          _clearBoard();
        },
      );
    } else if (displayElement[6] == displayElement[7] &&
        displayElement[6] == displayElement[8] &&
        displayElement[6] != '') {
      winnerElement.add(6);
      winnerElement.add(7);
      winnerElement.add(8);
      setState(() {
        ignoreBoard = true;
      });
      if (displayElement[6] == 'O') {
        oScore++;
      } else if (displayElement[6] == 'X') {
        xScore++;
      }
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(
        Duration(seconds: 1),
        () async {
          setState(() {
            ignoreBoard = false;
          });

          await _showWinDialog(displayElement[6]);
          _clearBoard();
        },
      );
    }

    // Checking Column
    else if (displayElement[0] == displayElement[3] &&
        displayElement[0] == displayElement[6] &&
        displayElement[0] != '') {
      winnerElement.add(0);
      winnerElement.add(3);
      winnerElement.add(6);

      setState(() {
        ignoreBoard = true;
      });
      if (displayElement[0] == 'O') {
        oScore++;
      } else if (displayElement[0] == 'X') {
        xScore++;
      }
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(
        Duration(seconds: 1),
        () async {
          setState(() {
            ignoreBoard = false;
          });

          await _showWinDialog(displayElement[0]);
          _clearBoard();
        },
      );
    } else if (displayElement[1] == displayElement[4] &&
        displayElement[1] == displayElement[7] &&
        displayElement[1] != '') {
      winnerElement.add(1);
      winnerElement.add(4);
      winnerElement.add(7);
      if (displayElement[1] == 'O') {
        oScore++;
      } else if (displayElement[1] == 'X') {
        xScore++;
      }
      setState(() {
        ignoreBoard = true;
      });
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(
        Duration(seconds: 1),
        () async {
          setState(() {
            ignoreBoard = false;
          });

          await _showWinDialog(displayElement[1]);
          _clearBoard();
        },
      );
    } else if (displayElement[2] == displayElement[5] &&
        displayElement[2] == displayElement[8] &&
        displayElement[2] != '') {
      winnerElement.add(2);
      winnerElement.add(5);
      winnerElement.add(8);
      setState(() {
        ignoreBoard = true;
      });
      if (displayElement[2] == 'O') {
        oScore++;
      } else if (displayElement[2] == 'X') {
        xScore++;
      }
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(
        Duration(seconds: 1),
        () async {
          setState(() {
            ignoreBoard = false;
          });

          await _showWinDialog(displayElement[2]);
          _clearBoard();
        },
      );
    }

    // Checking Diagonal
    else if (displayElement[0] == displayElement[4] &&
        displayElement[0] == displayElement[8] &&
        displayElement[0] != '') {
      winnerElement.add(0);
      winnerElement.add(4);
      winnerElement.add(8);
      setState(() {
        ignoreBoard = true;
      });
      if (displayElement[0] == 'O') {
        oScore++;
      } else if (displayElement[0] == 'X') {
        xScore++;
      }
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(
        Duration(seconds: 1),
        () async {
          setState(() {
            ignoreBoard = false;
          });
          _clearBoard();
          await _showWinDialog(displayElement[0]);
        },
      );
    } else if (displayElement[2] == displayElement[4] &&
        displayElement[2] == displayElement[6] &&
        displayElement[2] != '') {
      winnerElement.add(2);
      winnerElement.add(4);
      winnerElement.add(6);
      setState(() {
        ignoreBoard = true;
      });
      if (displayElement[2] == 'O') {
        oScore++;
      } else if (displayElement[2] == 'X') {
        xScore++;
      }
      if (Utility.volume == true) {
        Uri uri = Uri.parse("asset:///assets/music/winner.mp3");
        await player.setUrl(uri.toString());
        player.play();
      }
      Future.delayed(Duration(seconds: 1), () async {
        setState(() {
          ignoreBoard = false;
        });

        await _showWinDialog(displayElement[2]);
        _clearBoard();
      });
    } else if (filledBoxes == 9) {
      winnerElement.clear();
      setState(() {
        ignoreBoard = true;
      });
      //   drawDialog();
      //
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          ignoreBoard = false;
        });
        _clearBoard();
      });
      //
      // if (Utility.volume == true) {
      //   Uri uri = Uri.parse("asset:///assets/music/loose.mp3");
      //   await player.setUrl(uri.toString());
      //   player.play();
      // }
    }
  }

  _showWinDialog(String winner) {
    setState(() {
      ignoreBoard = true;
    });
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // return AlertDialog(
          //   title: Text("\" " + winner + " \" is Winner!!!"),
          //   actions: [
          //     ElevatedButton(
          //       child: Text("Play Again"),
          //       onPressed: () {
          //         _clearBoard();
          //         Navigator.of(context).pop();
          //       },
          //     )
          //   ],
          // );
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  height: Get.height * 0.3,
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      image: DecorationImage(
                          image: AssetImage('assets/images/winnerDialog.png'))),
                  child: Center(
                    child: Text(
                        '${winner.toUpperCase() == 'X' ? widget.player1 : widget.player2} you Won!!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
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
                          _clearBoard();
                          setState(() {
                            ignoreBoard = false;
                          });
                          Navigator.of(context).pop();

                          // final snackBar = SnackBar(
                          //   backgroundColor: Color(0xff5837B1),
                          //   duration: Duration(seconds: 3),
                          //   content: Text(
                          //     "${winner.toUpperCase() == 'X' ? widget.player2 : widget.player1} it's your turn now!!",
                          //     style: TextStyle(
                          //         color: Colors.white,
                          //         fontWeight: FontWeight.bold,
                          //         fontSize: 18),
                          //   ),
                          // );
                          // ScaffoldMessenger.of(context).showSnackBar(snackBar);

                          // Find the ScaffoldMessenger in the widget tree
                          // and use it to show a SnackBar.

                          // if (oTurn == false) {
                          //   if (widget.isComputer == true) {
                          //     Future.delayed(Duration(seconds: 2), () {
                          //       if (ignoreBoard == false) {
                          //         randomNumberGenerate();
                          //       }
                          //     });
                          //   }
                          // }
                        },
                        child: Image.asset(
                          'assets/images/cancelButton.png',
                          height: Get.height * 0.12,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }

  void drawDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: Get.height,
                  width: Get.width,
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      image: DecorationImage(
                          image: AssetImage('assets/images/winnerDialog.png'))),
                  child: Center(
                    child: Text('Match Draw',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _clearBoard();
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    'assets/images/cancelButton.png',
                    height: 120,
                  ),
                )
              ],
            ),
          );
        });
  }

  _clearBoard() async {
    setState(() {
      ignoreBoard = false;
    });
    winnerElement.clear();
    if (Utility.volume == true) {
      Uri uri = Uri.parse("asset:///assets/music/undo.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }

    setState(() {
      for (int i = 0; i < 9; i++) {
        displayElement[i] = '';
      }
      oTurn = true;
    });

    filledBoxes = 0;
  }

  void _clearScoreBoard() async {
    winnerElement.clear();

    final snackBar = SnackBar(
      backgroundColor: Color(0xff5837B1),
      duration: Duration(seconds: 3),
      content: Text(
        "Restart your Game now!!",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );

    // Find the ScaffoldMessenger in the widget tree
    // and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    if (Utility.volume == true) {
      Uri uri = Uri.parse("asset:///assets/music/refresh.mp3");
      await player.setUrl(uri.toString());
      player.play();
    }

    setState(() {
      xScore = 0;
      oScore = 0;
      for (int i = 0; i < 9; i++) {
        displayElement[i] = '';
      }
    });
    filledBoxes = 0;
  }
}

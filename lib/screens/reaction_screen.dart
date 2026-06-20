import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xoxo/model/user_model.dart';
import 'package:xoxo/screens/lobby_screen.dart';
import 'package:xoxo/services/firestore_services.dart';

class ReactionGameScreen extends StatefulWidget {
  final String roomId;
  final UserModel user;
  final String walletAddress;
  final double betAmount;

  const ReactionGameScreen({
    super.key,
    required this.roomId,
    required this.walletAddress,
    required this.user, required this.betAmount,
  });

  @override
  State<ReactionGameScreen> createState() => _ReactionGameScreenState();
}

class _ReactionGameScreenState extends State<ReactionGameScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final firestoreService = FirestoreService();
  final FirebaseAuth auth = FirebaseAuth.instance;

  StreamSubscription? winnerSubscription;

  bool canTap = false;

  bool gameFinished = false;

  bool navigating = false;

  late DateTime greenTime;

  String status = "WAIT...";

  String winnerText = "";
 
  Color backgroundColor = Colors.red;

  @override
  void initState() {
    super.initState();

    startGame();

    listenForWinner();
  }

  @override
  void dispose() {
    winnerSubscription?.cancel();

    super.dispose();
  }

  // =========================
  // START GAME
  // =========================

  Future<void> startGame() async {
    final delay = Random().nextInt(5) + 2;

    await Future.delayed(Duration(seconds: delay));

    if (!mounted) return;

    greenTime = DateTime.now();

    setState(() {
      canTap = true;

      backgroundColor = Colors.green;

      status = "TAP NOW";
    });
  }

 void listenForWinner() {
  winnerSubscription = firestore
      .collection("reaction_rooms")
      .doc(widget.roomId)
      .snapshots()
      .listen((doc) async {
        if (!doc.exists) return;
        final data = doc.data();
        if (data == null) return;
        if (data["winner"] == null) return;

        final winnerWallet = data["winner"];
        final isWinner = winnerWallet == widget.walletAddress;

        if (!mounted) return;

        setState(() {
          winnerText = isWinner ? "YOU WIN 🏆" : "YOU LOSE ❌";
        });

        // =========================
        // WAIT FOR ESCROW TO RESOLVE
        // poll until payoutDigest exists
        // before navigating away
        // =========================
        int waitCount = 0;
        while (waitCount < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          waitCount++;

          final updatedDoc = await firestore
              .collection("reaction_rooms")
              .doc(widget.roomId)
              .get();

          final resolved = updatedDoc.data()?['escrowResolved'] == true;
          final failed = updatedDoc.data()?['payoutSent'] == false;

          if (resolved || failed) break;
        }

        if (!mounted || navigating) return;
        navigating = true;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LobbyScreen(
              walletAddress: widget.walletAddress,
              user: widget.user,
            ),
          ),
          (route) => false,
        );
      });
}
  // =========================
  // HANDLE TAP
  // =========================

void handleTap() async {
  if (gameFinished) return;

  // =========================
  // TAPPED TOO EARLY
  // =========================
  if (!canTap) {
    setState(() {
      gameFinished = true;
      backgroundColor = Colors.orange;
      status = "TOO EARLY ❌";
    });

    await firestoreService.saveReaction(
      1000000000000000000, // worst possible reaction time
      widget.roomId,
      widget.walletAddress,
    );

    await firestoreService.checkWinner(
      widget.roomId,
      widget.betAmount,
      widget.walletAddress,
    );
    return;
  }

  // =========================
  // NORMAL TAP
  // =========================
  final reaction = DateTime.now()
      .difference(greenTime)
      .inMilliseconds;

  setState(() {
    gameFinished = true;
    backgroundColor = Colors.blue;
    status = "$reaction ms";
  });

  await firestoreService.saveReaction(
    reaction,
    widget.roomId,
    widget.walletAddress,
  );

  await firestoreService.checkWinner(
    widget.roomId,
    widget.betAmount,
    widget.walletAddress,
  );
}@override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "REACTION DUEL",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                AnimatedOpacity(
                  opacity: winnerText.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    winnerText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

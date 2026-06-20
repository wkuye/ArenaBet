import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xoxo/model/user_model.dart';
import 'package:xoxo/screens/reaction_screen.dart';
import 'package:xoxo/services/firestore_services.dart';

class CountdownScreen extends StatefulWidget {
  final String matchId;
  final String walletAddress;
  final double betAmount;
  final UserModel user;

  const CountdownScreen({
    super.key,
    required this.matchId,
    required this.walletAddress,
    required this.betAmount,
    required this.user,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int countdown = 3;
  final FirestoreService firestoreService = FirestoreService();
  late AnimationController controller;

  late Animation<double> scaleAnimation;

  void updateSuiBalance() async{
    final amount = widget.user.suiBalance - widget.betAmount;
   await firestoreService.updateBalance(uid: widget.user.uid, balance: amount);
  }

  @override
  void initState() {
    super.initState();
    updateSuiBalance();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    startCountdown();
  }

  Future<void> startCountdown() async {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          controller.forward();
        }
      });

      if (countdown == 1) {
        timer.cancel();

        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ReactionGameScreen(
                roomId: widget.matchId,
                walletAddress: widget.walletAddress,
                user: widget.user,
                betAmount: widget.betAmount,
              ),
            ),
          );
        });
      }

      setState(() {
        countdown--;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05010D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'ARENA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'BET',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'MATCH FOUND',
                style: TextStyle(
                  color: Colors.greenAccent,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 50),

              /// MATCH CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.flash_on,
                      color: Colors.greenAccent,
                      size: 60,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      '${widget.betAmount} SUI MATCH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      widget.walletAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// COUNTDOWN ANIMATION
              AnimatedBuilder(
                animation: scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: scaleAnimation.value,
                    child: Container(
                      height: 220,
                      width: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.greenAccent, Colors.teal],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.5),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          countdown > 0 ? '$countdown' : 'GO',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              const Text(
                'GET READY TO TAP',
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

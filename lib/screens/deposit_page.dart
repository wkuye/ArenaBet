import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xoxo/screens/reaction_screen.dart';

import 'package:xoxo/model/user_model.dart';
import 'package:xoxo/services/escrow_services.dart';

class DepositPage extends StatefulWidget {
  final String roomId;
  final UserModel user;
  final String walletAddress;
  final double betAmount;
  final String opponentWallet; // needed to lock both players

  const DepositPage({
    super.key,
    required this.roomId,
    required this.user,
    required this.walletAddress,
    required this.betAmount,
    required this.opponentWallet,
  });

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final escrowService = EscrowService();
  final firestore = FirebaseFirestore.instance;

  bool _loading = false;
  bool _deposited = false;
  String _status = 'Ready to deposit';

  Future<void> _deposit() async {
    setState(() {
      _loading = true;
      _status = 'Locking funds...';
    });

    try {
      // get both player uids
      final myQuery = await firestore
          .collection('users')
          .where('walletAddress', isEqualTo: widget.walletAddress)
          .limit(1)
          .get();

      final opponentQuery = await firestore
          .collection('users')
          .where('walletAddress', isEqualTo: widget.opponentWallet)
          .limit(1)
          .get();

      if (myQuery.docs.isEmpty || opponentQuery.docs.isEmpty) {
        setState(() {
          _loading = false;
          _status = 'Could not find player accounts. Try again.';
        });
        return;
      }

      final myUid = myQuery.docs.first.id;
      final opponentUid = opponentQuery.docs.first.id;

      // lock funds in Firestore
      final locked = await escrowService.lockFunds(
        player1Uid: myUid,
        player2Uid: opponentUid,
        roomId: widget.roomId,
        betAmount: widget.betAmount,
      );

      if (!locked) {
        setState(() {
          _loading = false;
          _status = 'Insufficient balance. Top up your wallet.';
        });
        return;
      }

      setState(() {
        _deposited = true;
        _loading = false;
        _status = 'Funds locked ✅ Starting game...';
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReactionGameScreen(
            roomId: widget.roomId,
            user: widget.user,
            walletAddress: widget.walletAddress,
            betAmount: widget.betAmount,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.deepPurpleAccent,
                  size: 50,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Match Found!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Lock your bet to start the game.\nWinner gets paid automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // bet amount card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurpleAccent),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Bet Amount',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.betAmount} SUI',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Winner receives ${widget.betAmount * 2} SUI',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // balance info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your balance',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    Text(
                      '${widget.user.suiBalance.toStringAsFixed(2)} SUI',
                      style: TextStyle(
                        color: widget.user.suiBalance >= widget.betAmount
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _status,
                  key: ValueKey(_status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _deposited ? Colors.greenAccent : Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ||
                          _deposited ||
                          widget.user.suiBalance < widget.betAmount
                      ? null
                      : _deposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    disabledBackgroundColor: Colors.deepPurple.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _deposited
                              ? 'Locked ✅'
                              : widget.user.suiBalance < widget.betAmount
                                  ? 'Insufficient Balance'
                                  : 'Lock ${widget.betAmount} SUI',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Wallet: ${widget.walletAddress.substring(0, 6)}...${widget.walletAddress.substring(widget.walletAddress.length - 4)}',
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
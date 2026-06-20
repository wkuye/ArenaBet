import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xoxo/model/user_model.dart';
import 'package:xoxo/screens/deposit_page.dart';
import 'package:xoxo/services/escrow_services.dart';
import 'package:xoxo/services/phantom_services.dart';

import '../services/matchmaking_service.dart';
import 'countdown_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String walletAddress;
  final UserModel user;

  const LobbyScreen({
    super.key,
    required this.walletAddress,
    required this.user,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with WidgetsBindingObserver {
  final MatchmakingService matchmakingService = MatchmakingService();
  final escrowService = EscrowService();
  final phantomservice = PhantomSuiService();
  final StreamController<int> timerController = StreamController.broadcast();
  double selectedBet = 0.1;

  bool isSearching = false;

  String? currentMatchId;

  Timer? searchTimer;

  int searchSeconds = 0;

  void startSearchTimer() {
    searchTimer?.cancel();

    searchSeconds = 0;

    timerController.add(searchSeconds);

    searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      searchSeconds++;

      timerController.add(searchSeconds);
    });
  }

  /// STOP TIMER
  void stopSearchTimer() {
    searchTimer?.cancel();

    searchTimer = null;

    searchSeconds = 0;

    timerController.add(searchSeconds);
  }

  void showMatchmakingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF0B0618),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.greenAccent),

                const SizedBox(height: 20),

                const Text(
                  'SEARCHING FOR OPPONENT...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                StreamBuilder<int>(
                  stream: timerController.stream,
                  initialData: 0,
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data} s',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () async {
                    stopSearchTimer();

                    Navigator.pop(dialogContext);

                    await cancelMatchmaking();
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.redAccent,
                    ),
                    child: const Center(
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> findMatch() async {
    startSearchTimer();

    try {
      setState(() {
        isSearching = true;
      });

      final result = await matchmakingService.findMatch(
        wallet: widget.walletAddress,
        bet: selectedBet,
      );

      final String matchId = result['id'];

      currentMatchId = matchId;

      matchmakingService.sub = matchmakingService.listenForMatch(
        matchId: matchId,
        onGameStart: (data, id) async {
          if (!mounted) return;

          stopSearchTimer();

          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
  final player1 = data['player1'] as String;
    final player2 = data['player2'] as String;
    final opponentWallet = player1 == widget.walletAddress 
        ? player2 
        : player1;
       
         Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DepositPage(roomId: matchId, user: widget.user, walletAddress:widget.walletAddress, betAmount:selectedBet, opponentWallet: opponentWallet,
               
                ),
              ),
            );
          }
      
      );
    } catch (e, stackTrace) {
      debugPrint(e.toString());

      debugPrint(stackTrace.toString());
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  Future<void> cancelMatchmaking() async {
    if (currentMatchId == null) return;

    await matchmakingService.cancelMatchmaking(currentMatchId!);
    print('cancelled');
    stopSearchTimer();

    setState(() {
      isSearching = false;
      currentMatchId = null;
    });
  }

  Future<void> refreshBalance() async {
    await phantomservice.refreshUserBalance(
      widget.user.uid,
      widget.user.walletAddress,
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    refreshBalance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    searchTimer?.cancel();

    timerController.close();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    /// USER LEFT APP
    print(state);
    if (state == AppLifecycleState.detached) {
      await cancelMatchmaking();

      debugPrint('Matchmaking cancelled: app closed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF05010D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: size.height,
            width: size.width,
            child: Column(
              children: [
                const Spacer(flex: 2),

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

                const SizedBox(height: 10),

                const Text(
                  'REALTIME SKILL DUELS',
                  style: TextStyle(color: Colors.white70, letterSpacing: 3),
                ),

                const Spacer(flex: 3),

                /// WALLET CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONNECTED WALLET',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        widget.walletAddress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                /// SELECT BET
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SELECT BET',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                /// BET OPTIONS
                Row(
                  children: [
                    Expanded(child: betCard(0.1)),
                    const SizedBox(width: 16),
                    Expanded(child: betCard(0.5)),
                    const SizedBox(width: 16),
                    Expanded(child: betCard(1.0)),
                  ],
                ),

                const Spacer(flex: 4),

                /// FIND MATCH BUTTON
                GestureDetector(
                  onTap: () async {
                    if (widget.user.suiBalance < selectedBet) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("amount low")),
                      );
                    } else {
                      showMatchmakingDialog();

                      findMatch();
                    }
                  },

                  child: Container(
                    height: 72,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Colors.teal],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isSearching
                          ? const Text(
                              'SEARCHING...',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Text(
                              'FIND MATCH',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                /// FOOTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    footerItem(Icons.flash_on, 'Fast'),
                    footerItem(Icons.emoji_events, 'Competitive'),
                    footerItem(Icons.paid, 'Win SUI'),
                  ],
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget betCard(double amount) {
    final selected = selectedBet == amount;

    return GestureDetector(
      onTap: () async {
        // var solBalance= await FirestoreService().getUserSolBalance(widget.user.uid);
        // int newAmount=solBalance['solBalance']-amount;
        // phantomservice.refreshUserBalance(uid, walletAddress)
        setState(() {
          selectedBet = amount;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected
              ? Colors.greenAccent.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected ? Colors.greenAccent : Colors.white12,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on,
              color: selected ? Colors.greenAccent : Colors.white70,
              size: widthBased(34),
            ),

            const SizedBox(height: 12),

            Text(
              '$amount SUI',
              style: TextStyle(
                color: selected ? Colors.greenAccent : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget footerItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
          ),
          child: Icon(icon, color: Colors.greenAccent),
        ),

        const SizedBox(height: 10),

        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  double widthBased(double size) {
    final width = MediaQuery.of(context).size.width;

    return width * (size / 430);
  }
}

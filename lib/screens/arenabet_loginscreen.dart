import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:xoxo/screens/lobby_screen.dart';
import 'package:xoxo/screens/username_page.dart';
import 'package:xoxo/services/firestore_services.dart';
import 'package:xoxo/services/phantom_services.dart';
import 'package:xoxo/webview/sui_webview.dart';

import 'package:xoxo/widget/app_widgets.dart';

class ArenaBetLoginScreen extends StatefulWidget {
  const ArenaBetLoginScreen({super.key});

  @override
  State<ArenaBetLoginScreen> createState() => _ArenaBetLoginScreenState();
}

class _ArenaBetLoginScreenState extends State<ArenaBetLoginScreen>
    with WidgetsBindingObserver {
  final phantomService = PhantomSuiService();
  String? walletAddress;
  final firestoreService = FirestoreService();
  final AppLinks appLinks = AppLinks();
  late StreamSubscription _linkSub;
  bool _waitingForWallet = false;
  bool _handledCallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLink();
    _listenForWalletCallback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForWallet) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _handledCallback) return;
        // no address came back — user cancelled or left Phantom
        _waitingForWallet = false;
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
    }
  }

  Future<void> _checkInitialLink() async {
    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) _handleUri(uri);
    } catch (_) {}
  }

  void _listenForWalletCallback() {
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  Future<void> _handleUri(Uri uri) async {
    if (!mounted || _handledCallback) return;
    if (uri.scheme != 'arenabet' || uri.host != 'sui-connect') return;

    final address = uri.queryParameters['address'];
    if (address == null) return;

    _handledCallback = true;
    _waitingForWallet = false;

    showAboutDialog(context: context);
    final result = await phantomService.handleWalletCallback(address);
    if (!mounted) return;

    // pop dialog only after everything is fetched
    if (Navigator.canPop(context)) Navigator.pop(context);

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserNamePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF05010D),
      body: Stack(
        children: [
          /// BACKGROUND GLOWS
          Positioned(
            top: -height * 0.12,
            left: -width * 0.25,
            child: glow(color: Colors.purpleAccent, size: width * 0.7),
          ),

          Positioned(
            bottom: -height * 0.15,
            right: -width * 0.25,
            child: glow(color: Colors.greenAccent, size: width * 0.7),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: Column(
                children: [
                  SizedBox(height: height * 0.04),

                  Container(
                    height: width * 0.24,
                    width: width * 0.24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.07),
                      gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Colors.purpleAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.35),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sports_esports,
                      size: width * 0.11,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  /// TITLE
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "ARENA",
                          style: TextStyle(
                            fontSize: width * 0.1,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: "BET",
                          style: TextStyle(
                            fontSize: width * 0.1,
                            fontWeight: FontWeight.w900,
                            color: Colors.greenAccent,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.01),

                  Text(
                    "PLAY • COMPETE • EARN",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: width * 0.032,
                      letterSpacing: 3,
                    ),
                  ),

                  SizedBox(height: height * 0.05),

                  /// GLASS CARD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(width * 0.07),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: EdgeInsets.all(width * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(width * 0.07),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "WELCOME TO ARENABET",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: width * 0.045,
                              ),
                            ),

                            SizedBox(height: height * 0.02),

                            Text(
                              "Connect your wallet to start competing in skill games and earn rewards.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                                fontSize: width * 0.038,
                              ),
                            ),

                            SizedBox(height: height * 0.04),

                            walletButton(
                              context,
                              title: "CONNECT SOLANA WALLET",
                              icon: Icons.currency_bitcoin,
                              glowColor: Colors.greenAccent,
                              onTap: () async {
                                _waitingForWallet = true;
                                _handledCallback = false;
                                showLoadingDialog(context);
                                await phantomService.openPhantomConnect();
                              },
                            ),
                            SizedBox(height: height * 0.025),

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.03,
                                  ),
                                  child: Text(
                                    "OR",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: width * 0.03,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                ),
                              ],
                            ),

                          

                            SizedBox(height: height * 0.03),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.shield,
                                  color: Colors.purpleAccent,
                                  size: width * 0.045,
                                ),
                                SizedBox(width: width * 0.02),
                                Expanded(
                                  child: Text(
                                    "We never store your private keys. Your funds are always safe.",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: width * 0.03,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.05),

                  /// FOOTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      footerItem(
                        context,
                        icon: Icons.sports_esports,
                        label: "Skill Games",
                      ),
                      footerItem(
                        context,
                        icon: Icons.emoji_events,
                        label: "Compete",
                      ),
                      footerItem(
                        context,
                        icon: Icons.paid,
                        label: "Earn Rewards",
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

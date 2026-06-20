import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// =========================
// PHANTOM SUI SERVICE
// No deeplinks — uses WebView
// to call window.phantom.sui
// =========================
class PhantomSuiService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final AppLinks appLinks = AppLinks();

  static const String _suiRpcUrl = 'https://fullnode.testnet.sui.io';

  // =========================
  // STEP 1 — OPEN PHANTOM
  // Just launches the browse
  // deeplink, returns nothing.
  // Address comes via deeplink
  // callback handled in Step 2
  // =========================

  Future<void> openPhantomConnect() async {
    final pageUrl = Uri.encodeComponent('https://arenabet-c8607.web.app');
    final ref = Uri.encodeComponent('arenabet://sui-connect');
    final browseUrl = 'https://phantom.app/ul/browse/$pageUrl?ref=$ref';

    await launchUrl(Uri.parse(browseUrl), mode: LaunchMode.externalApplication);
  }

  // =========================
  // STEP 2 — HANDLE CALLBACK
  // Called when app_links fires
  // arenabet://sui-connect
  // ?address=0x...
  // =========================

  Future<String?> handleWalletCallback(String walletAddress) async {
    try {
      debugPrint('Sui wallet address: $walletAddress');

      // =========================
      // CHECK EXISTING USER
      // =========================

      // final existingUser = await firestore
      //     .collection('users')
      //     .where('walletAddress', isEqualTo: walletAddress)
      //     .limit(1)
      //     .get();

      // if (existingUser.docs.isNotEmpty) {
      //   final uid = existingUser.docs.first.id;
      //   await auth.signInAnonymously();
      //   return 'exist';
      // }

      // =========================
      // NEW USER
      // =========================

      final credential = await auth.signInAnonymously();
      final uid = credential.user!.uid;

      // await requestFaucet(walletAddress);
      await Future.delayed(const Duration(seconds: 5));

      final balance = await getSuiBalance(walletAddress);
      print('balance: $balance');
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'walletAddress': walletAddress,
        'suiBalance': balance??0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return walletAddress;
    } catch (e) {
      debugPrint('Handle Wallet Callback Error: $e');
      return null;
    }
  }

  // =========================
  // GET SUI BALANCE
  // =========================

  Future<double?> getSuiBalance(String suiAddress) async {
    // 1. Define the Sui mainnet RPC endpoint
    final Uri url = Uri.parse('https://fullnode.testnet.sui.io:443');

    // 2. Construct the JSON-RPC request payload
    final Map<String, dynamic> requestPayload = {
      "jsonrpc": "2.0",
      "id": 1,
      "method": "suix_getAllBalances",
      "params": [suiAddress],
    };

    try {
      // 3. Send the HTTP POST request
      final http.Response response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      // 4. Handle and parse the response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('error')) {
          print('RPC Error: ${responseData['error']['message']}');
          return null;
        }

        final List<dynamic> result = responseData['result'];
        print('res: $result');
        for (var coin in result) {
          String coinType = coin['coinType'];
          String totalBalanceMist = coin['totalBalance'];
          print('totalBalanceMist: $totalBalanceMist');
          // Convert Mist string to BigInt, then to double SUI (1 SUI = 10^9 Mist)
          BigInt mist = BigInt.parse(totalBalanceMist);
          double sui = mist / BigInt.from(1000000000);

          return sui;
        }
      } else {
        print('HTTP Request Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred: $e');
    }
    return null;
  }

  // =========================
  // TESTNET FAUCET
  // =========================

  Future<void> requestFaucet(String walletAddress) async {
    try {
      final response = await http.post(
        Uri.parse('https://faucet.testnet.sui.io/v2/gas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'FixedAmountRequest': {'recipient': walletAddress},
        }),
      );
      print('Faucet: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('Faucet Error: $e');
    }
  }

  // =========================
  // REFRESH USER BALANCE
  // =========================

  Future<void> refreshUserBalance(String uid, String walletAddress) async {
    try {
      final balance = await getSuiBalance(walletAddress);
      await firestore.collection('users').doc(uid).update({
        'suiBalance': balance??0,
      });
    } catch (e) {
      debugPrint('Refresh Balance Error: $e');
    }
  }
}

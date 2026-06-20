import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sui/signers/raw_signer.dart';
import 'package:sui/sui.dart';

class SuiServices {
  static const String _rpcUrl = 'https://fullnode.testnet.sui.io';

  // =========================
  // YOUR ADMIN WALLET
  // holds funds during the game
  // =========================
  static const String _adminWallet =
      '0xa2efc0eec0eed2f2563befa4cdbb55eb85d9e982999b904adc7acf348d069ed2';
  static const String _adminPrivateKey =
      'suiprivkey1qr57nrpj7wj8xde0hudf6jlt39xefjsx0xkm6ukqk4m8l3493mseqfcvu9z';

  // =========================
  // GET SUI BALANCE
  // =========================
  Future<double> getSuiBalance(String walletAddress) async {
    try {
      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'suix_getBalance',
          'params': [walletAddress, '0x2::sui::SUI'],
        }),
      );
      final body = jsonDecode(response.body);
      final mist = double.parse(body['result']['totalBalance'].toString());
      return mist / 1e9;
    } catch (e) {
      debugPrint('getSuiBalance error: $e');
      return 0.0;
    }
  }

  // =========================
  // REFRESH USER BALANCE
  // updates balance in firestore
  // =========================
  Future<void> refreshUserBalance(String uid, String walletAddress) async {
    try {
      final balance = await getSuiBalance(walletAddress);
      debugPrint('refreshed balance: $balance SUI');
    } catch (e) {
      debugPrint('refreshUserBalance error: $e');
    }
  }

  // =========================
  // ADMIN SENDS TO WINNER
  // called after checkWinner
  // no user interaction needed
  // admin signs with private key
  // =========================
Future<String?> sendFromAdmin({
  required String receiverWallet,
  required double amount,
}) async {
  try {
    final mistAmount = (amount * 1e9).toInt();

    // get admin coins
    final coinsResponse = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'suix_getAllCoins',
        'params': [_adminWallet, null, 10],
      }),
    );

    final coinsBody = jsonDecode(coinsResponse.body);
    final allCoins = coinsBody['result']['data'] as List;

    final coins = allCoins
        .where((c) => c['coinType'] == '0x2::sui::SUI')
        .toList();

    if (coins.isEmpty) {
      debugPrint('No coins found for admin wallet');
      return null;
    }

    final mistWithGas = mistAmount + 10000000;
    final coin = coins.firstWhere(
      (c) => int.parse(c['balance'].toString()) >= mistWithGas,
      orElse: () => coins.first,
    );

    final coinObjectId = coin['coinObjectId'] as String;
    debugPrint('Admin using coin: $coinObjectId');

    // build tx bytes
    final txResponse = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'unsafe_transferSui',
        'params': [
          _adminWallet,
          coinObjectId,
          '10000000',
          receiverWallet,
          mistAmount.toString(),
        ],
      }),
    );

    final txBody = jsonDecode(txResponse.body);
    debugPrint('Admin tx: $txBody');

    if (txBody['error'] != null) {
      debugPrint('Build tx error: ${txBody['error']}');
      return null;
    }

    final txBytes = txBody['result']['txBytes'] as String;

    // =========================
    // SIGN USING RawSigner
    // fixes "setSigner" error
    // =========================
   // get the keypair from the account
final account = SuiAccount.fromPrivateKey(_adminPrivateKey);
final keypair = account.keyPair; // ← get keypair

final signer = RawSigner(
  keypair, // ← Keypair not SuiAccount
  endpoint: SuiUrls.testnet, // ← endpoint not client
);
 final txBytesDecoded = Uint8List.fromList(base64Decode(txBytes));
final response = await signer.signAndExecuteTransaction(
  transaction: txBytesDecoded,
);

debugPrint('sendFromAdmin digest: ${response.digest}');
return response.digest;
  } catch (e) {
    debugPrint('sendFromAdmin error: $e');
    return null;
  }
}
}

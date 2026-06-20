// lib/auth/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xoxo/services/sui_services.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final suiService = SuiServices();

  /// SAVE USER
  Future<void> saveUser({
    required String uid,
    required String walletAddress,
    required double solBalance,
  }) async {
    try {
      await firestore.collection('users').doc(uid).set({
        "uid": uid,
        "walletAddress": walletAddress,
        "wins": 0,
        "losses": 0,
        "username": "",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('e: $e');
    }
  }

  Future<void> saveReaction(
    int reaction,
    String roomID,
    String walletAdress,
  ) async {
    await firestore
        .collection("reaction_rooms")
        .doc(roomID)
        .collection("players")
        .doc(walletAdress)
        .set({
          "wallet": walletAdress,
          "reaction": reaction,
          "createdAt": FieldValue.serverTimestamp(),
        });
  }
Future<void> checkWinner(String roomID, double bet, String wallet) async {
  // =========================
  // WAIT FOR BOTH REACTIONS
  // poll until 2 players saved
  // max 10 seconds
  // =========================
  int attempts = 0;
  QuerySnapshot snapshot;

  do {
    snapshot = await firestore
        .collection("reaction_rooms")
        .doc(roomID)
        .collection("players")
        .get();

    if (snapshot.docs.length >= 2) break;

    await Future.delayed(const Duration(milliseconds: 500));
    attempts++;
  } while (attempts < 20); // 10 seconds max

  if (snapshot.docs.length < 2) {
    print('Only ${snapshot.docs.length} player(s) — timeout');
    return;
  }

  final players = snapshot.docs;
  players.sort((a, b) =>
    (a["reaction"] as int).compareTo(b["reaction"] as int));

  final winner = players.first;
  final loser = players.last;

  print('winner: $winner, loser: $loser');

  final roomRef = firestore.collection("reaction_rooms").doc(roomID);

  bool iAmThePayer = false;

  try {
    await firestore.runTransaction((txn) async {
      final roomDoc = await txn.get(roomRef);

      if (roomDoc.data()?['payoutSent'] == true) {
        iAmThePayer = false;
        return;
      }

      iAmThePayer = true;

      txn.set(roomRef, {
        "winner": winner["wallet"],
        "winningReaction": winner["reaction"],
        "gameFinished": true,
        "payoutSent": true,
      }, SetOptions(merge: true));
    });
  } catch (e) {
    print('Transaction error: $e');
    return;
  }

  if (!iAmThePayer) {
    print('Payout already handled by other device');
    return;
  }

  final winnerQuery = await firestore
      .collection('users')
      .where('walletAddress', isEqualTo: winner["wallet"])
      .limit(1)
      .get();

  final loserQuery = await firestore
      .collection('users')
      .where('walletAddress', isEqualTo: loser["wallet"])
      .limit(1)
      .get();

  if (winnerQuery.docs.isEmpty || loserQuery.docs.isEmpty) return;

  final winnerUid = winnerQuery.docs.first.id;
  final loserUid = loserQuery.docs.first.id;

  final digest = await suiService.sendFromAdmin(
    receiverWallet: winner["wallet"],
    amount: bet * 2,
  );

  print('Payout digest: $digest');

  if (digest == null) {
    print('sendFromAdmin failed — reverting');
    await roomRef.update({'payoutSent': false});
    return;
  }

  final batch = firestore.batch();

  batch.update(firestore.collection('users').doc(winnerUid), {
    'suiBalance': FieldValue.increment(bet * 2),
    'lockedBalance': FieldValue.increment(-bet),
    'wins': FieldValue.increment(1),
  });

  batch.update(firestore.collection('users').doc(loserUid), {
    'lockedBalance': FieldValue.increment(-bet),
    'losses': FieldValue.increment(1),
  });

  batch.update(roomRef, {
    'payoutDigest': digest,
    'escrowResolved': true,
  });

  await batch.commit();
  print('Payout complete — winner: ${winner["wallet"]} — digest: $digest');
}

  /// UPDATE BALANCE
  Future<void> updateBalance({
    required String uid,
    required double balance,
  }) async {
    await firestore.collection('users').doc(uid).update({
      "suiBalance": balance,
    });
  }

  Future<void> addUsername({
    required String uid,
    required String username,
  }) async {
    await firestore.collection('users').doc(uid).update({"username": username});
  }

  Future<bool> usernameExists(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<bool> checkWalletAvailability(String walletAddress) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('walletAddress', isEqualTo: walletAddress)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  /// UPDATE WINS
  Future<void> addWin(String uid) async {
    await firestore.collection('users').doc(uid).update({
      "wins": FieldValue.increment(1),
    });
  }

  /// UPDATE LOSSES
  Future<void> addLoss(String uid) async {
    await firestore.collection('users').doc(uid).update({
      "losses": FieldValue.increment(1),
    });
  }

  /// GET USER
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    return await firestore.collection('users').doc(uid).get();
  }

  Future<Map<String, dynamic>> getUserSuiBalance(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.data()!;
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class MatchmakingService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription? sub;

  /// FIND OR CREATE MATCH
  Future<Map> findMatch({required String wallet, required double bet}) async {
    final query = await firestore
        .collection('matches')
        .where('status', isEqualTo: 'waiting')
        .where('bet', isEqualTo: bet)
        .orderBy("createdAt")
        .get();

    final availableMatches = query.docs
        .where((doc) => doc['player1'] != wallet)
        .toList();

    if (availableMatches.isNotEmpty) {
      final matchDoc = availableMatches.first;

      // REFETCH latest version
      final freshDoc = await matchDoc.reference.get();

      // document deleted?
      if (!freshDoc.exists) {
        throw Exception("Match no longer exists");
      }

      final data = freshDoc.data() as Map<String, dynamic>;

      // already matched by another player?
      if (data['player2'] != null) {
        return findMatch(wallet: wallet, bet: bet);
      }

      await matchDoc.reference.update({
        'player2': wallet,
        'status': 'matched',
        'matchedAt': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await matchDoc.reference.get();

      return {"matchData": updatedDoc.data(), "id": updatedDoc.id};
    }

    final newDoc = await firestore.collection('matches').add({
      'player1': wallet,
      'player2': null,
      'bet': bet,
      'status': 'waiting',
      'gameStarted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final data = await newDoc.get();

    return {"matchData": data.data(), "id": newDoc.id};
  }

  StreamSubscription listenForMatch({
    required String matchId,
    required Function(Map<String, dynamic>, String) onGameStart,
  }) {
    return firestore.collection('matches').doc(matchId).snapshots().listen((
      snapshot,
    ) async {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final id = snapshot.id;

      if (data == null) return;

      /// BOTH PLAYERS READY
      if (data['status'] == 'matched') {
        /// HOST STARTS GAME
        if (data['gameStarted'] != true) {
          await snapshot.reference.update({'gameStarted': true});
        }
      }

      /// BOTH NAVIGATE
      if (data['gameStarted'] == true) {
        onGameStart(data,id);
      }
    });
  }

  Future<Map<String, dynamic>> getUpdatedPlayer2({
    required String player1,
    required String player2,
  }) async {
    final query = await firestore
        .collection('matches')
        .where('player1', isEqualTo: player1)
        .where('player2', isEqualTo: player2)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Matched document not found');
    }

    return query.docs.first.data();
  }

  void dispose() {
    sub!.cancel();
  }

  /// CANCEL MATCHMAKING
  Future<void> cancelMatchmaking(String matchId) async {
    final doc = firestore.collection('matches').doc(matchId);

    final snapshot = await doc.get();

    if (!snapshot.exists) return;

    final data = snapshot.data();

    /// ONLY DELETE WAITING MATCHES
    if (data?['status'] == 'waiting') {
      await doc.delete();
    }
  }
}

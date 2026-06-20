import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xoxo/services/sui_services.dart';

class EscrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SuiServices _suiServices = SuiServices();

  // =========================
  // LOCK FUNDS
  // deduct from both players
  // when match is found
  // =========================
  Future<bool> lockFunds({
    required String player1Uid,
    required String player2Uid,
    required String roomId,
    required double betAmount,
  }) async {
    try {
      final p1Doc = await _firestore
          .collection('users')
          .doc(player1Uid)
          .get();
      final p2Doc = await _firestore
          .collection('users')
          .doc(player2Uid)
          .get();

      final p1Balance =
          (p1Doc.data()?['suiBalance'] ?? 0.0).toDouble();
      final p2Balance =
          (p2Doc.data()?['suiBalance'] ?? 0.0).toDouble();

      debugPrint('P1 balance: $p1Balance, P2 balance: $p2Balance, bet: $betAmount');

      if (p1Balance < betAmount) {
        debugPrint('Player 1 insufficient balance');
        return false;
      }

      if (p2Balance < betAmount) {
        debugPrint('Player 2 insufficient balance');
        return false;
      }

      final batch = _firestore.batch();

      batch.update(
        _firestore.collection('users').doc(player1Uid),
        {
          'suiBalance': FieldValue.increment(-betAmount),
          'lockedBalance': FieldValue.increment(betAmount),
        },
      );

      batch.update(
        _firestore.collection('users').doc(player2Uid),
        {
          'suiBalance': FieldValue.increment(-betAmount),
          'lockedBalance': FieldValue.increment(betAmount),
        },
      );

    batch.set(
  _firestore.collection('reaction_rooms').doc(roomId),
  {
    'escrowLocked': true,
    'betAmount': betAmount,
  },
  SetOptions(merge: true),
);

      await batch.commit();
      debugPrint('Funds locked for room $roomId');
      return true;
    } catch (e) {
      debugPrint('lockFunds error: $e');
      return false;
    }
  }

  // =========================
  // RELEASE TO WINNER
  // admin sends real SUI +
  // updates Firestore balance
  // =========================
  Future<bool> releaseFunds({
    required String roomId,
    required String winnerUid,
    required String loserUid,
    required String winnerWallet,
    required double betAmount,
  }) async {
    try {
      // prevent double payout
      final roomDoc = await _firestore
          .collection('reaction_rooms')
          .doc(roomId)
          .get();

      if (roomDoc.data()?['payoutSent'] == true) {
        debugPrint('Payout already sent for room $roomId');
        return false;
      }

      // mark as paid immediately to prevent race condition
      await _firestore
          .collection('reaction_rooms')
          .doc(roomId)
          .update({'payoutSent': true});

      final winnings = betAmount * 2;

      // send real SUI from admin to winner
      final digest = await _suiServices.sendFromAdmin(
        receiverWallet: winnerWallet,
        amount: winnings,
      );

      if (digest == null) {
        debugPrint('sendFromAdmin failed');
        // revert payoutSent flag if tx failed
        await _firestore
            .collection('reaction_rooms')
            .doc(roomId)
            .update({'payoutSent': false});
        return false;
      }

      // update Firestore balances
      final batch = _firestore.batch();

      // winner gets winnings added to balance
      batch.update(
        _firestore.collection('users').doc(winnerUid),
        {
          'suiBalance': FieldValue.increment(winnings),
          'lockedBalance': FieldValue.increment(-betAmount),
          'wins': FieldValue.increment(1),
        },
      );

      // loser loses locked amount
      batch.update(
        _firestore.collection('users').doc(loserUid),
        {
          'lockedBalance': FieldValue.increment(-betAmount),
          'losses': FieldValue.increment(1),
        },
      );

      // save tx digest to room
      batch.update(
        _firestore.collection('reaction_rooms').doc(roomId),
        {
          'payoutDigest': digest,
          'escrowResolved': true,
        },
      );

      await batch.commit();
      debugPrint('Payout complete — digest: $digest');
      return true;
    } catch (e) {
      debugPrint('releaseFunds error: $e');
      return false;
    }
  }

  // =========================
  // REFUND BOTH
  // if game cancelled
  // =========================
  Future<void> refundFunds({
    required String player1Uid,
    required String player2Uid,
    required String roomId,
    required double betAmount,
  }) async {
    try {
      final batch = _firestore.batch();

      batch.update(
        _firestore.collection('users').doc(player1Uid),
        {
          'suiBalance': FieldValue.increment(betAmount),
          'lockedBalance': FieldValue.increment(-betAmount),
        },
      );

      batch.update(
        _firestore.collection('users').doc(player2Uid),
        {
          'suiBalance': FieldValue.increment(betAmount),
          'lockedBalance': FieldValue.increment(-betAmount),
        },
      );

      batch.update(
        _firestore.collection('reaction_rooms').doc(roomId),
        {'refunded': true},
      );

      await batch.commit();
      debugPrint('Refunded both players');
    } catch (e) {
      debugPrint('refundFunds error: $e');
    }
  }
}
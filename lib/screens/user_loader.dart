import 'package:flutter/material.dart';
import 'package:xoxo/model/user_model.dart';
import 'package:xoxo/screens/arenabet_loginscreen.dart';
import 'package:xoxo/screens/lobby_screen.dart';
import 'package:xoxo/services/firestore_services.dart';
class UserLoader extends StatefulWidget {
  final String uid;
  const UserLoader({required this.uid});

  @override
  State<UserLoader> createState() => UserLoaderState();
}

class UserLoaderState extends State<UserLoader> {


  final firestoreService = FirestoreService();
  late final Future _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = firestoreService.getUser(widget.uid); 
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.hasData ||
            userSnapshot.data == null ||
            !userSnapshot.data!.exists) {
          return ArenaBetLoginScreen();
        }

        final currentUser = UserModel.fromJson(userSnapshot.data!.data()!);
        return LobbyScreen(
          walletAddress: currentUser.walletAddress,
          user: currentUser,
        );
      },
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:xoxo/model/user_model.dart';
import 'package:xoxo/screens/lobby_screen.dart';
import 'package:xoxo/services/firestore_services.dart';
import 'package:xoxo/services/phantom_services.dart';

import 'package:xoxo/widget/app_widgets.dart';

class UserNamePage extends StatefulWidget {
  const UserNamePage({super.key});

  @override
  State<UserNamePage> createState() => _UserNamePageState();
}

class _UserNamePageState extends State<UserNamePage> {
  final TextEditingController controller = TextEditingController();

  final firestore = FirestoreService();
  final phantom = PhantomSuiService();
  final user = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>();

  String? usernameError;

  bool isLoading = false;

 Future<void> validateAndContinue() async {
  FocusScope.of(context).unfocus();
  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() {
    isLoading = true;
  });

  final username = controller.text.trim();

  final exists = await firestore.usernameExists(username);

  if (!mounted) return;

  if (exists) {
    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Username already taken"),
      ),
    );

    return;
  }

  await firestore.addUsername(
    uid: user!.uid,
    username: username,
  );

  final userdoc = await getUSers();

  if (userdoc == null) {
    setState(() {
      isLoading = false;
    });

    return;
  }

  final mainUser = UserModel.fromJson(userdoc);

 
  setState(() {
    isLoading = false;
  });

  _formKey.currentState?.reset();
  controller.clear();

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => LobbyScreen(
        walletAddress: mainUser.walletAddress, user: mainUser,
      ),
    ),
  );
}
  Future<Map<String, dynamic>?> getUSers() async {
    final userdoc = await firestore.getUser(user!.uid);
    return userdoc.data();
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
            child: Form(
              key: _formKey,
              child: Container(
                height: size.height,
                width: size.width,
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Enter a username";
                        }

                        if (value.length < 3) {
                          return "Username too short";
                        }

                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "type your username",
                      ),
                      controller: controller,
                    ),
                    SizedBox(height: 25),
                    GestureDetector(
                      onTap: () async {
                        await validateAndContinue();

                      },
                      child: Container(
                        width: size.width / 2,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              Colors.greenAccent.withOpacity(0.55),
                              Colors.greenAccent.withOpacity(0.22),
                            ],
                          ),
                        ),

                        child: Center(
                          child: isLoading
                              ? Transform.scale(
                                  scale: 0.6,
                                  child: const CircularProgressIndicator(),
                                )
                              : Text(
                                  "Submit",
                                  style: TextStyle(color: Colors.greenAccent),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

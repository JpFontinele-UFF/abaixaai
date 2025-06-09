import 'package:abaixaai/app/controller/login_controller.dart';
import 'package:abaixaai/app/routes/app_routes.dart';  // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:sign_in_button/sign_in_button.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  final LoginController _loginController = Get.put(LoginController());
  bool _showLogin = false;

  @override
  void initState() {
    super.initState();

    // Check if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      // User is logged in, navigate to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(Routes.HOME);
      });
    } else {
      // Show login after splash if not logged in
      Future.delayed(const Duration(milliseconds: 3000), () {
        setState(() {
          _showLogin = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.blue,
                  Colors.black,
                ],
              ),
            ),
          ),
          Center(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 500),
              firstChild: Center(
                child: SvgPicture.asset(
                  'assets/icons/logo.svg',
                  width: 200,
                  height: 200,
                  // ignore: deprecated_member_use
                  color: Colors.white,
                ),
              ),
              secondChild: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text(
                    "Abaixa AI",
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/logo.svg',
                    width: 200,
                    height: 200,
                    // ignore: deprecated_member_use
                    color: Colors.white,
                  ),
                  SignInButton(
                    Buttons.google,
                    text: 'Entrar com Google',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    onPressed: _loginController.loginGoogle,
                  ),
                ],
              ),
              crossFadeState: _showLogin
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ),
        ],
      ),
    );
  }
}
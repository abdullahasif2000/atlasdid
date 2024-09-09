import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToHome,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.white,
            ),
            Center(
              child: SizedBox(
                width: 200.0,
                height: 200.0,
                child: Image.asset(
                  'assets/images/Atlas.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              bottom: 100.0,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap to continue',
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

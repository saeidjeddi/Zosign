import 'package:flutter/material.dart';
import 'package:zosign/views/login_screen.dart';


/// صفحه شروع با انیمیشن
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> rotationAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();

    // انیمیشن 5 ثانیه
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    rotationAnimation = Tween<double>(begin: 0, end: 6.28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // انتقال بعد از 7 ثانیه
    Future.delayed(const Duration(seconds: 7), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>  LoginScreenTV(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [




            /// ✅ حرکت تصویر 2 از بالا
            Positioned(
              top: 80,
              right: 155,
              child: SlideTransition(
                position: slideAnimation,
                child: Image.asset(
                  'assets/images/2.png',
                  width: 100,
                  height: 100,
                ),
              ),
            ),





            /// ✅ چرخش تصویر 1
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: rotationAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/1.png',
                width: 300,
                height: 300,
              ),
            ),


          ],
        ),
      ),
    );
  }
}

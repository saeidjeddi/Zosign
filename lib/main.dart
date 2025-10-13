import 'package:flutter/material.dart';
import 'package:zosign/views/main_scrren.dart';

void main() {
  runApp(const MainAppTv());
}

class MainAppTv extends StatelessWidget {
  const MainAppTv({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}